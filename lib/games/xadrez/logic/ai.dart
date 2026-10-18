// lib/games/xadrez/logic/ai.dart

import 'dart:math';

import '../models/game_state.dart';
import 'position.dart';

enum AiLevel { easy, medium, hard }

// Valor das peças pelo tipo (índice 1 peão ... 6 rei).
const _values = [0, 100, 320, 330, 500, 900, 20000];
const _mateScore = 1000000;
// Não usar shift (1 << 40): no JavaScript ele dá 0 e quebra a busca na web.
const _infinity = 1000000000;
const _hardMaxDepth = 4;
// Quantos meios-lances a busca de quietude segue depois da profundidade.
const _maxQuiescence = 6;
// Abaixo deste material (sem peões nem reis, somando os dois lados) o rei
// usa a tabela do final.
const _endgameMaterial = 2600;

/// Lance escolhido pelo computador (quem joga em [p]) no nível pedido.
/// Só promove para dama. No difícil, a busca para quando passa do [budget] e
/// fica com o melhor lance da última profundidade completa.
/// Não chame numa posição sem lances (partida terminada).
ChessMove chooseMove(
  ChessPosition p,
  AiLevel level,
  Random random, {
  Duration budget = const Duration(milliseconds: 1200),
}) {
  final moves = _candidates(p);
  assert(moves.isNotEmpty, 'chooseMove numa posição sem lances');
  if (moves.length == 1) return moves.single;
  return switch (level) {
    AiLevel.easy => _easy(p, moves, random),
    AiLevel.medium => _medium(p, moves, random),
    AiLevel.hard => _hard(p, moves, random, budget),
  };
}

/// Para `compute`: (FEN, índice do nível, semente). Devolve o índice do lance
/// em `ChessPosition.fromFen(fen).legalMoves()`, que tem a mesma ordem da
/// posição original.
int chooseMoveInIsolate((String, int, int) args) {
  final (fen, level, seed) = args;
  final p = ChessPosition.fromFen(fen);
  final move = chooseMove(p, AiLevel.values[level], Random(seed));
  return p.legalMoves().indexOf(move);
}

/// Lances legais sem as promoções para torre, bispo e cavalo.
List<ChessMove> _candidates(ChessPosition p) => [
  for (final m in p.legalMoves())
    if (m.promotion == 0 || m.promotion == kQueen) m,
];

ChessMove _pick(List<ChessMove> options, Random random) =>
    options[random.nextInt(options.length)];

bool _isMate(ChessPosition p) => p.legalMoves().isEmpty && p.inCheck;

/// MVV-LVA: a vítima mais valiosa primeiro, comida pela peça mais barata.
/// Promoção conta como ganhar a dama.
int _orderScore(ChessPosition p, ChessMove m) {
  var score = 0;
  if (m.captured != 0) {
    score += 10 * _values[m.captured] - _values[p.cells[m.from].abs()] ~/ 10;
  }
  if (m.promotion != 0) score += 10 * _values[kQueen];
  return score;
}

ChessMove _easy(ChessPosition p, List<ChessMove> moves, Random random) {
  final mates = [
    for (final m in moves)
      if (_isMate(p.play(m))) m,
  ];
  if (mates.isNotEmpty) return _pick(mates, random);
  final captures = [
    for (final m in moves)
      if (m.captured != 0) m,
  ];
  if (captures.isNotEmpty && random.nextBool()) {
    final best = captures.map((m) => _orderScore(p, m)).reduce(max);
    return _pick([
      for (final m in captures)
        if (_orderScore(p, m) == best) m,
    ], random);
  }
  return _pick(moves, random);
}

/// Material do ponto de vista de [side].
int _material(ChessPosition p, ChessSide side) {
  var score = 0;
  for (final v in p.cells) {
    if (v == 0) continue;
    final value = _values[v.abs()];
    score += (v > 0) == (side == ChessSide.white) ? value : -value;
  }
  return score;
}

