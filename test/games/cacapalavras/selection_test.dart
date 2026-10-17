// test/games/cacapalavras/selection_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/cacapalavras/models/game_state.dart';
import 'package:brincaki/games/cacapalavras/services/selection.dart';

void main() {
  group('snapLine', () {
    test('mesma célula devolve só ela', () {
      expect(snapLine((2, 2), (2, 2), 6), [(2, 2)]);
      expect(snapLine((0, 0), (0, 0), 1), [(0, 0)]);
    });

    // Do centro (5,5) de uma grade 11×11, 3 passos em cada direção.
    for (final d in Direction.values) {
      test('reta exata para ${d.name}', () {
        final end = (5 + d.dr * 3, 5 + d.dc * 3);
        expect(snapLine((5, 5), end, 11), [
          for (var k = 0; k <= 3; k++) (5 + d.dr * k, 5 + d.dc * k),
        ]);
      });

      test('ponto um pouco fora da reta gruda em ${d.name}', () {
        // Desvio de uma célula, perpendicular à direção, a 4 passos de
        // distância: o ângulo fica a menos de 22,5° da direção certa.
        final perpendicular = (d.dc, -d.dr);
        final end = (
          5 + d.dr * 4 + perpendicular.$1,
          5 + d.dc * 4 + perpendicular.$2,
        );
        final cells = snapLine((5, 5), end, 11);
        expect(cells.first, (5, 5));
        for (var k = 1; k < cells.length; k++) {
          expect(cells[k].$1 - cells[k - 1].$1, d.dr, reason: '$cells');
          expect(cells[k].$2 - cells[k - 1].$2, d.dc, reason: '$cells');
        }
        // Comprimento = maior deslocamento (5 nas diagonais, 4 nas retas).
        final steps = [
          end.$1 - 5,
          end.$2 - 5,
        ].map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
        expect(cells.length, steps + 1);
      });
    }

    test('horizontal, vertical e para cima', () {
      expect(snapLine((1, 1), (1, 4), 6), [(1, 1), (1, 2), (1, 3), (1, 4)]);
      expect(snapLine((0, 2), (2, 2), 6), [(0, 2), (1, 2), (2, 2)]);
      expect(snapLine((3, 3), (0, 3), 6), [(3, 3), (2, 3), (1, 3), (0, 3)]);
    });

    test('ponto fora da reta gruda na direção mais próxima', () {
      // (2,3) está a ~34° da horizontal → diagonal ↘, comprimento 3.
      expect(snapLine((0, 0), (2, 3), 6), [(0, 0), (1, 1), (2, 2), (3, 3)]);
      // (1,4) está a ~14° → horizontal.
      expect(snapLine((0, 0), (1, 4), 6), [
        (0, 0),
        (0, 1),
        (0, 2),
        (0, 3),
        (0, 4),
      ]);
      // (4,1) está a ~76° → vertical.
      expect(snapLine((0, 0), (4, 1), 6), [
        (0, 0),
        (1, 0),
        (2, 0),
        (3, 0),
        (4, 0),
      ]);
    });

    test('o comprimento é o maior dos deslocamentos', () {
      expect(snapLine((5, 0), (2, 2), 6), [(5, 0), (4, 1), (3, 2), (2, 3)]);
    });

    test('para na borda da grade', () {
      expect(snapLine((4, 4), (1, 7), 6), [(4, 4), (3, 5)]);
      expect(snapLine((0, 0), (0, -5), 6), [(0, 0)]);
      expect(snapLine((5, 5), (9, 9), 6), [(5, 5)]);
      expect(snapLine((0, 3), (-2, 3), 6), [(0, 3)]);
    });

    test('início fora da grade é uma seleção inválida (vazia)', () {
      expect(snapLine((6, 0), (6, 3), 6), isEmpty);
      expect(snapLine((-1, -1), (2, 2), 6), isEmpty);
    });
  });
}
