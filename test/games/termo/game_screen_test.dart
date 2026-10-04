// test/games/termo/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/termo/data/daily_store.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/models/game_state.dart';
import 'package:brincaki/games/termo/providers/game_provider.dart';
import 'package:brincaki/games/termo/screens/game_screen.dart';

class _Store implements DailyStore {
  DailyState? state;
  @override
  Future<DailyState?> load() async => state;
  @override
  Future<void> save(DailyState s) async => state = s;
}

final _bank = WordBank(
  valid: {
    'CARRO': 'CARRO', 'PEDRA': 'PEDRA', 'AVIAO': 'AVIÃO',
    'PORTA': 'PORTA', 'MESAS': 'MESAS',
  },
  answers: ['CARRO', 'PEDRA', 'AVIAO'],
);

Future<TermoProvider> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = TermoProvider(
    bank: Future.value(_bank),
    store: _Store(),
    now: () => DateTime(2026, 10, 4),
    random: Random(3),
  );
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: TermoScreen()),
  ));
  await tester.pumpAndSettle();
  return provider;
}

Future<void> tapWord(WidgetTester tester, String word) async {
  for (final letter in word.split('')) {
    await tester.tap(find.byKey(Key('key-$letter')));
  }
  await tester.tap(find.byKey(const Key('key-ENTER')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('acertar pelo teclado da tela mostra a vitória', (tester) async {
    final p = await pumpScreen(tester);
    expect(find.text('Palavra do dia'), findsOneWidget);
    await tapWord(tester, p.answer);
    expect(p.phase, TermoPhase.won);
    expect(find.text('🎉 Acertou em 1!'), findsOneWidget);
    expect(find.text('Volte amanhã para a próxima palavra!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('palavra inválida mostra o aviso', (tester) async {
    final p = await pumpScreen(tester);
    await tapWord(tester, 'CARRA'); // 5 letras, mas não está no dicionário
    expect(find.text('Palavra inválida'), findsOneWidget);
    expect(p.guesses, isEmpty);
  });

  testWidgets('aviso de erro fica acima do teclado, sem cobrir as teclas',
      (tester) async {
    await pumpScreen(tester);
    await tapWord(tester, 'CARRA');
    final warning = tester.getRect(find.text('Palavra inválida'));
    final keyboardTop = tester.getRect(find.byKey(const Key('key-Q'))).top;
    expect(warning.bottom, lessThan(keyboardTop));
  });

  testWidgets('teclado físico também funciona', (tester) async {
    final p = await pumpScreen(tester);
    final wrong = ['PORTA', 'MESAS'].firstWhere((w) => w != p.answer);
    for (final letter in wrong.split('')) {
      await tester.sendKeyEvent(
          LogicalKeyboardKey.findKeyByKeyId(letter.toLowerCase().codeUnitAt(0))!);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(p.guesses, [wrong]);
  });

  testWidgets('ilimitado: perder mostra a resposta e Nova palavra',
      (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Ilimitado'));
    await tester.pumpAndSettle();
    expect(p.mode, TermoMode.unlimited);
    final wrong = ['PORTA', 'MESAS'].firstWhere((w) => w != p.answer);
    for (var i = 0; i < TermoProvider.maxGuesses; i++) {
      await tapWord(tester, wrong);
    }
    expect(find.text('A palavra era: ${p.answerDisplay}'), findsOneWidget);
    await tester.tap(find.text('Nova palavra'));
    await tester.pumpAndSettle();
    expect(p.phase, TermoPhase.playing);
  });
}
