// test/games/tictactoe/board_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/tictactoe/logic/board.dart';

/// Monta um tabuleiro a partir de 3 strings: '.' vazio, 'x' = 1, 'o' = 2.
List<List<int>> parse(List<String> rows) => [
  for (final row in rows) [for (final ch in row.split('')) ch == 'x' ? 1 : (ch == 'o' ? 2 : 0)],
];

void main() {
  group('emptyBoard', () {
    test('3x3 com tudo vazio', () {
      final b = emptyBoard();
      expect(b, hasLength(3));
      for (final row in b) {
        expect(row, [0, 0, 0]);
      }
    });

    test('linhas independentes (mudar uma não muda as outras)', () {
      final b = emptyBoard();
      b[0][0] = 1;
      expect(b[1][0], 0);
      expect(b[2][0], 0);
    });
  });

  group('isInside', () {
    test('aceita as 9 casas', () {
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          expect(isInside(r, c), isTrue);
        }
      }
    });

    test('recusa fora do tabuleiro', () {
      for (final (r, c) in const [(-1, 0), (0, -1), (3, 0), (0, 3), (5, 5)]) {
        expect(isInside(r, c), isFalse, reason: '($r, $c)');
      }
    });
  });

  group('place', () {
    test('devolve uma cópia com a peça e não mexe no original', () {
      final b = emptyBoard();
      final next = place(b, 1, 2, 2);
      expect(next[1][2], 2);
      expect(b[1][2], 0);
    });

    test('casa ocupada lança ArgumentError', () {
      final b = place(emptyBoard(), 0, 0, 1);
      expect(() => place(b, 0, 0, 2), throwsArgumentError);
    });

    test('fora do tabuleiro lança RangeError', () {
      expect(() => place(emptyBoard(), 3, 0, 1), throwsRangeError);
      expect(() => place(emptyBoard(), 0, -1, 1), throwsRangeError);
    });
  });

  group('winningLine e hasLine', () {
    test('tabuleiro vazio não tem linha', () {
      expect(winningLine(emptyBoard()), isNull);
      expect(hasLine(emptyBoard(), 1), isFalse);
      expect(hasLine(emptyBoard(), 2), isFalse);
    });

    test('reconhece as 8 linhas para os dois jogadores', () {
      expect(kLines, hasLength(8));
      for (final player in const [1, 2]) {
        for (final line in kLines) {
          var b = emptyBoard();
          for (final (r, c) in line) {
            b = place(b, r, c, player);
          }
          expect(winningLine(b), line);
          expect(hasLine(b, player), isTrue);
          expect(hasLine(b, 3 - player), isFalse);
        }
      }
    });

    test('duas peças só não formam linha', () {
      final b = parse(['xx.', 'oo.', '...']);
      expect(winningLine(b), isNull);
    });

    test('peças misturadas não formam linha', () {
      final b = parse(['xox', 'oxo', 'oxo']);
      expect(winningLine(b), isNull);
      expect(isFull(b), isTrue);
    });

    test('linha do ⭕ no meio de outras peças', () {
      final b = parse(['xox', 'xo.', '.o.']);
      expect(winningLine(b), [(0, 1), (1, 1), (2, 1)]);
      expect(hasLine(b, 2), isTrue);
      expect(hasLine(b, 1), isFalse);
    });
  });

  group('isFull e freeCells', () {
    test('vazio tem 9 casas livres em ordem de leitura', () {
      expect(isFull(emptyBoard()), isFalse);
      expect(freeCells(emptyBoard()), [
        (0, 0),
        (0, 1),
        (0, 2),
        (1, 0),
        (1, 1),
        (1, 2),
        (2, 0),
        (2, 1),
        (2, 2),
      ]);
    });

    test('lista só as casas vazias', () {
      final b = parse(['x.o', '.x.', 'oo.']);
      expect(freeCells(b), [(0, 1), (1, 0), (1, 2), (2, 2)]);
      expect(isFull(b), isFalse);
    });

    test('cheio não tem casas livres', () {
      final b = parse(['xox', 'xoo', 'oxx']);
      expect(isFull(b), isTrue);
      expect(freeCells(b), isEmpty);
    });
  });
}
