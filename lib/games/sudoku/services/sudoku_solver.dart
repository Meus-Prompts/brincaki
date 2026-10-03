class SudokuSolver {
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
    // Check row
    for (int c = 0; c < 9; c++) {
      if (grid[row][c] == num) return false;
    }

    // Check column
    for (int r = 0; r < 9; r++) {
      if (grid[r][col] == num) return false;
    }

    // Check 3x3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (grid[r][c] == num) return false;
      }
    }

    return true;
  }

  bool hasUniqueSolution(List<List<int>> grid) {
    int solutions = 0;
    _countSolutions(grid, () => solutions++);
    return solutions == 1;
  }

  void _countSolutions(List<List<int>> grid, void Function() onSolution) {
    final empty = _findEmpty(grid);
    if (empty == null) {
      onSolution();
      return;
    }

    final (row, col) = empty;

    for (int num = 1; num <= 9; num++) {
      if (_isValid(grid, row, col, num)) {
        grid[row][col] = num;
        _countSolutions(grid, onSolution);
        grid[row][col] = 0;
      }
    }
  }
}
