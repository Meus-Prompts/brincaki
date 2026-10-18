// lib/games/xadrez/logic/position.dart

import 'dart:typed_data';

import '../models/game_state.dart';

// Casas: 0 vazia; 1 peão, 2 cavalo, 3 bispo, 4 torre, 5 dama, 6 rei;
// positivo para as brancas, negativo para as pretas.
// Índice = linha * 8 + coluna, linha 0 = oitava fileira, coluna 0 = "a".
// Roque: 1 = K (brancas, lado do rei), 2 = Q, 4 = k (pretas), 8 = q.

const _files = 'abcdefgh';
const _fenPieces = '.pnbrqk';

/// Índice da casa pelo nome, por exemplo `'e4'` → 36.
int squareOf(String name) {
  final c = _files.indexOf(name[0]);
  final rank = int.parse(name[1]);
  return (8 - rank) * 8 + c;
}

/// Nome da casa pelo índice, por exemplo 36 → `'e4'`.
String nameOf(int square) => '${_files[square % 8]}${8 - square ~/ 8}';

const _knightSteps = [
  (-2, -1), (-2, 1), (-1, -2), (-1, 2), (1, -2), (1, 2), (2, -1), (2, 1), //
];
const _kingSteps = [
  (-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1), //
];
const _rookDirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];
const _bishopDirs = [(-1, -1), (-1, 1), (1, -1), (1, 1)];

List<List<int>> _stepTable(List<(int, int)> steps) => [
  for (var s = 0; s < 64; s++)
    [
      for (final (dr, dc) in steps)
        if (s ~/ 8 + dr >= 0 &&
            s ~/ 8 + dr < 8 &&
            s % 8 + dc >= 0 &&
            s % 8 + dc < 8)
          (s ~/ 8 + dr) * 8 + s % 8 + dc,
    ],
];

/// Raios por casa e direção: as casas na ordem, a partir da vizinha.
List<List<List<int>>> _rayTable(List<(int, int)> dirs) => [
  for (var s = 0; s < 64; s++)
    [
      for (final (dr, dc) in dirs)
        [
          for (
            var r = s ~/ 8 + dr, c = s % 8 + dc;
            r >= 0 && r < 8 && c >= 0 && c < 8;
            r += dr, c += dc
          )
            r * 8 + c,
        ],
    ],
];

final _knightTargets = _stepTable(_knightSteps);
final _kingTargets = _stepTable(_kingSteps);
final _rookRays = _rayTable(_rookDirs);
final _bishopRays = _rayTable(_bishopDirs);

// Casas cujo movimento (origem ou destino) tira direitos de roque.
final _castleMask = () {
  final m = List.filled(64, 15);
  m[63] = 15 & ~1; // h1
  m[56] = 15 & ~2; // a1
  m[60] = 15 & ~3; // e1
  m[7] = 15 & ~4; // h8
  m[0] = 15 & ~8; // a8
  m[4] = 15 & ~12; // e8
  return m;
}();

/// Tabuleiro de rascunho para testar a legalidade sem alocar.
final _scratch = Int8List(64);

/// Diz se [square] é atacada pelo lado [by] (true = brancas) em [b].
bool _attacked(List<int> b, int square, bool byWhite) {
  final sign = byWhite ? 1 : -1;
  final r = square ~/ 8, c = square % 8;
  // Peões brancos atacam para cima (linha menor), então ficam embaixo.
  final pr = byWhite ? r + 1 : r - 1;
  if (pr >= 0 && pr < 8) {
    if (c > 0 && b[pr * 8 + c - 1] == sign * kPawn) return true;
    if (c < 7 && b[pr * 8 + c + 1] == sign * kPawn) return true;
  }
  for (final t in _knightTargets[square]) {
    if (b[t] == sign * kKnight) return true;
  }
  for (final t in _kingTargets[square]) {
    if (b[t] == sign * kKing) return true;
  }
  for (final ray in _rookRays[square]) {
    for (final t in ray) {
      final v = b[t];
      if (v == 0) continue;
      if (v == sign * kRook || v == sign * kQueen) return true;
      break;
    }
  }
  for (final ray in _bishopRays[square]) {
    for (final t in ray) {
      final v = b[t];
      if (v == 0) continue;
      if (v == sign * kBishop || v == sign * kQueen) return true;
      break;
    }
  }
  return false;
}

