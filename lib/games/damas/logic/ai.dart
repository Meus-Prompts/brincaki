// lib/games/damas/logic/ai.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import 'board.dart';

enum AiLevel { easy, medium, hard }

/// Tempo de busca do difícil no celular e no computador.
const kNativeHardBudget = Duration(milliseconds: 1200);

/// Na web o `compute` não abre outra thread: a busca roda junto com a tela,
/// que fica parada enquanto o computador pensa. Por isso ele pensa menos.
const kWebHardBudget = Duration(milliseconds: 400);

/// Tempo de busca do difícil nesta plataforma.
const kHardBudget = kIsWeb ? kWebHardBudget : kNativeHardBudget;

const _manValue = 100;
const _kingValue = 300;
const _winScore = 1000000;
// Não usar shift (1 << 40): no JavaScript ele dá 0 e quebra a busca na web.
const _infinity = 1000000000;
const _hardMaxDepth = 6;
// Quantos meios-lances a mais a busca segue quando só há capturas.
const _maxExtension = 6;

/// Lance escolhido pelo computador (quem joga em [p]) no nível pedido.
/// No difícil, a busca para quando passa do [budget] e fica com o melhor lance
/// da última profundidade completa.
/// Não chame numa posição sem lances (partida terminada).
DamasMove chooseMove(
  DamasPosition p,
  AiLevel level,
  Random random, {
  Duration budget = kHardBudget,
}) {
  final moves = legalMoves(p);
  assert(moves.isNotEmpty, 'chooseMove numa posição sem lances');
  if (moves.length == 1) return moves.single;
  return switch (level) {
    AiLevel.easy => _easy(moves, p, random),
    AiLevel.medium => _medium(p, moves, random),
    AiLevel.hard => _hard(p, moves, random, budget),
  };
}

/// Para `compute`: (casas, vez, índice do nível, semente). Devolve o índice do
/// lance em `legalMoves`.
int chooseMoveInIsolate((List<int>, int, int, int) args) {
  final (cells, turn, level, seed) = args;
  final p = DamasPosition(cells, DamasSide.values[turn]);
  final move = chooseMove(p, AiLevel.values[level], Random(seed));
  return legalMoves(p).indexOf(move);
}

int _pieceValue(int v) => isKing(v) ? _kingValue : _manValue;

int _capturedValue(DamasPosition p, DamasMove m) =>
    m.captured.fold(0, (sum, i) => sum + _pieceValue(p.cells[i]));

DamasMove _pick(List<DamasMove> options, Random random) =>
    options[random.nextInt(options.length)];

DamasMove _easy(List<DamasMove> moves, DamasPosition p, Random random) {
  if (moves.first.isCapture && random.nextBool()) {
    var best = 0;
    for (final m in moves) {
      best = max(best, _capturedValue(p, m));
    }
    return _pick([
      for (final m in moves)
        if (_capturedValue(p, m) == best) m,
    ], random);
  }
  return _pick(moves, random);
}

/// Tira lances que levam à mesma posição: a dama voadora pode chegar ao mesmo
/// lugar, comendo as mesmas peças, por caminhos diferentes.
List<DamasMove> _unique(List<DamasMove> moves) {
  if (moves.isEmpty || moves.first.captured.length < 2) return moves;
  final seen = <String>{};
  return [
    for (final m in moves)
      if (seen.add(
        '${m.from}>${m.to}:${(List.of(m.captured)..sort()).join(',')}',
      ))
        m,
  ];
}

/// Material do ponto de vista de [side].
int _material(DamasPosition p, DamasSide side) {
  var score = 0;
  for (final v in p.cells) {
    if (v == 0) continue;
    final value = _pieceValue(v);
    score += sideOf(v) == side ? value : -value;
  }
  return score;
}

