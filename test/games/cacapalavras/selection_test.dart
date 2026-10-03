// test/games/cacapalavras/selection_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/cacapalavras/services/selection.dart';

void main() {
  group('snapLine', () {
    test('mesma célula devolve só ela', () {
      expect(snapLine((2, 2), (2, 2), 6), [(2, 2)]);
    });

    test('horizontal, vertical e para cima', () {
      expect(snapLine((1, 1), (1, 4), 6), [(1, 1), (1, 2), (1, 3), (1, 4)]);
      expect(snapLine((0, 2), (2, 2), 6), [(0, 2), (1, 2), (2, 2)]);
      expect(snapLine((3, 3), (0, 3), 6), [(3, 3), (2, 3), (1, 3), (0, 3)]);
    });

    test('ponto fora da reta gruda na direção mais próxima', () {
      // (2,3) está a ~34° da horizontal → diagonal ↘, comprimento 3.
      expect(snapLine((0, 0), (2, 3), 6), [(0, 0), (1, 1), (2, 2), (3, 3)]);
      // (1,4) está a ~14° → horizontal.
      expect(snapLine((0, 0), (1, 4), 6), [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)]);
    });

    test('para na borda da grade', () {
      expect(snapLine((4, 4), (1, 7), 6), [(4, 4), (3, 5)]);
    });
  });
}
