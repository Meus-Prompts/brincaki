// test/games/termo/termo_keyboard_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/termo/data/daily_store.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/providers/game_provider.dart';
import 'package:brincaki/games/termo/widgets/guess_grid.dart';
import 'package:brincaki/games/termo/widgets/termo_keyboard.dart';

class _Store implements DailyStore {
  @override
  Future<DailyState?> load() async => null;
  @override
  Future<void> save(DailyState s) async {}
}

const _plain = Color(0xFFE2E8F0);

Future<TermoProvider> pumpKeyboard(WidgetTester tester, {double width = 360}) async {
  tester.view.physicalSize = Size(width, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = TermoProvider(
    bank: Future.value(WordBank(
      valid: const {'CARRO': 'CARRO', 'PORTA': 'PORTA'},
      answers: const ['CARRO'],
    )),
    store: _Store(),
    now: () => DateTime(2026, 10, 4),
  );
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: Scaffold(body: TermoKeyboard())),
  ));
  await tester.pumpAndSettle();
  return provider;
}

Finder _key(String label) => find.byKey(Key('key-$label'));

Color keyColor(WidgetTester tester, String label) => tester
    .widget<Material>(find.ancestor(of: _key(label), matching: find.byType(Material)).first)
    .color!;

Color labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.descendant(of: _key(label), matching: find.byType(Text))).style!.color!;

Future<void> tapKeys(WidgetTester tester, String labels) async {
  for (final label in labels.split('')) {
    await tester.tap(_key(label));
  }
  await tester.pump();
}

void main() {
  testWidgets('tem as 26 letras, ENTER e apagar', (tester) async {
    await pumpKeyboard(tester);
    for (var code = 'A'.codeUnitAt(0); code <= 'Z'.codeUnitAt(0); code++) {
      expect(_key(String.fromCharCode(code)), findsOneWidget);
    }
    expect(_key('ENTER'), findsOneWidget);
    expect(_key('⌫'), findsOneWidget);
  });

  testWidgets('começa com todas as teclas neutras', (tester) async {
    await pumpKeyboard(tester);
    for (final label in ['A', 'Q', 'M', 'ENTER', '⌫']) {
      expect(keyColor(tester, label), _plain);
      expect(labelColor(tester, label), const Color(0xFF0F172A));
    }
  });

  testWidgets('tocar nas letras digita', (tester) async {
    final p = await pumpKeyboard(tester);
    await tapKeys(tester, 'POR');
    expect(p.current, 'POR');
  });

  testWidgets('apagar tira a última letra', (tester) async {
    final p = await pumpKeyboard(tester);
    await tapKeys(tester, 'PO');
    await tester.tap(_key('⌫'));
    await tester.pump();
    expect(p.current, 'P');
  });

  testWidgets('ENTER envia a tentativa', (tester) async {
    final p = await pumpKeyboard(tester);
    await tapKeys(tester, 'PORTA');
    await tester.tap(_key('ENTER'));
    await tester.pump();
    expect(p.guesses, ['PORTA']);
  });

  testWidgets('ENTER com palavra curta mostra o erro', (tester) async {
    final p = await pumpKeyboard(tester);
    await tapKeys(tester, 'PO');
    await tester.tap(_key('ENTER'));
    await tester.pump();
    expect(p.lastError, 'Só palavras com 5 letras');
  });

  testWidgets('teclas ganham a cor do resultado com letra branca', (tester) async {
    await pumpKeyboard(tester);
    await tapKeys(tester, 'PORTA'); // contra CARRO: P cinza, O amarelo, R verde
    await tester.tap(_key('ENTER'));
    await tester.pump();

    expect(keyColor(tester, 'R'), kTermoGreen);
    expect(keyColor(tester, 'O'), kTermoYellow);
    expect(keyColor(tester, 'A'), kTermoYellow);
    expect(keyColor(tester, 'P'), kTermoGrey);
    expect(keyColor(tester, 'T'), kTermoGrey);
    expect(labelColor(tester, 'R'), Colors.white);
    // Letras não usadas continuam neutras.
    expect(keyColor(tester, 'C'), _plain);
    expect(labelColor(tester, 'C'), const Color(0xFF0F172A));
  });

  for (final width in [360.0, 320.0]) {
    testWidgets('cabe em ${width.toInt()} de largura', (tester) async {
      await pumpKeyboard(tester, width: width);
      expect(tester.takeException(), isNull);
      expect(tester.getRect(_key('P')).right, lessThanOrEqualTo(width));
      expect(tester.getRect(_key('⌫')).right, lessThanOrEqualTo(width));
    });
  }
}