class ChessMove {
  const ChessMove(
    this.from,
    this.to, {
    this.promotion = 0,
    this.isCastle = false,
    this.isEnPassant = false,
    this.captured = 0,
  });

  final int from;
  final int to;

  /// Peça da promoção (5 dama, 4 torre, 3 bispo, 2 cavalo) ou 0.
  final int promotion;
  final bool isCastle;
  final bool isEnPassant;

  /// Tipo da peça capturada (sem sinal) ou 0.
  final int captured;

  String get uci =>
      '${nameOf(from)}${nameOf(to)}${promotion == 0 ? '' : _fenPieces[promotion]}';

  @override
  bool operator ==(Object other) =>
      other is ChessMove &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion;

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() => 'ChessMove($uci)';
}

class ChessPosition {
  ChessPosition._(
    List<int> cells,
    this.turn,
    this.castling,
    this.enPassant,
    this.halfmoveClock,
    this.fullmove,
  ) : cells = List.unmodifiable(cells);

  factory ChessPosition.initial() => ChessPosition.fromFen(
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  );

  factory ChessPosition.fromFen(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    final cells = List.filled(64, 0);
    var i = 0;
    for (final ch in parts[0].split('')) {
      if (ch == '/') continue;
      final n = int.tryParse(ch);
      if (n != null) {
        i += n;
        continue;
      }
      final type = _fenPieces.indexOf(ch.toLowerCase());
      cells[i++] = ch == ch.toUpperCase() ? type : -type;
    }
    final turn = parts[1] == 'b' ? ChessSide.black : ChessSide.white;
    var castling = 0;
    final c = parts.length > 2 ? parts[2] : '-';
    if (c.contains('K')) castling |= 1;
    if (c.contains('Q')) castling |= 2;
    if (c.contains('k')) castling |= 4;
    if (c.contains('q')) castling |= 8;
    final ep = parts.length > 3 && parts[3] != '-' ? squareOf(parts[3]) : null;
    final half = parts.length > 4 ? int.parse(parts[4]) : 0;
    final full = parts.length > 5 ? int.parse(parts[5]) : 1;
    return ChessPosition._(cells, turn, castling, ep, half, full);
  }

  final List<int> cells;
  final ChessSide turn;
  final int castling;

  /// Casa por onde o peão passou no avanço duplo do lance anterior.
  final int? enPassant;
  final int halfmoveClock;
  final int fullmove;

  List<ChessMove>? _legal;

  String _placement() {
    final sb = StringBuffer();
    for (var r = 0; r < 8; r++) {
      var empty = 0;
      for (var c = 0; c < 8; c++) {
        final v = cells[r * 8 + c];
        if (v == 0) {
          empty++;
          continue;
        }
        if (empty > 0) sb.write(empty);
        empty = 0;
        final ch = _fenPieces[v.abs()];
        sb.write(v > 0 ? ch.toUpperCase() : ch);
      }
      if (empty > 0) sb.write(empty);
      if (r < 7) sb.write('/');
    }
    return sb.toString();
  }

  String _castlingText() {
    if (castling == 0) return '-';
    return '${castling & 1 != 0 ? 'K' : ''}${castling & 2 != 0 ? 'Q' : ''}'
        '${castling & 4 != 0 ? 'k' : ''}${castling & 8 != 0 ? 'q' : ''}';
  }

  String get _turnText => turn == ChessSide.white ? 'w' : 'b';

  String toFen() =>
      '${_placement()} $_turnText ${_castlingText()} '
      '${enPassant == null ? '-' : nameOf(enPassant!)} '
      '$halfmoveClock $fullmove';

