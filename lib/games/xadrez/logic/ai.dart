// lib/games/xadrez/logic/ai.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import 'position.dart';

enum AiLevel { easy, medium, hard }

/// Tempo de busca do difícil no celular e no computador.
const kNativeHardBudget = Duration(milliseconds: 1200);

/// Na web o `compute` não abre outra thread: a busca roda junto com a tela,
/// que fica parada enquanto o computador pensa. Por isso ele pensa menos.
const kWebHardBudget = Duration(milliseconds: 400);

/// Tempo de busca do difícil nesta plataforma.
const kHardBudget = kIsWeb ? kWebHardBudget : kNativeHardBudget;

// Valor das peças pelo tipo (índice 1 peão ... 6 rei).
const _values = [0, 100, 320, 330, 500, 900, 20000];
const _mateScore = 1000000;
// Não usar shift (1 << 40): no JavaScript ele dá 0 e quebra a busca na web.
const _infinity = 1000000000;
const _hardMaxDepth = 4;
// No final, com poucas peças, a busca é barata e vai mais fundo, senão não
// enxerga o mate (dama e rei contra rei precisam de uns 3 lances).
const _hardEndgameMaxDepth = 6;
// Quantos meios-lances a busca de quietude segue depois da profundidade.
const _maxQuiescence = 6;
// Abaixo deste material (sem peões nem reis, somando os dois lados) o rei
// usa a tabela do final.
const _endgameMaterial = 2600;
// Vantagem de material a partir da qual o final vira "dar mate".
const _mopUpAdvantage = 400;

/// Lance escolhido pelo computador (quem joga em [p]) no nível pedido.
/// Só promove para dama. No difícil, a busca para quando passa do [budget] e
/// fica com o melhor lance da última profundidade completa.
/// [history] são as chaves de repetição das posições da partida que ainda
/// podem se repetir (`ChessGame.recentKeys`); no difícil, voltar a uma delas
/// conta como empate.
/// Não chame numa posição sem lances (partida terminada).
ChessMove chooseMove(
  ChessPosition p,
  AiLevel level,
  Random random, {
  Duration budget = kHardBudget,
  List<String> history = const [],
}) {
  final moves = _candidates(p);
  assert(moves.isNotEmpty, 'chooseMove numa posição sem lances');
  if (moves.length == 1) return moves.single;
  return switch (level) {
    AiLevel.easy => _easy(p, moves, random),
    AiLevel.medium => _medium(p, moves, random),
    AiLevel.hard => _hard(p, moves, random, budget, history),
  };
}

