// lib/games/lig4/logic/board.dart

const int kRows = 6;
const int kCols = 7;

const _directions = [(0, 1), (1, 0), (1, 1), (-1, 1)];

List<List<int>> emptyBoard() => List.generate(kRows, (_) => List.filled(kCols, 0));

/// Linha onde a peça cairia na coluna, ou null se a coluna estiver cheia.
int? dropRow(List<List<int>> board, int col) {
  for (var r = kRows - 1; r >= 0; r--) {
    if (board[r][col] == 0) return r;
  }
  return null;
}

List<List<int>> drop(List<List<int>> board, int col, int player) {
  final row = dropRow(board, col);
  if (row == null) throw ArgumentError('Coluna $col cheia');
  final next = board.map((r) => List<int>.from(r)).toList();
  next[row][col] = player;
  return next;
}

/// As 4 células alinhadas de qualquer jogador, ou null.
List<(int, int)>? winningLine(List<List<int>> board) {
  for (final player in const [1, 2]) {
    final line = _lineOf(board, player);
    if (line != null) return line;
  }
  return null;
}

bool hasLine(List<List<int>> board, int player) => _lineOf(board, player) != null;

List<(int, int)>? _lineOf(List<List<int>> board, int player) {
  for (var r = 0; r < kRows; r++) {
    for (var c = 0; c < kCols; c++) {
      if (board[r][c] != player) continue;
      for (final (dr, dc) in _directions) {
        final cells = [for (var k = 0; k < 4; k++) (r + dr * k, c + dc * k)];
        if (cells.every((p) =>
            p.$1 >= 0 && p.$1 < kRows && p.$2 >= 0 && p.$2 < kCols &&
            board[p.$1][p.$2] == player)) {
          return cells;
        }
      }
    }
  }
  return null;
}

bool isFull(List<List<int>> board) => board[0].every((v) => v != 0);

List<int> validColumns(List<List<int>> board) =>
    [for (var c = 0; c < kCols; c++) if (board[0][c] == 0) c];