  /// Posição, vez, roque e en passant só se a captura for possível.
  String get repetitionKey {
    final ep = enPassant != null && legalMoves().any((m) => m.isEnPassant)
        ? nameOf(enPassant!)
        : '-';
    return '${_placement()} $_turnText ${_castlingText()} $ep';
  }

  int kingSquare(ChessSide side) {
    final king = side == ChessSide.white ? kKing : -kKing;
    return cells.indexOf(king);
  }

  bool isAttacked(int square, ChessSide by) =>
      _attacked(cells, square, by == ChessSide.white);

  bool get inCheck {
    final k = kingSquare(turn);
    return k >= 0 && isAttacked(k, turn.opponent);
  }

  bool get insufficientMaterial {
    final others = <int>[];
    for (var i = 0; i < 64; i++) {
      final v = cells[i];
      if (v == 0 || v.abs() == kKing) continue;
      if (others.length == 2) return false;
      others.add(i);
    }
    if (others.isEmpty) return true;
    final a = cells[others[0]];
    if (others.length == 1) return a.abs() == kBishop || a.abs() == kKnight;
    final b = cells[others[1]];
    if (a.abs() != kBishop || b.abs() != kBishop || a.sign == b.sign) {
      return false;
    }
    int shade(int s) => (s ~/ 8 + s % 8) % 2;
    return shade(others[0]) == shade(others[1]);
  }

  /// Lances que não deixam o próprio rei em xeque.
  List<ChessMove> legalMoves() {
    final cached = _legal;
    if (cached != null) return cached;
    final white = turn == ChessSide.white;
    final sign = white ? 1 : -1;
    final pseudo = <ChessMove>[];
    _pseudoMoves(pseudo, white, sign);
    final legal = <ChessMove>[];
    final king = sign * kKing;
    for (final m in pseudo) {
      _scratch.setAll(0, cells);
      final piece = _scratch[m.from];
      _scratch[m.from] = 0;
      _scratch[m.to] = piece;
      if (m.isEnPassant) _scratch[(m.from ~/ 8) * 8 + m.to % 8] = 0;
      final k = piece == king ? m.to : _scratch.indexOf(king);
      if (k < 0 || !_attacked(_scratch, k, !white)) legal.add(m);
    }
    return _legal = List.unmodifiable(legal);
  }

  void _pseudoMoves(List<ChessMove> out, bool white, int sign) {
    final b = cells;
    for (var s = 0; s < 64; s++) {
      final v = b[s];
      if (v == 0 || (v > 0) != white) continue;
      switch (v.abs()) {
        case kPawn:
          _pawnMoves(out, s, white, sign);
        case kKnight:
          _stepMoves(out, s, _knightTargets[s], white);
        case kBishop:
          _slideMoves(out, s, _bishopRays[s], white);
        case kRook:
          _slideMoves(out, s, _rookRays[s], white);
        case kQueen:
          _slideMoves(out, s, _bishopRays[s], white);
          _slideMoves(out, s, _rookRays[s], white);
        case kKing:
          _stepMoves(out, s, _kingTargets[s], white);
          _castleMoves(out, s, white);
      }
    }
  }

  void _addPawn(List<ChessMove> out, int from, int to, int captured) {
    final r = to ~/ 8;
    if (r == 0 || r == 7) {
      for (final p in const [kQueen, kRook, kBishop, kKnight]) {
        out.add(ChessMove(from, to, promotion: p, captured: captured));
      }
    } else {
      out.add(ChessMove(from, to, captured: captured));
    }
  }

  void _pawnMoves(List<ChessMove> out, int s, bool white, int sign) {
    final b = cells;
    final r = s ~/ 8, c = s % 8;
    final dir = white ? -8 : 8;
    final one = s + dir;
    if (b[one] == 0) {
      _addPawn(out, s, one, 0);
      final startRow = white ? 6 : 1;
      if (r == startRow && b[one + dir] == 0) {
        out.add(ChessMove(s, one + dir));
      }
    }
    for (final dc in const [-1, 1]) {
      if (c + dc < 0 || c + dc > 7) continue;
      final t = one + dc;
      final v = b[t];
      if (v != 0 && (v > 0) != white) {
        _addPawn(out, s, t, v.abs());
      } else if (v == 0 && t == enPassant) {
        out.add(ChessMove(s, t, isEnPassant: true, captured: kPawn));
      }
    }
  }

