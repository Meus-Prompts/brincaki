// test/games/sudoku/widgets_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/sudoku/models/difficulty.dart';
import 'package:brincaki/games/sudoku/models/sudoku_cell.dart';
import 'package:brincaki/games/sudoku/providers/game_provider.dart';
import 'package:brincaki/games/sudoku/widgets/game_timer.dart';
import 'package:brincaki/games/sudoku/widgets/sudoku_cell_widget.dart';
import 'package:brincaki/games/sudoku/widgets/sudoku_grid.dart';
import 'package:brincaki/widgets/game_palette.dart';

SudokuCellWidget cellWidget(
  SudokuCell cell, {
  bool selected = false,
  bool highlighted = false,
  bool same = false,
  VoidCallback? onTap,
}) => SudokuCellWidget(
  cell: cell,
  isSelected: selected,
  isHighlighted: highlighted,
  isSameNumber: same,
  onTap: onTap ?? () {},
);

void main() {
  group('SudokuCellWidget', () {
    const palette = kSudokuPalette;

    test('fundo: selecionada > erro > mesmo número > destaque > branco', () {
      const free = SudokuCell(value: 3);
      const error = SudokuCell(value: 3, isError: true);
      const empty = SudokuCell();
      expect(
        cellWidget(error, selected: true).backgroundColor,
        palette.accent.withValues(alpha: 0.45),
      );
      expect(cellWidget(error, same: true).backgroundColor, kSudokuError.withValues(alpha: 0.12));
      expect(
        cellWidget(free, same: true, highlighted: true).backgroundColor,
        palette.accent.withValues(alpha: 0.25),
      );
      // Casa vazia nunca conta como "mesmo número".
      expect(cellWidget(empty, same: true, highlighted: true).backgroundColor, palette.background);
      expect(cellWidget(free).backgroundColor, Colors.white);
    });

    test('texto: erro em vermelho, fixa em cinza-escuro, livre na cor do jogo', () {
      expect(cellWidget(const SudokuCell(value: 1, isError: true)).textColor, kSudokuError);
      expect(cellWidget(const SudokuCell(value: 1, isFixed: true)).textColor, kSudokuFixed);
      expect(cellWidget(const SudokuCell(value: 1)).textColor, palette.dark);
    });

    testWidgets('mostra o número, nada quando vazia, e avisa o toque', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              SizedBox.square(
                dimension: 40,
                child: cellWidget(const SudokuCell(value: 7), onTap: () => taps++),
              ),
              SizedBox.square(dimension: 40, child: cellWidget(const SudokuCell())),
            ],
          ),
        ),
      );
      expect(find.text('7'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
      await tester.tap(find.text('7'));
      expect(taps, 1);
    });
  });

  testWidgets('SudokuGrid sem partida não desenha nada', (tester) async {
    final p = SudokuProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: p,
        child: const MaterialApp(home: SudokuGrid()),
      ),
    );
    expect(find.byType(SudokuCellWidget), findsNothing);
    p.dispose();
  });

  testWidgets('SudokuGrid desenha as 81 casas', (tester) async {
    final p = SudokuProvider(random: Random(1))..start(Difficulty.easy);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: p,
        child: const MaterialApp(
          home: Center(child: SizedBox.square(dimension: 300, child: SudokuGrid())),
        ),
      ),
    );
    expect(find.byType(SudokuCellWidget), findsNWidgets(81));
    p.dispose();
  });

  testWidgets('GameTimer acompanha o tempo do provider', (tester) async {
    final p = SudokuProvider(random: Random(1))..start(Difficulty.easy);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: p,
        child: const MaterialApp(home: Scaffold(body: GameTimer())),
      ),
    );
    expect(find.text('00:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
    expect(find.text('01:01'), findsOneWidget);
    final text = tester.widget<Text>(find.text('01:01'));
    expect(text.style!.color, kSudokuPalette.dark);
    p.dispose();
  });
}