DamasMove _medium(DamasPosition p, List<DamasMove> moves, Random random) {
  var best = -_infinity;
  final bestMoves = <DamasMove>[];
  for (final m in _unique(moves)) {
    final next = applyMove(p, m);
    final replies = _unique(legalMoves(next));
    var score = _infinity;
    if (replies.isEmpty) {
      score = _winScore;
    } else {
      for (final r in replies) {
        score = min(score, _material(applyMove(next, r), p.turn));
      }
    }
    if (score > best) {
      best = score;
      bestMoves
        ..clear()
        ..add(m);
    } else if (score == best) {
      bestMoves.add(m);
    }
  }
  return _pick(bestMoves, random);
}

class _Timeout implements Exception {}

class _Search {
  _Search(this.budgetMicros) : watch = Stopwatch()..start();

  final int budgetMicros;
  final Stopwatch watch;

  /// A profundidade 1 sempre termina, para ter um lance.
  bool canAbort = false;
  int nodes = 0;

  void tick() {
    if (canAbort &&
        (++nodes & 255) == 0 &&
        watch.elapsedMicroseconds > budgetMicros) {
      throw _Timeout();
    }
  }

  /// Pontuação do ponto de vista de quem joga em [p].
  int negamax(DamasPosition p, int depth, int ply, int alpha, int beta) {
    tick();
    final moves = _unique(legalMoves(p));
    // Sem lance (ou sem peças) é derrota; perder mais tarde é menos ruim.
    if (moves.isEmpty) return -(_winScore - ply);
    if (depth <= 0) {
      // Capturas são obrigatórias: segue até a posição ficar calma.
      if (!moves.first.isCapture || depth <= -_maxExtension) {
        return _evaluate(p);
      }
    }
    var best = -_infinity;
    for (final m in moves) {
      final score = -negamax(
        applyMove(p, m),
        depth - 1,
        ply + 1,
        -beta,
        -alpha,
      );
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }
}

DamasMove _hard(
  DamasPosition p,
  List<DamasMove> moves,
  Random random,
  Duration budget,
) {
  final search = _Search(budget.inMicroseconds);
  var order = _unique(moves);
  var result = order.first;
  for (var depth = 1; depth <= _hardMaxDepth; depth++) {
    try {
      final scored = <(DamasMove, int)>[];
      var best = -_infinity;
      for (final m in order) {
        // Janela a partir de best - 1 para reconhecer lances empatados.
        final score = -search.negamax(
          applyMove(p, m),
          depth - 1,
          1,
          -_infinity,
          -(best - 1),
        );
        scored.add((m, score));
        if (score > best) best = score;
      }
      final bestMoves = [
        for (final (m, s) in scored)
          if (s == best) m,
      ];
      result = _pick(bestMoves, random);
      // Melhor lance primeiro na próxima profundidade, para cortar mais.
      scored.sort((a, b) => b.$2.compareTo(a.$2));
      order = [for (final (m, _) in scored) m];
      if (best.abs() >= _winScore - 100) break;
    } on _Timeout {
      break;
    }
    search.canAbort = true;
    if (search.watch.elapsedMicroseconds > search.budgetMicros) break;
  }
  return result;
}

/// Avaliação do ponto de vista de quem joga em [p]: material, avanço das
/// pedras, centro e a última fileira protegida.
int _evaluate(DamasPosition p) {
  var white = 0;
  for (var i = 0; i < 64; i++) {
    final v = p.cells[i];
    if (v == 0) continue;
    final r = i ~/ 8, c = i % 8;
    var score = _pieceValue(v);
    if (isMan(v)) {
      // Linhas que a pedra já andou rumo à promoção.
      final advanced = v > 0 ? 7 - r : r;
      score += advanced * 3;
      if (advanced == 0) score += 6;
    }
    if (r >= 2 && r <= 5 && c >= 2 && c <= 5) score += 5;
    white += v > 0 ? score : -score;
  }
  return p.turn == DamasSide.white ? white : -white;
}
