// lib/games/sudoku/services/sudoku_solver.dart

/// Resolve tabuleiros 9x9 por backtracking. Casas vazias valem 0.
class SudokuSolver {
  /// Preenche [grid] com a primeira solução encontrada. Devolve `false` (e
  /// deixa [grid] como estava) quando não há solução.
  bool solve(List<List<int>> grid) {
    final empty = _findEmpty(grid);
    if (empty == null) return true;

    final (row, col) = empty;

    for (int num = 1; num <= 9; num++) {
      if (_isValid(grid, row, col, num)) {
        grid[row][col] = num;

        if (solve(grid)) return true;

        grid[row][col] = 0;
      }
    }

    return false;
  }

  (int, int)? _findEmpty(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) return (r, c);
      }
    }
    return null;
  }

  bool _isValid(List<List<int>> grid, int row, int col, int num) {
    // Linha
    for (int c = 0; c < 9; c++) {
      if (grid[row][c] == num) return false;
    }

    // Coluna
    for (int r = 0; r < 9; r++) {
      if (grid[r][col] == num) return false;
    }

    // Bloco 3x3
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (grid[r][c] == num) return false;
      }
    }

    return true;
  }

  /// Conta as soluções de [grid] até [limit] (para de procurar ao chegar
  /// nele). Não altera [grid].
  int countSolutions(List<List<int>> grid, {int limit = 2}) {
    final copy = grid.map((row) => row.toList()).toList();
    var solutions = 0;
    void count() {
      final empty = _findEmpty(copy);
      if (empty == null) {
        solutions++;
        return;
      }
      final (row, col) = empty;
      for (int num = 1; num <= 9 && solutions < limit; num++) {
        if (_isValid(copy, row, col, num)) {
          copy[row][col] = num;
          count();
          copy[row][col] = 0;
        }
      }
    }

    count();
    return solutions;
  }

  bool hasUniqueSolution(List<List<int>> grid) => countSolutions(grid) == 1;
}