/// Para `compute`: (FEN, índice do nível, semente, chaves de repetição da
/// partida, veja [chooseMove]). Devolve o índice do lance
/// em `ChessPosition.fromFen(fen).legalMoves()`, que tem a mesma ordem da
/// posição original.
int chooseMoveInIsolate((String, int, int, List<String>) args) {
  final (fen, level, seed, history) = args;
  final p = ChessPosition.fromFen(fen);
  final move = chooseMove(
    p,
    AiLevel.values[level],
    Random(seed),
    history: history,
  );
  final index = p.legalMoves().indexOf(move);
  assert(index >= 0, 'chooseMove devolveu um lance fora da lista');
  return index;
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

  /// Chaves de repetição da partida (as que ainda podem se repetir) e das
  /// posições do caminho atual da busca.
  final path = <String>[];

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
    // Voltar a uma posição da partida ou do caminho conta como empate, para
    // quem está ganhando não ficar repetindo lances. Só depois de 4
    // meios-lances sem peão nem captura uma posição pode se repetir.
    final key = p.repetitionKey;
    if (p.halfmoveClock >= 4 && path.contains(key)) return 0;
    path.add(key);
    try {
      _sort(p, moves);
      var best = -_infinity;
      for (final m in moves) {
        final score = -negamax(p.play(m), depth - 1, ply + 1, -beta, -alpha);
        if (score > best) best = score;
        if (best > alpha) alpha = best;
        if (alpha >= beta) break;
      }
      return best;
    } finally {
      path.removeLast();
    }
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

/// Entre lances empatados na busca, fica com os que já melhoram a posição
/// agora. Sem isso, num final ganho todos os caminhos dão a mesma nota e o rei
/// fica andando para lá e para cá em vez de avançar.
ChessMove _pickProgress(ChessPosition p, List<ChessMove> tied, Random random) {
  if (tied.length == 1) return tied.single;
  var best = -_infinity;
  final bestMoves = <ChessMove>[];
  for (final m in tied) {
    final score = -_evaluate(p.play(m));
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

ChessMove _hard(
  ChessPosition p,
  List<ChessMove> moves,
  Random random,
  Duration budget,
  List<String> history,
) {
  final rootKey = p.repetitionKey;
  final search = _Search(budget.inMicroseconds)..path.addAll(history);
  if (history.isEmpty || history.last != rootKey) search.path.add(rootKey);
  var order = List.of(moves);
  _sort(p, order);
  var result = order.first;
  final maxDepth = _isEndgame(p) ? _hardEndgameMaxDepth : _hardMaxDepth;
  for (var depth = 1; depth <= maxDepth; depth++) {
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
      result = _pickProgress(p, [
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
  // Material sem os reis de cada lado.
  var whiteMaterial = 0;
  var blackMaterial = 0;
  for (var i = 0; i < 64; i++) {
    final v = cells[i];
    if (v == 0) continue;
    final type = v.abs();
    if (type != kPawn && type != kKing) pieces += _values[type];
    if (type == kKing) continue;
    if (v > 0) {
      whiteMaterial += _values[type];
    } else {
      blackMaterial += _values[type];
    }
    final score = _values[type] + _tables[type][v > 0 ? i : i ^ 56];
    white += v > 0 ? score : -score;
  }
  final endgame = pieces <= _endgameMaterial;
  final kingTable = endgame ? _kingEndTable : _kingTable;
  final advantage = whiteMaterial - blackMaterial;
  final mopUp = endgame && advantage.abs() >= _mopUpAdvantage;
  for (var i = 0; i < 64; i++) {
    final v = cells[i];
    // Dando mate, o rei de quem ganha não precisa do centro: ele vai atrás
    // do outro rei (veja _mopUp).
    if (v == kKing && !(mopUp && advantage > 0)) white += kingTable[i];
    if (v == -kKing && !(mopUp && advantage < 0)) {
      white -= kingTable[i ^ 56];
    }
  }
  if (mopUp) white += _mopUp(cells, advantage);
  return p.turn == ChessSide.white ? white : -white;
}

/// Final: material sem peões nem reis, somando os dois lados, até
/// [_endgameMaterial].
bool _isEndgame(ChessPosition p) {
  var pieces = 0;
  for (final v in p.cells) {
    final type = v.abs();
    if (type != 0 && type != kPawn && type != kKing) pieces += _values[type];
  }
  return pieces <= _endgameMaterial;
}

/// No final com uma torre ou mais de vantagem, quem ganha quer o rei
/// adversário na borda e os dois reis perto, para conseguir dar mate.
/// Pontuação do ponto de vista das brancas.
int _mopUp(List<int> cells, int advantage) {
  final whiteKing = cells.indexOf(kKing);
  final blackKing = cells.indexOf(-kKing);
  if (whiteKing < 0 || blackKing < 0) return 0;
  final loser = advantage > 0 ? blackKing : whiteKing;
  final lr = loser ~/ 8, lc = loser % 8;
  // Distância do rei que perde até o centro (0 a 6).
  final int fromCentre = max(3 - lr, lr - 4) + max(3 - lc, lc - 4);
  final int kingsApart =
      (whiteKing ~/ 8 - blackKing ~/ 8).abs() +
      (whiteKing % 8 - blackKing % 8).abs();
  final int bonus = 10 * fromCentre + 4 * (14 - kingsApart);
  return advantage > 0 ? bonus : -bonus;
}
