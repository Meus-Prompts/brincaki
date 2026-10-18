// lib/games/damas/logic/board.dart

import '../models/game_state.dart';

// Casas: 0 vazia, 1 pedra branca, 2 dama branca, -1 pedra preta, -2 dama preta.
// Índice = linha * 8 + coluna, linha 0 em cima (fileira de trás das pretas).

const _diagonals = [(-1, -1), (-1, 1), (1, -1), (1, 1)];

bool isMan(int v) => v == 1 || v == -1;

bool isKing(int v) => v == 2 || v == -2;

DamasSide? sideOf(int v) =>
    v > 0 ? DamasSide.white : (v < 0 ? DamasSide.black : null);

class DamasMove {
  const DamasMove(this.path, this.captured);

  /// Casas por onde a peça passa: origem, cada pouso e o destino final.
  final List<int> path;

  /// Peças capturadas, na ordem dos saltos.
  final List<int> captured;

  int get from => path.first;
  int get to => path.last;
  bool get isCapture => captured.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (other is! DamasMove || other.path.length != path.length) return false;
    for (var i = 0; i < path.length; i++) {
      if (other.path[i] != path[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(path);

  @override
  String toString() => 'DamasMove($path, $captured)';
}

class DamasPosition {
  DamasPosition(List<int> cells, this.turn) : cells = List.unmodifiable(cells);

  factory DamasPosition.initial() {
    final cells = List.filled(64, 0);
    for (var i = 0; i < 64; i++) {
      final r = i ~/ 8, c = i % 8;
      if ((r + c).isEven) continue;
      if (r < 3) cells[i] = -1;
      if (r > 4) cells[i] = 1;
    }
    return DamasPosition(List.unmodifiable(cells), DamasSide.white);
  }

  final List<int> cells;
  final DamasSide turn;

  /// Identifica a posição (peças + vez) para contar repetições.
  String get key => '${cells.join(',')}|${turn.name}';
}

bool _inside(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

bool _isEnemy(int v, int piece) => v != 0 && (v > 0) != (piece > 0);

/// Lances legais: se houver captura, só as que comem mais peças (lei da
/// maioria); senão, os lances simples.
List<DamasMove> legalMoves(DamasPosition p) {
  final captures = <DamasMove>[];
  for (var i = 0; i < 64; i++) {
    final piece = p.cells[i];
    if (sideOf(piece) != p.turn) continue;
    // A peça sai da origem; as capturadas ficam no tabuleiro até o fim.
    final work = List<int>.of(p.cells)..[i] = 0;
    _captures(work, i, piece, [i], [], captures);
  }
  if (captures.isNotEmpty) {
    var best = 0;
    for (final m in captures) {
      if (m.captured.length > best) best = m.captured.length;
    }
    return [
      for (final m in captures)
        if (m.captured.length == best) m,
    ];
  }
  final moves = <DamasMove>[];
  for (var i = 0; i < 64; i++) {
    final piece = p.cells[i];
    if (sideOf(piece) != p.turn) continue;
    final r = i ~/ 8, c = i % 8;
    for (final (dr, dc) in _diagonals) {
      if (isMan(piece)) {
        final forward = piece > 0 ? -1 : 1;
        if (dr != forward) continue;
        final nr = r + dr, nc = c + dc;
        if (_inside(nr, nc) && p.cells[nr * 8 + nc] == 0) {
          moves.add(DamasMove([i, nr * 8 + nc], const []));
        }
      } else {
        var nr = r + dr, nc = c + dc;
        while (_inside(nr, nc) && p.cells[nr * 8 + nc] == 0) {
          moves.add(DamasMove([i, nr * 8 + nc], const []));
          nr += dr;
          nc += dc;
        }
      }
    }
  }
  return moves;
}

/// Busca em profundidade das sequências de captura a partir de [at].
/// [piece] não muda no meio do lance: a pedra só vira dama no fim.
void _captures(
  List<int> cells,
  int at,
  int piece,
  List<int> path,
  List<int> captured,
  List<DamasMove> out,
) {
  var extended = false;
  final r = at ~/ 8, c = at % 8;

  void jump(int target, int landing) {
    extended = true;
    path.add(landing);
    captured.add(target);
    _captures(cells, landing, piece, path, captured, out);
    path.removeLast();
    captured.removeLast();
  }

  for (final (dr, dc) in _diagonals) {
    var tr = r + dr, tc = c + dc;
    if (isKing(piece)) {
      while (_inside(tr, tc) && cells[tr * 8 + tc] == 0) {
        tr += dr;
        tc += dc;
      }
    }
    if (!_inside(tr, tc)) continue;
    final target = tr * 8 + tc;
    if (!_isEnemy(cells[target], piece) || captured.contains(target)) continue;
    var lr = tr + dr, lc = tc + dc;
    while (_inside(lr, lc) && cells[lr * 8 + lc] == 0) {
      jump(target, lr * 8 + lc);
      if (isMan(piece)) break;
      lr += dr;
      lc += dc;
    }
  }

  if (!extended && captured.isNotEmpty) {
    out.add(DamasMove(List.unmodifiable(path), List.unmodifiable(captured)));
  }
}

/// Aplica o lance: tira as capturadas, promove a pedra que termina na última
/// fileira e passa a vez.
DamasPosition applyMove(DamasPosition p, DamasMove m) {
  final cells = List<int>.of(p.cells);
  var piece = cells[m.from];
  cells[m.from] = 0;
  for (final i in m.captured) {
    cells[i] = 0;
  }
  final row = m.to ~/ 8;
  if (piece == 1 && row == 0) piece = 2;
  if (piece == -1 && row == 7) piece = -2;
  cells[m.to] = piece;
  return DamasPosition(List.unmodifiable(cells), p.turn.opponent);
}
