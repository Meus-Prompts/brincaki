// lib/games/sudoku/models/sudoku_board.dart

import 'sudoku_cell.dart';

/// Tabuleiro imutável: cada jogada devolve um novo, com os conflitos marcados.
class SudokuBoard {
  final List<List<SudokuCell>> cells;
  final List<List<int>> solution;

  SudokuBoard({required this.cells, required this.solution});

  SudokuCell getCell(int row, int col) => cells[row][col];

  SudokuBoard setCell(int row, int col, int value) {
    final newCells = cells.map((r) => r.toList()).toList();
    final cell = newCells[row][col];

    if (cell.isFixed) return this;

    newCells[row][col] = cell.copyWith(value: value, isError: false);

    // Mudar uma casa pode criar ou desfazer conflitos em outras da mesma
    // linha, coluna ou bloco: reavalia todas.
    return SudokuBoard(cells: newCells, solution: solution).revalidateAll();
  }

  bool isValidMove(int row, int col, int value) {
    // Linha
    for (int c = 0; c < 9; c++) {
      if (c != col && cells[row][c].value == value) return false;
    }

    // Coluna
    for (int r = 0; r < 9; r++) {
      if (r != row && cells[r][col].value == value) return false;
    }

    // Bloco 3x3 (linha e coluna já foram vistas acima)
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (r != row && c != col && cells[r][c].value == value) return false;
      }
    }

    return true;
  }

  bool get isComplete {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = cells[r][c];
        if (cell.isEmpty || cell.isError) return false;
      }
    }
    return true;
  }

  int getHint(int row, int col) => solution[row][col];

  SudokuBoard revalidateAll() {
    final newCells = <List<SudokuCell>>[];

    for (int r = 0; r < 9; r++) {
      final row = <SudokuCell>[];
      for (int c = 0; c < 9; c++) {
        final cell = cells[r][c];
        if (!cell.isFixed && cell.value != 0) {
          final isError = !isValidMove(r, c, cell.value);
          row.add(cell.copyWith(isError: isError));
        } else {
          row.add(cell);
        }
      }
      newCells.add(row);
    }

    return SudokuBoard(cells: newCells, solution: solution);
  }
}
