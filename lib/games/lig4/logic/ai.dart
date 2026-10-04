// lib/games/lig4/logic/ai.dart

import 'dart:math';

import 'board.dart';

enum AiLevel { easy, medium, hard }

const _centerOrder = [3, 2, 4, 1, 5, 0, 6];
const _centerWeights = [1, 2, 3, 4, 3, 2, 1];
const _winScore = 1000000;
const _infinity = 1 << 40;
const _hardDepth = 6;

/// Coluna escolhida pelo computador (jogador [me]) no nível pedido.
int chooseColumn(List<List<int>> board, int me, AiLevel level, Random random) {
  return switch (level) {
    AiLevel.easy => _easy(board, me, random),
    AiLevel.medium => _medium(board, me, random),
    AiLevel.hard => _hard(board, me, random),
  };
}

/// Para `compute`: (tabuleiro, jogador, índice do nível, semente).
int chooseColumnInIsolate((List<List<int>>, int, int, int) args) {
  final (board, me, level, seed) = args;
  return chooseColumn(board, me, AiLevel.values[level], Random(seed));
}

int? _winningMove(List<List<int>> board, int player) {
  for (final c in validColumns(board)) {
    if (hasLine(drop(board, c, player), player)) return c;
  }
  return null;
}

int _easy(List<List<int>> board, int me, Random random) {
  final win = _winningMove(board, me);
  if (win != null && random.nextBool()) return win;
  final valid = validColumns(board);
  return valid[random.nextInt(valid.length)];
}

int _medium(List<List<int>> board, int me, Random random) {
  final opp = 3 - me;
  final win = _winningMove(board, me);
  if (win != null) return win;
  final block = _winningMove(board, opp);
  if (block != null) return block;
  final valid = validColumns(board);
  final safe = [
    for (final c in valid)
      if (_winningMove(drop(board, c, me), opp) == null) c,
  ];
  return _weightedCenter(safe.isEmpty ? valid : safe, random);
}

int _weightedCenter(List<int> options, Random random) {
  final total = options.fold<int>(0, (sum, c) => sum + _centerWeights[c]);
  var pick = random.nextInt(total);
  for (final c in options) {
    pick -= _centerWeights[c];
    if (pick < 0) return c;
  }
  return options.last;
}

int _hard(List<List<int>> board, int me, Random random) {
  final opp = 3 - me;
  var best = -_infinity;
  final bestCols = <int>[];
  for (final c in _centerOrder) {
    if (board[0][c] != 0) continue;
    final score =
        -_negamax(drop(board, c, me), _hardDepth - 1, -_infinity, _infinity, opp);
    if (score > best) {
      best = score;
      bestCols
        ..clear()
        ..add(c);
    } else if (score == best) {
      bestCols.add(c);
    }
  }
  return bestCols[random.nextInt(bestCols.length)];
}

/// Pontuação do ponto de vista de [player], que joga agora.
int _negamax(List<List<int>> board, int depth, int alpha, int beta, int player) {
  final opp = 3 - player;
  // Quem acabou de jogar foi o adversário: se ele alinhou, perdi.
  // Perder mais tarde (menos profundidade restante) é menos ruim.
  if (hasLine(board, opp)) return -(_winScore + depth);
  if (isFull(board)) return 0;
  if (depth == 0) return _evaluate(board, player);

  var best = -_infinity;
  for (final c in _centerOrder) {
    if (board[0][c] != 0) continue;
    final score = -_negamax(drop(board, c, player), depth - 1, -beta, -alpha, opp);
    if (score > best) best = score;
    if (best > alpha) alpha = best;
    if (alpha >= beta) break;
  }
  return best;
}

int _evaluate(List<List<int>> board, int me) {
  final opp = 3 - me;
  var score = 0;
  for (var r = 0; r < kRows; r++) {
    if (board[r][3] == me) score += 6;
  }
  for (var r = 0; r < kRows; r++) {
    for (var c = 0; c < kCols; c++) {
      for (final (dr, dc) in const [(0, 1), (1, 0), (1, 1), (-1, 1)]) {
        final endR = r + dr * 3;
        final endC = c + dc * 3;
        if (endR < 0 || endR >= kRows || endC >= kCols) continue;
        var mine = 0, theirs = 0, empty = 0;
        for (var k = 0; k < 4; k++) {
          final v = board[r + dr * k][c + dc * k];
          if (v == me) {
            mine++;
          } else if (v == opp) {
            theirs++;
          } else {
            empty++;
          }
        }
        if (mine == 3 && empty == 1) score += 50;
        if (mine == 2 && empty == 2) score += 10;
        if (theirs == 3 && empty == 1) score -= 80;
        if (theirs == 2 && empty == 2) score -= 10;
      }
    }
  }
  return score;
}
