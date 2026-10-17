// lib/games/tictactoe/logic/ai.dart

import 'dart:math';

import 'board.dart';

enum AiLevel { easy, medium, hard }

const _center = (1, 1);
const _corners = [(0, 0), (0, 2), (2, 0), (2, 2)];

/// Casa escolhida pelo computador (jogador [me]) no nível pedido.
///
/// Lança [StateError] se não houver casa livre ou se a partida já acabou.
(int, int) chooseMove(List<List<int>> board, int me, AiLevel level, Random random) {
  if (freeCells(board).isEmpty || winningLine(board) != null) {
    throw StateError('Não há jogada possível');
  }
  return switch (level) {
    AiLevel.easy => _easy(board, me, random),
    AiLevel.medium => _medium(board, me, random),
    AiLevel.hard => _hard(board, me, random),
  };
}

/// Casas onde [player] vence na hora.
List<(int, int)> winningMoves(List<List<int>> board, int player) => [
  for (final (r, c) in freeCells(board))
    if (hasLine(place(board, r, c, player), player)) (r, c),
];

(int, int) _pick(List<(int, int)> options, Random random) =>
    options[random.nextInt(options.length)];

(int, int) _easy(List<List<int>> board, int me, Random random) {
  final wins = winningMoves(board, me);
  if (wins.isNotEmpty && random.nextBool()) return _pick(wins, random);
  return _pick(freeCells(board), random);
}

(int, int) _medium(List<List<int>> board, int me, Random random) {
  final wins = winningMoves(board, me);
  if (wins.isNotEmpty) return _pick(wins, random);
  final blocks = winningMoves(board, 3 - me);
  if (blocks.isNotEmpty) return _pick(blocks, random);
  final free = freeCells(board);
  if (free.contains(_center)) return _center;
  final corners = [
    for (final cell in free)
      if (_corners.contains(cell)) cell,
  ];
  // Sem centro nem cantos livres, só sobram os lados.
  return _pick(corners.isNotEmpty ? corners : free, random);
}

(int, int) _hard(List<List<int>> board, int me, Random random) {
  var best = -100;
  final bestMoves = <(int, int)>[];
  for (final (r, c) in freeCells(board)) {
    final score = -_negamax(place(board, r, c, me), 3 - me);
    if (score > best) {
      best = score;
      bestMoves
        ..clear()
        ..add((r, c));
    } else if (score == best) {
      bestMoves.add((r, c));
    }
  }
  return _pick(bestMoves, random);
}

/// Pontuação do ponto de vista de [player], que joga agora: positiva se ele
/// vence, negativa se perde, 0 no empate. Vencer cedo vale mais que tarde.
int _negamax(List<List<int>> board, int player) {
  final key = _key(board, player);
  final cached = _memo[key];
  if (cached != null) return cached;
  final free = freeCells(board);
  int best;
  if (hasLine(board, 3 - player)) {
    // Quem acabou de jogar foi o adversário: se ele alinhou, perdi.
    best = -(free.length + 1);
  } else if (free.isEmpty) {
    best = 0;
  } else {
    best = -100;
    for (final (r, c) in free) {
      final score = -_negamax(place(board, r, c, player), 3 - player);
      if (score > best) best = score;
    }
  }
  _memo[key] = best;
  return best;
}

/// Há poucos milhares de posições: guardar o valor de cada uma deixa a busca
/// completa instantânea.
final _memo = <int, int>{};

int _key(List<List<int>> board, int player) {
  var key = player;
  for (final row in board) {
    for (final v in row) {
      key = key * 3 + v;
    }
  }
  return key;
}
