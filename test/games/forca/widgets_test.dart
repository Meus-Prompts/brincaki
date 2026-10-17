// test/games/forca/widgets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/forca/models/game_state.dart';
import 'package:brincaki/games/forca/widgets/hangman_painter.dart';
import 'package:brincaki/games/forca/widgets/letter_keyboard.dart';
import 'package:brincaki/games/forca/widgets/word_display.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('HangmanWidget', () {
    RenderObject painter(WidgetTester tester) => tester.renderObject(find.descendant(
          of: find.byType(HangmanWidget),
          matching: find.byType(CustomPaint),
        ));

    // A forca tem 4 linhas; a cabeça é um arco; cada parte do corpo, uma linha.
    const lines = [4, 4, 5, 6, 7, 8, 9];

    for (var errors = 0; errors <= 6; errors++) {
      testWidgets('com $errors erros desenha a etapa $errors', (tester) async {
        await tester.pumpWidget(wrap(HangmanWidget(wrongCount: errors)));
        expect(tester.takeException(), isNull);
        expect(painter(tester), paintsExactlyCountTimes(#drawLine, lines[errors]));
        expect(painter(tester), paintsExactlyCountTimes(#drawArc, errors == 0 ? 0 : 1));
      });
    }

    testWidgets('tem 200x220', (tester) async {
      await tester.pumpWidget(wrap(const HangmanWidget(wrongCount: 0)));
      expect(tester.getSize(find.byType(HangmanWidget)), const Size(200, 220));
    });

    testWidgets('mais de 6 erros desenha o boneco completo', (tester) async {
      await tester.pumpWidget(wrap(const HangmanWidget(wrongCount: 9)));
      expect(painter(tester), paintsExactlyCountTimes(#drawLine, 9));
      expect(painter(tester), paintsExactlyCountTimes(#drawArc, 1));
    });

    testWidgets('a parte nova aparece animada', (tester) async {
      await tester.pumpWidget(wrap(const HangmanWidget(wrongCount: 1)));
      await tester.pumpWidget(wrap(const HangmanWidget(wrongCount: 2)));
      // Início da animação: o corpo ainda não foi desenhado.
      expect(painter(tester), paintsExactlyCountTimes(#drawLine, 4));
      await tester.pump(const Duration(milliseconds: 200));
      expect(painter(tester), paintsExactlyCountTimes(#drawLine, 5));
      await tester.pumpAndSettle();
      expect(
        painter(tester),
        paints
          ..arc()
          ..line(p1: const Offset(150, 89), p2: const Offset(150, 149)),
      );
    });

    testWidgets('cada parte nova anima uma de cada vez até o fim', (tester) async {
      for (var errors = 0; errors <= 6; errors++) {
        await tester.pumpWidget(wrap(HangmanWidget(wrongCount: errors)));
        await tester.pump(const Duration(milliseconds: 100));
        expect(painter(tester), paintsExactlyCountTimes(#drawLine, lines[errors]));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('pular vários erros de uma vez desenha tudo', (tester) async {
      await tester.pumpWidget(wrap(const HangmanWidget(wrongCount: 0)));
      await tester.pumpWidget(wrap(const HangmanWidget(wrongCount: 4)));
      await tester.pumpAndSettle();
      expect(painter(tester), paintsExactlyCountTimes(#drawLine, 7));
    });

    testWidgets('voltar a zero erros (palavra nova) apaga o boneco', (tester) async {
      await tester.pumpWidget(wrap(const HangmanWidget(wrongCount: 6)));
      await tester.pumpWidget(wrap(const HangmanWidget(wrongCount: 0)));
      await tester.pumpAndSettle();
      expect(painter(tester), paintsExactlyCountTimes(#drawLine, 4));
      expect(painter(tester), paintsExactlyCountTimes(#drawArc, 0));
    });
  });

  group('WordDisplay', () {
    Iterable<String> slots(WidgetTester tester) => tester
        .widgetList<Text>(find.descendant(
          of: find.byType(WordDisplay),
          matching: find.byType(Text),
        ))
        .map((t) => t.data!);

    testWidgets('esconde as letras não acertadas', (tester) async {
      await tester.pumpWidget(wrap(const WordDisplay(word: 'GATO', correctLetters: {})));
      expect(slots(tester), [' ', ' ', ' ', ' ']);
    });

    testWidgets('mostra a letra acertada em todas as posições', (tester) async {
      await tester.pumpWidget(wrap(const WordDisplay(word: 'BANANA', correctLetters: {'A'})));
      await tester.pumpAndSettle();
      expect(slots(tester), [' ', 'A', ' ', 'A', ' ', 'A']);
    });

    testWidgets('palavra completa', (tester) async {
      await tester.pumpWidget(
          wrap(const WordDisplay(word: 'UVA', correctLetters: {'U', 'V', 'A'})));
      await tester.pumpAndSettle();
      expect(slots(tester), ['U', 'V', 'A']);
    });

    testWidgets('palavra longa quebra linha numa tela estreita', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          wrap(const WordDisplay(word: 'ESTEGOSSAURO', correctLetters: {'S'})));
      expect(tester.takeException(), isNull);
      final first = tester.getTopLeft(find.text('S').first);
      final last = tester.getTopLeft(find.text('S').last);
      expect(last.dy, greaterThan(first.dy));
    });
  });

  group('LetterKeyboard', () {
    Color keyColor(WidgetTester tester, String letter) {
      final box = tester.widget<AnimatedContainer>(find.descendant(
        of: find.byKey(ValueKey('tecla-$letter')),
        matching: find.byType(AnimatedContainer),
      ));
      return (box.decoration! as BoxDecoration).color!;
    }

    Color textColor(WidgetTester tester, String letter) =>
        tester.widget<Text>(find.text(letter)).style!.color!;

    Future<List<String>> pumpKeyboard(
      WidgetTester tester, {
      Map<String, LetterState> states = const {},
      bool disabled = false,
    }) async {
      final taps = <String>[];
      await tester.pumpWidget(wrap(LetterKeyboard(
        letterStates: states,
        onLetterTap: taps.add,
        disabled: disabled,
      )));
      return taps;
    }

    testWidgets('mostra as 26 letras', (tester) async {
      await pumpKeyboard(tester);
      for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
        expect(find.byKey(ValueKey('tecla-$letter')), findsOneWidget);
        expect(find.text(letter), findsOneWidget);
      }
    });

    testWidgets('cores por estado', (tester) async {
      await pumpKeyboard(tester, states: const {
        'A': LetterState.correct,
        'B': LetterState.wrong,
        'C': LetterState.unguessed,
      });
      expect(keyColor(tester, 'A'), const Color(0xFF16A34A));
      expect(keyColor(tester, 'B'), const Color(0xFFDC2626));
      expect(keyColor(tester, 'C'), const Color(0xFFE2E8F0));
      expect(keyColor(tester, 'D'), const Color(0xFFE2E8F0));
      expect(textColor(tester, 'A'), Colors.white);
      expect(textColor(tester, 'B'), Colors.white);
      expect(textColor(tester, 'D'), const Color(0xFF1E293B));
    });

    testWidgets('só as letras não tentadas têm sombra', (tester) async {
      await pumpKeyboard(tester, states: const {'A': LetterState.correct});
      BoxDecoration deco(String l) => tester
          .widget<AnimatedContainer>(find.descendant(
            of: find.byKey(ValueKey('tecla-$l')),
            matching: find.byType(AnimatedContainer),
          ))
          .decoration! as BoxDecoration;
      expect(deco('A').boxShadow, isNull);
      expect(deco('B').boxShadow, isNotEmpty);
    });

    testWidgets('tocar numa letra nova avisa; letras tentadas não', (tester) async {
      final taps = await pumpKeyboard(tester, states: const {
        'A': LetterState.correct,
        'B': LetterState.wrong,
      });
      await tester.tap(find.text('A'));
      await tester.tap(find.text('B'));
      await tester.tap(find.text('C'));
      await tester.tap(find.text('Z'));
      expect(taps, ['C', 'Z']);
    });

    testWidgets('desabilitado não aceita toques nem tem sombra', (tester) async {
      final taps = await pumpKeyboard(tester, disabled: true);
      await tester.tap(find.text('C'));
      expect(taps, isEmpty);
      final box = tester.widget<AnimatedContainer>(find.descendant(
        of: find.byKey(const ValueKey('tecla-C')),
        matching: find.byType(AnimatedContainer),
      ));
      expect((box.decoration! as BoxDecoration).boxShadow, isNull);
    });

    for (final size in const [Size(360, 740), Size(320, 568)]) {
      testWidgets('cabe em ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpKeyboard(tester);
        expect(tester.takeException(), isNull);
        for (final letter in ['A', 'Z']) {
          final rect = tester.getRect(find.byKey(ValueKey('tecla-$letter')));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
        }
      });
    }
  });
}
