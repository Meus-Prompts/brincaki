// lib/games/sudoku/services/sudoku_generator.dart

import 'dart:math';

import '../models/difficulty.dart';
import '../models/sudoku_board.dart';
import '../models/sudoku_cell.dart';
import 'sudoku_solver.dart';

/// Gera partidas: sorteia um tabuleiro completo e esvazia de
/// `minEmpty` a `maxEmpty` casas, conforme a dificuldade.
class SudokuGenerator {
  SudokuGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;
  final _solver = SudokuSolver();

  SudokuBoard generate(Difficulty difficulty) {
    final solution = _generateCompletedGrid();
    final puzzle = _removeCells(solution, difficulty);

    final cells = <List<SudokuCell>>[];
    for (int r = 0; r < 9; r++) {
      final row = <SudokuCell>[];
      for (int c = 0; c < 9; c++) {
        final value = puzzle[r][c];
        row.add(SudokuCell(value: value, isFixed: value != 0));
      }
      cells.add(row);
    }

    return SudokuBoard(cells: cells, solution: solution);
  }

  List<List<int>> _generateCompletedGrid() {
    final grid = List.generate(9, (_) => List.filled(9, 0));

    // Os blocos da diagonal não se cruzam: dá para sorteá-los à vontade.
    for (int i = 0; i < 9; i += 3) {
      _fillBox(grid, i, i);
    }

    // O resto sai do solver.
    _solver.solve(grid);

    return grid;
  }

  void _fillBox(List<List<int>> grid, int startRow, int startCol) {
    final numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_random);
    int index = 0;

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        grid[startRow + r][startCol + c] = numbers[index++];
      }
    }
  }

  List<List<int>> _removeCells(List<List<int>> solution, Difficulty difficulty) {
    final puzzle = solution.map((row) => row.toList()).toList();
    final cellsToRemove =
        difficulty.minEmpty + _random.nextInt(difficulty.maxEmpty - difficulty.minEmpty + 1);

    final positions = <(int, int)>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        positions.add((r, c));
      }
    }
    positions.shuffle(_random);

    int removed = 0;
    for (final (row, col) in positions) {
      if (removed >= cellsToRemove) break;

      puzzle[row][col] = 0;
      removed++;
    }

    return puzzle;
  }
}
