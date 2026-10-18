// test/games/contas/widgets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/contas/widgets/choice_grid.dart';
import 'package:brincaki/games/contas/widgets/number_pad.dart';
import 'package:brincaki/games/contas/widgets/status_bar.dart';
import 'package:brincaki/widgets/game_palette.dart';

Future<void> pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    theme: kContasPalette.theme,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ));
}

StatusBar statusBar({int lives = 3, int streak = 0, int score = 0, int multiplier = 1}) =>
    StatusBar(
      lives: lives,
      maxLives: 3,
      streak: streak,
      score: score,
      multiplier: multiplier,
      maxMultiplier: 5,
      streakStep: 5,
    );

void main() {
  test('paleta verde-limão das Contas', () {
    expect(kContasPalette.accent, const Color(0xFF65A30D));
    expect(kContasPalette.light, const Color(0xFF84CC16));
    expect(kContasPalette.dark, const Color(0xFF3F6212));
    expect(kContasPalette.background, const Color(0xFFF7FEE7));
  });

  group('StatusBar', () {
    testWidgets('vidas cheias e vazias, sequência e pontos', (tester) async {
      await pump(tester, statusBar(lives: 2, streak: 6, score: 140, multiplier: 2));
      Icon heart(int i) => tester.widget<Icon>(find.byKey(Key('vida-$i')));
      expect(heart(0).icon, Icons.favorite);
      expect(heart(1).icon, Icons.favorite);
      expect(heart(2).icon, Icons.favorite_border);
      expect(find.text('🔥 6'), findsOneWidget);
      expect(find.text('⭐ 140'), findsOneWidget);
    });

    testWidgets('quanto falta para o próximo multiplicador', (tester) async {
      await pump(tester, statusBar(streak: 6, multiplier: 2));
      expect(find.text('×2 pontos · faltam 4 para ×3'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(bar.value, closeTo(0.2, 0.001));
    });

    testWidgets('no ×5 a barra fica cheia', (tester) async {
      await pump(tester, statusBar(streak: 27, multiplier: 5));
      expect(find.text('×5 pontos'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(bar.value, 1.0);
    });
  });

  group('NumberPad', () {
    testWidgets('teclas chamam os callbacks', (tester) async {
      final digits = <int>[];
      var deleted = 0;
      var submitted = 0;
      await pump(
        tester,
        NumberPad(
          typed: '56',
          onDigit: digits.add,
          onDelete: () => deleted++,
          onSubmit: () => submitted++,
        ),
      );
      expect(find.text('56'), findsOneWidget);
      for (var d = 0; d <= 9; d++) {
        await tester.tap(find.byKey(Key('tecla-$d')));
      }
      await tester.tap(find.byKey(const Key('tecla-apagar')));
      await tester.tap(find.byKey(const Key('tecla-ok')));
      expect(digits, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(deleted, 1);
      expect(submitted, 1);
    });

    testWidgets('confirmar fica desligado sem resposta', (tester) async {
      var submitted = 0;
      await pump(
        tester,
        NumberPad(
          typed: '',
          onDigit: (_) {},
          onDelete: () {},
          onSubmit: () => submitted++,
        ),
      );
      await tester.tap(find.byKey(const Key('tecla-ok')));
      expect(submitted, 0);
    });
  });

  testWidgets('ChoiceGrid mostra as 4 opções e avisa o toque', (tester) async {
    final chosen = <int>[];
    await pump(tester, ChoiceGrid(choices: const [54, 56, 48, 63], onChoose: chosen.add));
    for (final value in [54, 56, 48, 63]) {
      expect(find.text('$value'), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('opcao-56')));
    await tester.tap(find.byKey(const Key('opcao-63')));
    expect(chosen, [56, 63]);
  });
}
