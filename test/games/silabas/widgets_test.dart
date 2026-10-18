// test/games/silabas/widgets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/silabas/models/game_state.dart';
import 'package:brincaki/games/silabas/widgets/classify_buttons.dart';
import 'package:brincaki/games/silabas/widgets/split_word.dart';
import 'package:brincaki/games/silabas/widgets/syllable_blocks.dart';
import 'package:brincaki/widgets/game_palette.dart';

Widget wrap(Widget child, {double width = 360}) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );

const _red = Color(0xFFDC2626);
const _green = Color(0xFF16A34A);

Color? barColor(WidgetTester tester, int pos) {
  final box = tester.widget<Container>(find.descendant(
    of: find.byKey(Key('corte-$pos')),
    matching: find.byType(Container),
  ));
  return (box.decoration as BoxDecoration).color;
}

BoxDecoration blockDecoration(WidgetTester tester, int i) {
  final box = tester.widget<Container>(find.descendant(
    of: find.byKey(Key('silaba-$i')),
    matching: find.byType(Container),
  ));
  return box.decoration as BoxDecoration;
}

Color? textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('SplitWord', () {
    testWidgets('um espaço entre cada par de letras, com 24 px ou mais',
        (tester) async {
      await tester.pumpWidget(wrap(SplitWord(
        palette: kSilabasPalette,
        text: 'pássaro',
        cuts: const {},
        wrongCuts: const {},
        onToggle: (_) {},
      )));
      for (var pos = 1; pos <= 6; pos++) {
        final size = tester.getSize(find.byKey(Key('corte-$pos')));
        expect(size.width, greaterThanOrEqualTo(24));
        expect(size.height, greaterThan(40));
      }
      expect(find.byKey(const Key('corte-0')), findsNothing);
      expect(find.byKey(const Key('corte-7')), findsNothing);
    });

    testWidgets('tocar no espaço chama o callback com a posição',
        (tester) async {
      final toggled = <int>[];
      await tester.pumpWidget(wrap(SplitWord(
        palette: kSilabasPalette,
        text: 'bola',
        cuts: const {},
        wrongCuts: const {},
        onToggle: toggled.add,
      )));
      await tester.tap(find.byKey(const Key('corte-2')));
      await tester.tap(find.byKey(const Key('corte-1')));
      expect(toggled, [2, 1]);
    });

    testWidgets('blocos lado a lado, do tamanho do conteúdo', (tester) async {
      await tester.pumpWidget(wrap(const SyllableBlocks(
        palette: kSilabasPalette,
        syllables: ['pás', 'sa', 'ro'],
      )));
      final a = tester.getRect(find.byKey(const Key('silaba-0')));
      final b = tester.getRect(find.byKey(const Key('silaba-1')));
      expect(b.top, a.top);
      expect(b.left, greaterThan(a.right));
      expect(a.width, lessThan(120));
    });

    testWidgets('separadores só quando pedidos', (tester) async {
      await tester.pumpWidget(wrap(const SyllableBlocks(
        palette: kSilabasPalette,
        syllables: ['pás', 'sa', 'ro'],
      )));
      expect(find.text('·'), findsNothing);
      await tester.pumpWidget(wrap(const SyllableBlocks(
        palette: kSilabasPalette,
        syllables: ['pás', 'sa', 'ro'],
        separators: true,
      )));
      expect(find.text('·'), findsNWidgets(2));
    });

    testWidgets('sem callback, tocar não faz nada', (tester) async {
      await tester.pumpWidget(wrap(const SplitWord(
        palette: kSilabasPalette,
        text: 'bola',
        cuts: {},
        wrongCuts: {},
      )));
      await tester.tap(find.byKey(const Key('corte-2')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('corte ligado na cor do jogo, errado em vermelho',
        (tester) async {
      await tester.pumpWidget(wrap(const SplitWord(
        palette: kSilabasPalette,
        text: 'bola',
        cuts: {1, 2},
        wrongCuts: {1},
      )));
      expect(barColor(tester, 1), _red);
      expect(barColor(tester, 2), kSilabasPalette.accent);
      expect(barColor(tester, 3), isNot(kSilabasPalette.accent));
      expect(barColor(tester, 3), isNot(_red));
    });

    testWidgets('palavra de 10 letras em 288 px mantém os espaços de 24 px',
        (tester) async {
      await tester.pumpWidget(wrap(
        SplitWord(
          palette: kSilabasPalette,
          text: 'bicicletas',
          cuts: const {},
          wrongCuts: const {},
          onToggle: (_) {},
        ),
        width: 288,
      ));
      expect(tester.takeException(), isNull);
      for (var pos = 1; pos <= 9; pos++) {
        expect(tester.getSize(find.byKey(Key('corte-$pos'))).width, 24);
      }
    });

    testWidgets('sem largura limitada usa o tamanho máximo da letra',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SplitWord(
              palette: kSilabasPalette,
              text: 'bola',
              cuts: const {},
              wrongCuts: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('corte-3')), findsOneWidget);
    });
  });

  group('SyllableBlocks', () {
    testWidgets('um bloco por sílaba, tocável', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(wrap(SyllableBlocks(
        palette: kSilabasPalette,
        syllables: const ['pás', 'sa', 'ro'],
        onTap: taps.add,
      )));
      expect(find.text('pás'), findsOneWidget);
      await tester.tap(find.byKey(const Key('silaba-2')));
      await tester.tap(find.byKey(const Key('silaba-0')));
      expect(taps, [2, 0]);
    });

    testWidgets('sem callback, tocar não faz nada', (tester) async {
      await tester.pumpWidget(wrap(const SyllableBlocks(
        palette: kSilabasPalette,
        syllables: ['pás', 'sa', 'ro'],
      )));
      await tester.tap(find.byKey(const Key('silaba-1')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('destacada: cor cheia do jogo e texto branco', (tester) async {
      await tester.pumpWidget(wrap(const SyllableBlocks(
        palette: kSilabasPalette,
        syllables: ['pás', 'sa', 'ro'],
        highlighted: 0,
      )));
      expect(blockDecoration(tester, 0).color, kSilabasPalette.accent);
      expect(textColor(tester, 'pás'), Colors.white);
      expect(blockDecoration(tester, 1).color, Colors.white);
      expect(textColor(tester, 'sa'), kSilabasPalette.dark);
    });

    testWidgets('errada: borda e texto vermelhos, sem toque', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(wrap(SyllableBlocks(
        palette: kSilabasPalette,
        syllables: const ['pás', 'sa', 'ro'],
        wrong: const {1},
        onTap: taps.add,
      )));
      final border = blockDecoration(tester, 1).border as Border;
      expect(border.top.color, _red);
      expect(textColor(tester, 'sa'), _red);
      await tester.tap(find.byKey(const Key('silaba-1')));
      expect(taps, isEmpty);
      await tester.tap(find.byKey(const Key('silaba-2')));
      expect(taps, [2]);
    });
  });

  group('ClassifyButtons', () {
    ElevatedButton button(WidgetTester tester, StressClass c) =>
        tester.widget<ElevatedButton>(find.byKey(Key('classe-${c.name}')));

    testWidgets('três botões com nome e dica', (tester) async {
      final chosen = <StressClass>[];
      await tester.pumpWidget(wrap(ClassifyButtons(
        palette: kSilabasPalette,
        onChoose: chosen.add,
      )));
      expect(find.text('Oxítona'), findsOneWidget);
      expect(find.text('Paroxítona'), findsOneWidget);
      expect(find.text('Proparoxítona'), findsOneWidget);
      expect(find.text('a última é a mais forte'), findsOneWidget);
      expect(find.text('a penúltima é a mais forte'), findsOneWidget);
      expect(find.text('a antepenúltima é a mais forte'), findsOneWidget);
      await tester.tap(find.byKey(const Key('classe-paroxitona')));
      await tester.tap(find.byKey(const Key('classe-oxitona')));
      expect(chosen, [StressClass.paroxitona, StressClass.oxitona]);
    });

    testWidgets('errada: vermelha e desabilitada', (tester) async {
      final chosen = <StressClass>[];
      await tester.pumpWidget(wrap(ClassifyButtons(
        palette: kSilabasPalette,
        wrong: const {StressClass.oxitona},
        onChoose: chosen.add,
      )));
      final wrongButton = button(tester, StressClass.oxitona);
      expect(wrongButton.onPressed, isNull);
      expect(wrongButton.style?.foregroundColor?.resolve({}), _red);
      await tester.tap(find.byKey(const Key('classe-oxitona')));
      expect(chosen, isEmpty);
      expect(button(tester, StressClass.paroxitona).onPressed, isNotNull);
    });

    testWidgets('certa: verde', (tester) async {
      await tester.pumpWidget(wrap(const ClassifyButtons(
        palette: kSilabasPalette,
        correct: StressClass.paroxitona,
      )));
      final style = button(tester, StressClass.paroxitona).style!;
      expect(style.backgroundColor?.resolve({}), _green);
      expect(style.foregroundColor?.resolve({}), Colors.white);
    });

    testWidgets('sem callback, todos desabilitados', (tester) async {
      await tester.pumpWidget(wrap(const ClassifyButtons(
        palette: kSilabasPalette,
      )));
      for (final c in StressClass.values) {
        expect(button(tester, c).onPressed, isNull);
      }
    });
  });
}