  void _stepMoves(List<ChessMove> out, int s, List<int> targets, bool white) {
    for (final t in targets) {
      final v = cells[t];
      if (v == 0) {
        out.add(ChessMove(s, t));
      } else if ((v > 0) != white) {
        out.add(ChessMove(s, t, captured: v.abs()));
      }
    }
  }

  void _slideMoves(
    List<ChessMove> out,
    int s,
    List<List<int>> rays,
    bool white,
  ) {
    for (final ray in rays) {
      for (final t in ray) {
        final v = cells[t];
        if (v == 0) {
          out.add(ChessMove(s, t));
          continue;
        }
        if ((v > 0) != white) out.add(ChessMove(s, t, captured: v.abs()));
        break;
      }
    }
  }

  void _castleMoves(List<ChessMove> out, int s, bool white) {
    final b = cells;
    final home = white ? 60 : 4;
    if (s != home) return;
    final sign = white ? 1 : -1;
    final kingSide = white ? 1 : 4;
    final queenSide = white ? 2 : 8;
    if (castling & (kingSide | queenSide) == 0) return;
    if (_attacked(b, s, !white)) return;
    // O destino do rei é conferido pelo filtro de legalidade.
    if (castling & kingSide != 0 &&
        b[s + 3] == sign * kRook &&
        b[s + 1] == 0 &&
        b[s + 2] == 0 &&
        !_attacked(b, s + 1, !white)) {
      out.add(ChessMove(s, s + 2, isCastle: true));
    }
    if (castling & queenSide != 0 &&
        b[s - 4] == sign * kRook &&
        b[s - 1] == 0 &&
        b[s - 2] == 0 &&
        b[s - 3] == 0 &&
        !_attacked(b, s - 1, !white)) {
      out.add(ChessMove(s, s - 2, isCastle: true));
    }
  }

  /// Nova posição depois de [m]. Roque, en passant e captura são
  /// deduzidos do tabuleiro, então basta a origem, o destino e a promoção.
  ChessPosition play(ChessMove m) {
    final b = List.of(cells);
    final piece = b[m.from];
    final type = piece.abs();
    final sign = piece.sign;
    var capture = b[m.to] != 0;
    b[m.from] = 0;
    b[m.to] = m.promotion != 0 ? sign * m.promotion : piece;
    if (type == kPawn && m.to == enPassant && m.from % 8 != m.to % 8) {
      final victim = (m.from ~/ 8) * 8 + m.to % 8;
      if (b[victim] == -sign * kPawn && !capture) {
        b[victim] = 0;
        capture = true;
      }
    }
    if (type == kKing && (m.to - m.from).abs() == 2) {
      final rookFrom = m.to > m.from ? m.from + 3 : m.from - 4;
      final rookTo = m.to > m.from ? m.from + 1 : m.from - 1;
      b[rookTo] = b[rookFrom];
      b[rookFrom] = 0;
    }
    final ep = type == kPawn && (m.to - m.from).abs() == 16
        ? (m.from + m.to) ~/ 2
        : null;
    return ChessPosition._(
      b,
      turn.opponent,
      castling & _castleMask[m.from] & _castleMask[m.to],
      ep,
      type == kPawn || capture ? 0 : halfmoveClock + 1,
      turn == ChessSide.black ? fullmove + 1 : fullmove,
    );
  }
}

/// Conta as folhas da árvore de lances legais até [depth].
int perft(ChessPosition p, int depth) {
  if (depth == 0) return 1;
  final moves = p.legalMoves();
  if (depth == 1) return moves.length;
  var n = 0;
  for (final m in moves) {
    n += perft(p.play(m), depth - 1);
  }
  return n;
}
