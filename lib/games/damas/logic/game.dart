// lib/games/damas/logic/game.dart

import '../models/game_state.dart';
import 'board.dart' as rules;
import 'board.dart' show DamasMove, DamasPosition, applyMove, isMan, sideOf;

/// Material (damas, pedras) de cada lado em que valem os 5 lances.
const _fiveMovesSets = {'2,0|2,0', '2,0|1,0', '2,0|1,1', '1,0|1,0', '1,1|1,0'};

/// Partida imutável: guarda a posição, o histórico de repetições e os
/// contadores de empate. `play` devolve uma nova partida.
class DamasGame {
  DamasGame._(
    this.position,
    this._counts,
    this.twentyCount,
    this._material,
    this.fiveCount,
    this.lastMove,
    this.end,
    this.winner,
  ) : legalMoves = end == null ? rules.legalMoves(position) : const [];

  factory DamasGame.start([DamasPosition? from]) {
    final p = from ?? DamasPosition.initial();
    final moves = rules.legalMoves(p);
    DamasEnd? end;
    DamasSide? winner;
    if (!p.cells.any((v) => sideOf(v) == p.turn)) {
      end = DamasEnd.noPieces;
      winner = p.turn.opponent;
    } else if (moves.isEmpty) {
      end = DamasEnd.noMoves;
      winner = p.turn.opponent;
    }
    return DamasGame._(p, {p.key: 1}, 0, _materialKey(p), 0, null, end, winner);
  }

  final DamasPosition position;
  final Map<String, int> _counts;

  /// Meios-lances seguidos sem captura e sem lance de pedra.
  final int twentyCount;
  final String _material;

  /// Meios-lances desde que o material entrou na lista dos 5 lances.
  final int fiveCount;
  final DamasMove? lastMove;
  final DamasEnd? end;
  final DamasSide? winner;
  final List<DamasMove> legalMoves;

  DamasGame play(DamasMove m) {
    if (end != null) throw StateError('A partida já terminou');
    if (!legalMoves.contains(m)) throw StateError('Lance ilegal: $m');
    // Usa o lance da lista, que traz as capturas.
    final move = legalMoves.firstWhere((x) => x == m);
    final wasMan = isMan(position.cells[move.from]);
    final next = applyMove(position, move);
    final counts = Map<String, int>.of(_counts);
    final seen = (counts[next.key] ?? 0) + 1;
    counts[next.key] = seen;

    final twenty = (move.isCapture || wasMan) ? 0 : twentyCount + 1;
    final material = _materialKey(next);
    final five = _fiveMovesSets.contains(material)
        ? (material == _material ? fiveCount + 1 : 0)
        : 0;

    DamasEnd? newEnd;
    DamasSide? newWinner;
    if (!next.cells.any((v) => sideOf(v) == next.turn)) {
      newEnd = DamasEnd.noPieces;
      newWinner = position.turn;
    } else if (rules.legalMoves(next).isEmpty) {
      newEnd = DamasEnd.noMoves;
      newWinner = position.turn;
    } else if (seen >= 3) {
      newEnd = DamasEnd.repetition;
    } else if (twenty >= 40) {
      newEnd = DamasEnd.twentyMoves;
    } else if (five >= 10) {
      newEnd = DamasEnd.fiveMoves;
    }
    return DamasGame._(
      next,
      counts,
      twenty,
      material,
      five,
      move,
      newEnd,
      newWinner,
    );
  }
}

/// "damas,pedras|damas,pedras" com o lado maior primeiro.
String _materialKey(DamasPosition p) {
  var wk = 0, wp = 0, bk = 0, bp = 0;
  for (final v in p.cells) {
    if (v == 2) wk++;
    if (v == 1) wp++;
    if (v == -2) bk++;
    if (v == -1) bp++;
  }
  final a = '$wk,$wp', b = '$bk,$bp';
  return a.compareTo(b) >= 0 ? '$a|$b' : '$b|$a';
}
