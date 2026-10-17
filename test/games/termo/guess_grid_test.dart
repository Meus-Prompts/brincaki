// test/games/termo/guess_grid_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/termo/data/daily_store.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/logic/evaluate.dart';
import 'package:brincaki/games/termo/providers/game_provider.dart';
import 'package:brincaki/games/termo/widgets/guess_grid.dart';

class _Store implements DailyStore {
  @override
  Future<DailyState?> load() async => null;
  @override
  Future<void> save(DailyState s) async {}
}

/// Resposta sempre CARRO.
Future<TermoProvider> pumpGrid(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = TermoProvider(
    bank: Future.value(WordBank(
      valid: const {'CARRO': 'CARRO', 'PORTA': 'PORTA', 'MACAS': 'MAÇÃS'},
      answers: const ['CARRO'],
    )),
    store: _Store(),
    now: () => DateTime(2026, 10, 4),
  );
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: Scaffold(body: Center(child: GuessGrid()))),
  ));
  await tester.pumpAndSettle();
  return provider;
}

void typeWord(TermoProvider p, String word) {
  for (final l in word.split('')) {
    p.type(l);
  }
}

/// Quantas casas da grade estão pintadas com [color].
int painted(WidgetTester tester, Color color) => tester
    .widgetList<Container>(find.descendant(of: find.byType(GuessGrid), matching: find.byType(Container)))
    .where((c) => (c.decoration as BoxDecoration?)?.color == color)
    .length;

int whiteTiles(WidgetTester tester) => painted(tester, Colors.white);

/// Deixa passar os atrasos de cada casa e termina as animações.
Future<void> reveal(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  test('resultColor: verde, amarelo e cinza', () {
    expect(resultColor(LetterResult.correct), kTermoGreen);
    expect(resultColor(LetterResult.present), kTermoYellow);
    expect(resultColor(LetterResult.absent), kTermoGrey);
  });

  testWidgets('começa com 30 casas brancas e vazias', (tester) async {
    await pumpGrid(tester);
    expect(whiteTiles(tester), 30);
    expect(find.byType(Text), findsNWidgets(30));
  });

  testWidgets('letras digitadas aparecem na linha atual', (tester) async {
    final p = await pumpGrid(tester);
    typeWord(p, 'POR');
    await tester.pump();
    expect(find.text('P'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
  });

  testWidgets('revelar: as casas viram uma a uma e ganham a cor', (tester) async {
    final p = await pumpGrid(tester);
    typeWord(p, 'PORTA'); // contra CARRO: cinza, amarelo, verde, cinza, amarelo
    p.submit();
    await tester.pump();
    // Logo depois de enviar, ainda tudo branco.
    expect(painted(tester, kTermoGrey), 0);
    expect(painted(tester, kTermoGreen), 0);

    // A primeira casa vira na metade da animação; as outras ainda não.
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 130));
    expect(painted(tester, kTermoGrey), 1);
    expect(painted(tester, kTermoYellow), 0);

    await reveal(tester);
    expect(painted(tester, kTermoGrey), 2);
    expect(painted(tester, kTermoYellow), 2);
    expect(painted(tester, kTermoGreen), 1);
    expect(whiteTiles(tester), 25);
  });

  testWidgets('mostra a tentativa com a grafia certa', (tester) async {
    final p = await pumpGrid(tester);
    typeWord(p, 'MACAS'); // MAÇÃS contra CARRO: A verde, Ç amarelo, Ã cinza
    p.submit();
    await reveal(tester);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Ç'), findsOneWidget);
    expect(find.text('Ã'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
  });

  testWidgets('erro faz a linha atual tremer', (tester) async {
    final p = await pumpGrid(tester);
    expect(find.byKey(const ValueKey('shake-1')), findsNothing);
    typeWord(p, 'PO');
    p.submit();
    await tester.pump();
    expect(find.byKey(const ValueKey('shake-1')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    final moving = tester.widget<Transform>(find.descendant(
      of: find.byKey(const ValueKey('shake-1')),
      matching: find.byType(Transform),
    ).first);
    expect(moving.transform.getTranslation().x, isNot(0));

    await tester.pumpAndSettle();
    final still = tester.widget<Transform>(find.descendant(
      of: find.byKey(const ValueKey('shake-1')),
      matching: find.byType(Transform),
    ).first);
    expect(still.transform.getTranslation().x, closeTo(0, 0.01));

    p.submit();
    await tester.pump();
    expect(find.byKey(const ValueKey('shake-2')), findsOneWidget);
  });

  testWidgets('sair da tela no meio da revelação não deixa timer pendente',
      (tester) async {
    final p = await pumpGrid(tester);
    typeWord(p, 'PORTA');
    p.submit();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    // O teste falharia com "A Timer is still pending" se o timer ficasse.
  });

  testWidgets('com a partida terminada não sobra linha atual', (tester) async {
    final p = await pumpGrid(tester);
    typeWord(p, 'CARRO');
    p.submit();
    await reveal(tester);
    expect(painted(tester, kTermoGreen), 5);
    expect(whiteTiles(tester), 25);
    expect(find.byKey(const ValueKey('shake-1')), findsNothing);
  });
}
