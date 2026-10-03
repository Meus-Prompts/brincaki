// lib/games/cacapalavras/services/selection.dart

import 'dart:math';

/// Células da reta que sai de [start] em direção a [end], ajustada para a mais
/// próxima das 8 direções e cortada na borda da grade.
List<(int, int)> snapLine((int, int) start, (int, int) end, int size) {
  final dr = end.$1 - start.$1;
  final dc = end.$2 - start.$2;
  if (dr == 0 && dc == 0) return [start];

  final octant = (atan2(dr, dc) / (pi / 4)).round();
  final stepRow = sin(octant * pi / 4).round();
  final stepCol = cos(octant * pi / 4).round();
  final length = max(dr.abs(), dc.abs());

  final cells = <(int, int)>[];
  for (var k = 0; k <= length; k++) {
    final r = start.$1 + stepRow * k;
    final c = start.$2 + stepCol * k;
    if (r < 0 || r >= size || c < 0 || c >= size) break;
    cells.add((r, c));
  }
  return cells;
}
