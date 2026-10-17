// lib/games/tictactoe/logic/board.dart

/// Tabuleiro 3x3: 0 é casa vazia, 1 é ❌ e 2 é ⭕.
const int kSize = 3;

/// As 8 linhas que dão vitória: 3 horizontais, 3 verticais e 2 diagonais.
const List<List<(int, int)>> kLines = [
  [(0, 0), (0, 1), (0, 2)],
  [(1, 0), (1, 1), (1, 2)],
  [(2, 0), (2, 1), (2, 2)],
  [(0, 0), (1, 0), (2, 0)],
  [(0, 1), (1, 1), (2, 1)],
  [(0, 2), (1, 2), (2, 2)],
  [(0, 0), (1, 1), (2, 2)],
  [(0, 2), (1, 1), (2, 0)],
];

List<List<int>> emptyBoard() => List.generate(kSize, (_) => List.filled(kSize, 0));

bool isInside(int row, int col) => row >= 0 && row < kSize && col >= 0 && col < kSize;

/// Cópia do tabuleiro com a peça de [player] em ([row], [col]).
List<List<int>> place(List<List<int>> board, int row, int col, int player) {
  if (!isInside(row, col)) throw RangeError('Casa ($row, $col) fora do tabuleiro');
  if (board[row][col] != 0) throw ArgumentError('Casa ($row, $col) ocupada');
  final next = board.map((r) => List<int>.from(r)).toList();
  next[row][col] = player;
  return next;
}

/// As 3 casas alinhadas de qualquer jogador, ou null.
List<(int, int)>? winningLine(List<List<int>> board) {
  for (final line in kLines) {
    final (r, c) = line.first;
    final v = board[r][c];
    if (v != 0 && line.every((p) => board[p.$1][p.$2] == v)) return line;
  }
  return null;
}

/// Se [player] tem 3 casas alinhadas.
bool hasLine(List<List<int>> board, int player) =>
    kLines.any((line) => line.every((p) => board[p.$1][p.$2] == player));

bool isFull(List<List<int>> board) => board.every((r) => r.every((v) => v != 0));

List<(int, int)> freeCells(List<List<int>> board) => [
  for (var r = 0; r < kSize; r++)
    for (var c = 0; c < kSize; c++)
      if (board[r][c] == 0) (r, c),
];
