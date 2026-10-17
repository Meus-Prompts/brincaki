// test/games/sudoku/fixtures.dart

import 'package:brincaki/games/sudoku/models/sudoku_board.dart';
import 'package:brincaki/games/sudoku/models/sudoku_cell.dart';

/// Um tabuleiro resolvido conhecido.
const kSolved = [
  [5, 3, 4, 6, 7, 8, 9, 1, 2],
  [6, 7, 2, 1, 9, 5, 3, 4, 8],
  [1, 9, 8, 3, 4, 2, 5, 6, 7],
  [8, 5, 9, 7, 6, 1, 4, 2, 3],
  [4, 2, 6, 8, 5, 3, 7, 9, 1],
  [7, 1, 3, 9, 2, 4, 8, 5, 6],
  [9, 6, 1, 5, 3, 7, 2, 8, 4],
  [2, 8, 7, 4, 1, 9, 6, 3, 5],
  [3, 4, 5, 2, 8, 6, 1, 7, 9],
];

/// O problema clássico desse tabuleiro, com solução única.
const kPuzzle = [
  [5, 3, 0, 0, 7, 0, 0, 0, 0],
  [6, 0, 0, 1, 9, 5, 0, 0, 0],
  [0, 9, 8, 0, 0, 0, 0, 6, 0],
  [8, 0, 0, 0, 6, 0, 0, 0, 3],
  [4, 0, 0, 8, 0, 3, 0, 0, 1],
  [7, 0, 0, 0, 2, 0, 0, 0, 6],
  [0, 6, 0, 0, 0, 0, 2, 8, 0],
  [0, 0, 0, 4, 1, 9, 0, 0, 5],
  [0, 0, 0, 0, 8, 0, 0, 7, 9],
];

List<List<int>> copyGrid(List<List<int>> grid) => [for (final row in grid) row.toList()];

/// Tabuleiro de jogo montado a partir de [puzzle] (casas != 0 são fixas).
SudokuBoard boardFrom(List<List<int>> puzzle, {List<List<int>> solution = kSolved}) {
  return SudokuBoard(
    cells: [
      for (final row in puzzle) [for (final v in row) SudokuCell(value: v, isFixed: v != 0)],
    ],
    solution: copyGrid(solution),
  );
}

/// Casas vazias de [board], de cima para baixo.
List<(int, int)> emptyCells(SudokuBoard board) => [
  for (var r = 0; r < 9; r++)
    for (var c = 0; c < 9; c++)
      if (board.getCell(r, c).isEmpty) (r, c),
];

bool isValidSolution(List<List<int>> grid) {
  bool ok(Iterable<int> values) => values.toSet().length == 9 && !values.contains(0);
  for (var i = 0; i < 9; i++) {
    if (!ok(grid[i])) return false;
    if (!ok([for (var r = 0; r < 9; r++) grid[r][i]])) return false;
    final br = (i ~/ 3) * 3, bc = (i % 3) * 3;
    if (!ok([
      for (var r = br; r < br + 3; r++)
        for (var c = bc; c < bc + 3; c++) grid[r][c],
    ])) {
      return false;
    }
  }
  return true;
}
