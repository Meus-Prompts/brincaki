// test/games/sudoku/sudoku_generator_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/sudoku/models/difficulty.dart';
import 'package:brincaki/games/sudoku/models/sudoku_board.dart';
import 'package:brincaki/games/sudoku/services/sudoku_generator.dart';

import 'fixtures.dart';

List<List<int>> valuesOf(SudokuBoard board) => [
  for (var r = 0; r < 9; r++) [for (var c = 0; c < 9; c++) board.getCell(r, c).value],
];

void main() {
  group('SudokuGenerator', () {
    for (final difficulty in Difficulty.values) {
      test('${difficulty.name}: casas vazias entre ${difficulty.minEmpty} e '
          '${difficulty.maxEmpty} em várias sementes', () {
        for (var seed = 0; seed < 10; seed++) {
          final board = SudokuGenerator(random: Random(seed)).generate(difficulty);
          expect(
            emptyCells(board).length,
            inInclusiveRange(difficulty.minEmpty, difficulty.maxEmpty),
            reason: 'semente $seed',
          );
        }
      });
    }

    test('a solução é um Sudoku válido e bate com as casas fixas', () {
      for (var seed = 0; seed < 5; seed++) {
        final board = SudokuGenerator(random: Random(seed)).generate(Difficulty.medium);
        expect(isValidSolution(board.solution), isTrue);
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            final cell = board.getCell(r, c);
            expect(cell.isFixed, !cell.isEmpty);
            expect(cell.isError, isFalse);
            if (cell.isFixed) expect(cell.value, board.solution[r][c]);
          }
        }
      }
    });

    test('a mesma semente gera a mesma partida', () {
      final a = SudokuGenerator(random: Random(42)).generate(Difficulty.hard);
      final b = SudokuGenerator(random: Random(42)).generate(Difficulty.hard);
      expect(valuesOf(a), valuesOf(b));
      expect(a.solution, b.solution);
    });

    test('sementes diferentes geram partidas diferentes', () {
      final a = SudokuGenerator(random: Random(1)).generate(Difficulty.easy);
      final b = SudokuGenerator(random: Random(2)).generate(Difficulty.easy);
      expect(a.solution, isNot(b.solution));
    });

    test('sem semente também gera um tabuleiro válido', () {
      final board = SudokuGenerator().generate(Difficulty.master);
      expect(isValidSolution(board.solution), isTrue);
      expect(
        emptyCells(board).length,
        inInclusiveRange(Difficulty.master.minEmpty, Difficulty.master.maxEmpty),
      );
    });
  });

  test('as dificuldades ficam mais vazias à medida que sobem', () {
    final values = Difficulty.values;
    expect([for (final d in values) d.name], ['Fácil', 'Médio', 'Difícil', 'Expert', 'Master']);
    for (var i = 0; i < values.length; i++) {
      expect(values[i].minEmpty, lessThanOrEqualTo(values[i].maxEmpty));
      if (i > 0) expect(values[i].minEmpty, greaterThan(values[i - 1].maxEmpty));
    }
  });
}
