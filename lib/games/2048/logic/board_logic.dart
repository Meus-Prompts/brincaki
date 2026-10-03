// lib/games/2048/logic/board_logic.dart

import 'dart:ui';

enum Direction { up, down, left, right }

class SlideResult {
  const SlideResult({
    required this.board,
    required this.points,
    required this.moved,
    required this.merged,
  });

  final List<List<int>> board;
  final int points;
  final bool moved;

  /// Células (linha, coluna) que receberam uma peça juntada nesta jogada.
  final Set<(int, int)> merged;
}

/// Células de uma linha do tabuleiro, da borda para onde as peças vão
/// até a borda oposta.
List<(int, int)> _line(int index, Direction direction, int size) {
  return switch (direction) {
    Direction.left => [for (var c = 0; c < size; c++) (index, c)],
    Direction.right => [for (var c = size - 1; c >= 0; c--) (index, c)],
    Direction.up => [for (var r = 0; r < size; r++) (r, index)],
    Direction.down => [for (var r = size - 1; r >= 0; r--) (r, index)],
  };
}

SlideResult slide(List<List<int>> board, Direction direction) {
  final size = board.length;
  final result = board.map((row) => List<int>.from(row)).toList();
  final merged = <(int, int)>{};
  var points = 0;
  var moved = false;

  for (var i = 0; i < size; i++) {
    final cells = _line(i, direction, size);
    final tiles = [
      for (final (r, c) in cells)
        if (board[r][c] != 0) board[r][c],
    ];

    final packed = <int>[];
    final mergedAt = <int>[];
    for (var k = 0; k < tiles.length; k++) {
      if (k + 1 < tiles.length && tiles[k] == tiles[k + 1]) {
        final value = tiles[k] * 2;
        mergedAt.add(packed.length);
        packed.add(value);
        points += value;
        k++;
      } else {
        packed.add(tiles[k]);
      }
    }

    for (var k = 0; k < size; k++) {
      final (r, c) = cells[k];
      final value = k < packed.length ? packed[k] : 0;
      if (result[r][c] != value) moved = true;
      result[r][c] = value;
    }
    for (final k in mergedAt) {
      merged.add(cells[k]);
    }
  }

  return SlideResult(board: result, points: points, moved: moved, merged: merged);
}

bool canMove(List<List<int>> board) {
  final size = board.length;
  for (var r = 0; r < size; r++) {
    for (var c = 0; c < size; c++) {
      final value = board[r][c];
      if (value == 0) return true;
      if (c + 1 < size && board[r][c + 1] == value) return true;
      if (r + 1 < size && board[r + 1][c] == value) return true;
    }
  }
  return false;
}

/// Converte a velocidade de um swipe numa direção, ou `null` se for lento demais.
Direction? directionFromVelocity(Offset velocity) {
  if (velocity.distance < 100) return null;
  if (velocity.dx.abs() > velocity.dy.abs()) {
    return velocity.dx > 0 ? Direction.right : Direction.left;
  }
  return velocity.dy > 0 ? Direction.down : Direction.up;
}

/// Direção pela distância total arrastada, ou `null` se for curta demais.
/// Cobre o arrasto lento, em que o dedo para antes de soltar.
Direction? directionFromDistance(Offset distance) {
  if (distance.distance < 24) return null;
  if (distance.dx.abs() > distance.dy.abs()) {
    return distance.dx > 0 ? Direction.right : Direction.left;
  }
  return distance.dy > 0 ? Direction.down : Direction.up;
}