ChessMove _medium(ChessPosition p, List<ChessMove> moves, Random random) {
  var best = -_infinity;
  final bestMoves = <ChessMove>[];
  for (final m in moves) {
    final next = p.play(m);
    final replies = _candidates(next);
    int score;
    if (replies.isEmpty) {
      score = next.inCheck ? _mateScore : 0;
    } else {
      score = _infinity;
      for (final r in replies) {
        score = min(score, _material(next.play(r), p.turn));
      }
      // Um pouco de sorte entre lances próximos.
      score += random.nextInt(21) - 10;
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
  int negamax(ChessPosition p, int depth, int ply, int alpha, int beta) {
    if (depth <= 0) return quiesce(p, 0, ply, alpha, beta);
    tick();
    final moves = _candidates(p);
    // Levar mate mais tarde é menos ruim; dar mate mais cedo é melhor.
    if (moves.isEmpty) return p.inCheck ? -(_mateScore - ply) : 0;
    _sort(p, moves);
    var best = -_infinity;
    for (final m in moves) {
      final score = -negamax(p.play(m), depth - 1, ply + 1, -beta, -alpha);
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }

  /// Segue só as capturas (ou todas as saídas do xeque) até a posição ficar
  /// calma, com no máximo [_maxQuiescence] meios-lances.
  int quiesce(ChessPosition p, int qply, int ply, int alpha, int beta) {
    tick();
    final all = _candidates(p);
    final check = p.inCheck;
    if (all.isEmpty) return check ? -(_mateScore - ply) : 0;
    final standPat = _evaluate(p);
    if (qply >= _maxQuiescence) return standPat;
    var best = -_infinity;
    if (!check) {
      best = standPat;
      if (best > alpha) alpha = best;
      if (alpha >= beta) return best;
    }
    final moves = check
        ? all
        : [
            for (final m in all)
              if (m.captured != 0 || m.promotion != 0) m,
          ];
    _sort(p, moves);
    for (final m in moves) {
      final score = -quiesce(p.play(m), qply + 1, ply + 1, -beta, -alpha);
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }
}

void _sort(ChessPosition p, List<ChessMove> moves) {
  final scores = {for (final m in moves) m: _orderScore(p, m)};
  moves.sort((a, b) => scores[b]!.compareTo(scores[a]!));
}

ChessMove _hard(
  ChessPosition p,
  List<ChessMove> moves,
  Random random,
  Duration budget,
) {
  final search = _Search(budget.inMicroseconds);
  var order = List.of(moves);
  _sort(p, order);
  var result = order.first;
  for (var depth = 1; depth <= _hardMaxDepth; depth++) {
    try {
      final scored = <(ChessMove, int)>[];
      var best = -_infinity;
      for (final m in order) {
        // Janela a partir de best - 1 para reconhecer lances empatados.
        final score = -search.negamax(
          p.play(m),
          depth - 1,
          1,
          -_infinity,
          -(best - 1),
        );
        scored.add((m, score));
        if (score > best) best = score;
      }
      result = _pick([
        for (final (m, s) in scored)
          if (s == best) m,
      ], random);
      // Melhor lance primeiro na próxima profundidade, para cortar mais.
      scored.sort((a, b) => b.$2.compareTo(a.$2));
      order = [for (final (m, _) in scored) m];
      if (best >= _mateScore - 100) break;
    } on _Timeout {
      break;
    }
    search.canAbort = true;
    if (search.watch.elapsedMicroseconds > search.budgetMicros) break;
  }
  return result;
}

// Tabelas de posição do ponto de vista das brancas, índice 0 = a8.
// As pretas usam a casa espelhada (índice ^ 56).
const _pawnTable = [
  0, 0, 0, 0, 0, 0, 0, 0, //
  50, 50, 50, 50, 50, 50, 50, 50,
  10, 10, 20, 30, 30, 20, 10, 10,
  5, 5, 10, 25, 25, 10, 5, 5,
  0, 0, 0, 20, 20, 0, 0, 0,
  5, -5, -10, 0, 0, -10, -5, 5,
  5, 10, 10, -20, -20, 10, 10, 5,
  0, 0, 0, 0, 0, 0, 0, 0,
];
const _knightTable = [
  -50, -40, -30, -30, -30, -30, -40, -50, //
  -40, -20, 0, 0, 0, 0, -20, -40,
  -30, 0, 10, 15, 15, 10, 0, -30,
  -30, 5, 15, 20, 20, 15, 5, -30,
  -30, 0, 15, 20, 20, 15, 0, -30,
  -30, 5, 10, 15, 15, 10, 5, -30,
  -40, -20, 0, 5, 5, 0, -20, -40,
  -50, -40, -30, -30, -30, -30, -40, -50,
];
const _bishopTable = [
  -20, -10, -10, -10, -10, -10, -10, -20, //
  -10, 0, 0, 0, 0, 0, 0, -10,
  -10, 0, 5, 10, 10, 5, 0, -10,
  -10, 5, 5, 10, 10, 5, 5, -10,
  -10, 0, 10, 10, 10, 10, 0, -10,
  -10, 10, 10, 10, 10, 10, 10, -10,
  -10, 5, 0, 0, 0, 0, 5, -10,
  -20, -10, -10, -10, -10, -10, -10, -20,
];
const _rookTable = [
  0, 0, 0, 0, 0, 0, 0, 0, //
  5, 10, 10, 10, 10, 10, 10, 5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  0, 0, 0, 5, 5, 0, 0, 0,
];
const _queenTable = [
  -20, -10, -10, -5, -5, -10, -10, -20, //
  -10, 0, 0, 0, 0, 0, 0, -10,
  -10, 0, 5, 5, 5, 5, 0, -10,
  -5, 0, 5, 5, 5, 5, 0, -5,
  0, 0, 5, 5, 5, 5, 0, -5,
  -10, 5, 5, 5, 5, 5, 0, -10,
  -10, 0, 5, 0, 0, 0, 0, -10,
  -20, -10, -10, -5, -5, -10, -10, -20,
];
const _kingTable = [
  -30, -40, -40, -50, -50, -40, -40, -30, //
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -20, -30, -30, -40, -40, -30, -30, -20,
  -10, -20, -20, -20, -20, -20, -20, -10,
  20, 20, 0, 0, 0, 0, 20, 20,
  20, 30, 10, 0, 0, 10, 30, 20,
];
const _kingEndTable = [
  -50, -40, -30, -20, -20, -30, -40, -50, //
  -30, -20, -10, 0, 0, -10, -20, -30,
  -30, -10, 20, 30, 30, 20, -10, -30,
  -30, -10, 30, 40, 40, 30, -10, -30,
  -30, -10, 30, 40, 40, 30, -10, -30,
  -30, -10, 20, 30, 30, 20, -10, -30,
  -30, -30, 0, 0, 0, 0, -30, -30,
  -50, -30, -30, -30, -30, -30, -30, -50,
];
const _tables = [
  <int>[],
  _pawnTable,
  _knightTable,
  _bishopTable,
  _rookTable,
  _queenTable,
];

/// Avaliação do ponto de vista de quem joga em [p]: material e tabelas de
/// posição; no final, o rei vai para o centro.
int _evaluate(ChessPosition p) {
  final cells = p.cells;
  var white = 0;
  var pieces = 0;
  for (var i = 0; i < 64; i++) {
    final v = cells[i];
    if (v == 0) continue;
    final type = v.abs();
    if (type != kPawn && type != kKing) pieces += _values[type];
    if (type == kKing) continue;
    final score = _values[type] + _tables[type][v > 0 ? i : i ^ 56];
    white += v > 0 ? score : -score;
  }
  final kingTable = pieces <= _endgameMaterial ? _kingEndTable : _kingTable;
  for (var i = 0; i < 64; i++) {
    final v = cells[i];
    if (v == kKing) white += kingTable[i];
    if (v == -kKing) white -= kingTable[i ^ 56];
  }
  return p.turn == ChessSide.white ? white : -white;
}
