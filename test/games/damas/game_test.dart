// test/games/damas/game_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/damas/logic/board.dart';
import 'package:brincaki/games/damas/logic/game.dart';
import 'package:brincaki/games/damas/models/game_state.dart';

int sq(int r, int c) => r * 8 + c;

DamasPosition pos(Map<int, int> pieces, DamasSide turn) {
  final cells = List.filled(64, 0);
  pieces.forEach((i, v) => cells[i] = v);
  return DamasPosition(cells, turn);
}

DamasGame playTo(DamasGame g, int from, int to) =>
    g.play(g.legalMoves.firstWhere((m) => m.from == from && m.to == to));

/// Joga o primeiro lance sem captura que leva a uma posição ainda não vista.
DamasGame walk(DamasGame g, Set<String> seen) {
  for (final m
      in g.legalMoves.toList()..shuffle(Random(g.position.key.length))) {
    if (m.isCapture) continue;
    final n = g.play(m);
    if (n.winner != null || n.legalMoves.any((x) => x.isCapture)) continue;
    if (seen.add(n.position.key)) return n;
  }
  throw StateError('sem lance novo\n${g.position.cells}');
}

void main() {
  test('posição guarda cópia imutável das casas', () {
    final list = List.filled(64, 0);
    final p = DamasPosition(list, DamasSide.white);
    final key = p.key;
    list[1] = 1;
    expect(p.key, key);
    expect(() => p.cells[0] = 1, throwsUnsupportedError);
  });

  test('vence quem tira todas as peças', () {
    final g = DamasGame.start(
      pos({sq(5, 0): 1, sq(4, 1): -1}, DamasSide.white),
    );
    final after = g.play(g.legalMoves.single);
    expect(after.end, DamasEnd.noPieces);
    expect(after.winner, DamasSide.white);
    expect(after.lastMove, isNotNull);
  });

  test('vence quem deixa o adversário sem lance', () {
    // Preta na borda, bloqueada pela branca que acabou de chegar.
    // A preta da borda está bloqueada por (2,1), que tem (3,2) atrás.
    final g = DamasGame.start(
      pos({
        sq(1, 0): -1,
        sq(2, 1): 1,
        sq(3, 2): 1,
        sq(7, 4): 1,
      }, DamasSide.white),
    );
    final after = playTo(g, sq(7, 4), sq(6, 3));
    expect(after.end, DamasEnd.noMoves);
    expect(after.winner, DamasSide.white);
  });

  test('empata com a mesma posição 3 vezes', () {
    // Damas longe uma da outra, sem diagonal em comum nos vai-e-vem.
    var g = DamasGame.start(pos({sq(7, 0): 2, sq(0, 5): -2}, DamasSide.white));
    for (var i = 0; i < 2; i++) {
      g = playTo(g, sq(7, 0), sq(6, 1));
      g = playTo(g, sq(0, 5), sq(1, 4));
      g = playTo(g, sq(6, 1), sq(7, 0));
      expect(g.end, isNull);
      g = playTo(g, sq(1, 4), sq(0, 5));
    }
    expect(g.end, DamasEnd.repetition);
    expect(g.winner, isNull);
  });

  test('empata com 20 lances de cada lado só com damas', () {
    // 3 damas x 3 damas não está na lista dos 5 lances.
    var g = DamasGame.start(
      pos({
        sq(7, 0): 2,
        sq(7, 2): 2,
        sq(7, 4): 2,
        sq(0, 7): -2,
        sq(0, 5): -2,
        sq(0, 3): -2,
      }, DamasSide.white),
    );
    final seen = <String>{g.position.key};
    var half = 0;
    while (g.end == null) {
      expect(half, lessThan(40));
      g = walk(g, seen);
      half++;
    }
    expect(half, 40);
    expect(g.end, DamasEnd.twentyMoves);
    expect(g.winner, isNull);
  });

  test('lance de pedra zera a contagem dos 20 lances', () {
    var g = DamasGame.start(
      pos({
        sq(7, 0): 2,
        sq(7, 2): 2,
        sq(7, 4): 2,
        sq(5, 2): 1,
        sq(0, 1): -2,
        sq(0, 5): -2,
        sq(0, 3): -2,
      }, DamasSide.white),
    );
    expect(g.twentyCount, 0);
    g = playTo(g, sq(7, 0), sq(6, 1));
    g = playTo(g, sq(0, 1), sq(1, 0));
    expect(g.twentyCount, 2);
    g = playTo(g, sq(5, 2), sq(4, 1));
    expect(g.twentyCount, 0);
  });

  test('empata com 5 lances em 2 damas contra 1', () {
    var g = DamasGame.start(
      pos({sq(7, 0): 2, sq(7, 2): 2, sq(0, 3): -2}, DamasSide.white),
    );
    final seen = <String>{g.position.key};
    var half = 0;
    while (g.end == null) {
      expect(half, lessThan(10));
      g = walk(g, seen);
      half++;
    }
    expect(half, 10);
    expect(g.end, DamasEnd.fiveMoves);
  });

  test('play recusa lance ilegal', () {
    final g = DamasGame.start();
    expect(() => g.play(const DamasMove([0, 1], [])), throwsStateError);
  });

  test('play recusa lance depois do fim', () {
    final g = DamasGame.start(
      pos({sq(5, 0): 1, sq(4, 1): -1}, DamasSide.white),
    );
    final after = g.play(g.legalMoves.single);
    expect(() => after.play(const DamasMove([0, 1], [])), throwsStateError);
    expect(after.legalMoves, isEmpty);
  });
}
