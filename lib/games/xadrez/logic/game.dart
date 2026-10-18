// lib/games/xadrez/logic/game.dart

import '../models/game_state.dart';
import 'position.dart';

/// Partida imutável: guarda a posição e o histórico de repetições.
/// `play` devolve uma nova partida.
class ChessGame {
  ChessGame._(
    this.position,
    this._counts,
    this._recent,
    this.lastMove,
    this.end,
  ) : legalMoves = end == null ? position.legalMoves() : const [];

  factory ChessGame.start([ChessPosition? from]) {
    final p = from ?? ChessPosition.initial();
    final key = p.repetitionKey;
    return ChessGame._(
      p,
      {key: 1},
      List.unmodifiable([key]),
      null,
      _endOf(p, 1),
    );
  }

  final ChessPosition position;
  final Map<String, int> _counts;
  final List<String> _recent;
  final ChessMove? lastMove;
  final XadrezEnd? end;
  final List<ChessMove> legalMoves;

  /// Chaves de repetição desde a última captura ou lance de peão, da mais
  /// antiga até a posição atual. Só essas posições ainda podem se repetir.
  List<String> get recentKeys => _recent;

  /// Só o mate dá vitória: vence quem fez o último lance.
  ChessSide? get winner =>
      end == XadrezEnd.checkmate ? position.turn.opponent : null;

  ChessGame play(ChessMove m) {
    if (end != null) throw StateError('A partida já terminou');
    final i = legalMoves.indexOf(m);
    if (i < 0) throw StateError('Lance ilegal: $m');
    // Usa o lance da lista, que traz a captura e o tipo do lance.
    final move = legalMoves[i];
    final next = position.play(move);
    final counts = Map<String, int>.of(_counts);
    final key = next.repetitionKey;
    final seen = (counts[key] ?? 0) + 1;
    counts[key] = seen;
    final recent = List<String>.unmodifiable(
      next.halfmoveClock == 0 ? [key] : [..._recent, key],
    );
    return ChessGame._(next, counts, recent, move, _endOf(next, seen));
  }
}

XadrezEnd? _endOf(ChessPosition p, int seen) {
  if (p.legalMoves().isEmpty) {
    return p.inCheck ? XadrezEnd.checkmate : XadrezEnd.stalemate;
  }
  if (p.insufficientMaterial) return XadrezEnd.insufficientMaterial;
  if (p.halfmoveClock >= 100) return XadrezEnd.fiftyMoves;
  if (seen >= 3) return XadrezEnd.repetition;
  return null;
}
