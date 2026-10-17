// test/widgets/solo_setup_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/level_picker.dart';
import 'package:brincaki/widgets/solo_setup.dart';

void main() {
  int? started;

  Future<void> pumpSetup(WidgetTester tester,
      {String levelLabel = 'Nível', int initialLevel = 0}) async {
    started = null;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SoloSetup(
          palette: kSudokuPalette,
          title: 'Sudoku',
          emoji: '🔢',
          levels: const ['Fácil', 'Médio', 'Difícil', 'Expert', 'Master'],
          levelLabel: levelLabel,
          initialLevel: initialLevel,
          onStart: (i) => started = i,
        ),
      ),
    ));
  }

  testWidgets('mostra emoji, título, rótulo, níveis e Jogar!', (tester) async {
    await pumpSetup(tester, levelLabel: 'Dificuldade');
    expect(find.text('🔢'), findsOneWidget);
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Dificuldade'), findsOneWidget);
    for (final level in ['Fácil', 'Médio', 'Difícil', 'Expert', 'Master']) {
      expect(find.text(level), findsOneWidget);
    }
    expect(find.text('Jogar!'), findsOneWidget);
  });

  testWidgets('sem escolher, começa no primeiro nível', (tester) async {
    await pumpSetup(tester);
    await tester.tap(find.text('Jogar!'));
    expect(started, 0);
  });

  testWidgets('começa no nível escolhido', (tester) async {
    await pumpSetup(tester);
    await tester.tap(find.text('Expert'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    expect(started, 3);
  });

  testWidgets('initialLevel já vem marcado', (tester) async {
    await pumpSetup(tester, initialLevel: 2);
    final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Difícil'));
    expect(chip.selected, isTrue);
    await tester.tap(find.text('Jogar!'));
    expect(started, 2);
  });

  testWidgets('cabe numa tela pequena (rola)', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpSetup(tester);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Jogar!'));
    await tester.tap(find.text('Jogar!'));
    expect(started, 0);
  });

  group('LevelPicker', () {
    testWidgets('só o nível escolhido fica marcado', (tester) async {
      var selected = 1;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LevelPicker(
              palette: kForcaPalette,
              label: 'Nível',
              levels: const ['1', '2', '3'],
              selected: selected,
              onChanged: (i) => setState(() => selected = i),
            ),
          ),
        ),
      ));
      List<bool> marks() => tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .map((c) => c.selected)
          .toList();
      expect(marks(), [false, true, false]);
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(selected, 2);
      expect(marks(), [false, false, true]);
    });
  });
}
