// test/games/2048/board_logic_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/2048/logic/board_logic.dart';

void main() {
  group('slide', () {
    test('esquerda junta pares uma vez só: [2,2,2,2] → [4,4,0,0]', () {
      final r = slide([
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Direction.left);
      expect(r.board[0], [4, 4, 0, 0]);
      expect(r.points, 8);
      expect(r.moved, isTrue);
      expect(r.merged, {(0, 0), (0, 1)});
    });

    test('esquerda: [2,2,4,0] → [4,4,0,0] (o 4 novo não junta de novo)', () {
      final r = slide([
        [2, 2, 4, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Direction.left);
      expect(r.board[0], [4, 4, 0, 0]);
      expect(r.points, 4);
    });

    test('direita: [2,0,2,4] → [0,0,4,4]', () {
      final r = slide([
        [2, 0, 2, 4],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Direction.right);
      expect(r.board[0], [0, 0, 4, 4]);
      expect(r.merged, {(0, 2)});
    });

    test('cima e baixo trabalham nas colunas', () {
      final board = [
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [4, 0, 0, 0],
        [0, 0, 0, 8],
      ];
      final up = slide(board, Direction.up);
      expect([for (final row in up.board) row[0]], [4, 4, 0, 0]);
      expect(up.board[0][3], 8);

      final down = slide(board, Direction.down);
      expect([for (final row in down.board) row[0]], [0, 0, 4, 4]);
      expect(down.board[3][3], 8);
      expect(down.merged, {(2, 0)});
    });

    test('jogada que não muda nada devolve moved == false e não mexe no original', () {
      final board = [
        [2, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      final r = slide(board, Direction.left);
      expect(r.moved, isFalse);
      expect(r.points, 0);
      expect(board[0], [2, 4, 0, 0]);
    });

    test('não modifica o tabuleiro recebido', () {
      final board = [
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      slide(board, Direction.left);
      expect(board[0], [2, 2, 0, 0]);
    });
  });

  group('canMove', () {
    test('verdadeiro com casa vazia', () {
      expect(
        canMove([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 0],
        ]),
        isTrue,
      );
    });

    test('verdadeiro com vizinhas iguais na vertical', () {
      expect(
        canMove([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [2, 8, 16, 32],
        ]),
        isTrue,
      );
    });

    test('falso com tabuleiro cheio sem vizinhas iguais', () {
      expect(
        canMove([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2],
        ]),
        isFalse,
      );
    });
  });

  group('directionFromVelocity', () {
    test('eixo dominante define a direção', () {
      expect(directionFromVelocity(const Offset(500, 100)), Direction.right);
      expect(directionFromVelocity(const Offset(-500, 100)), Direction.left);
      expect(directionFromVelocity(const Offset(100, 500)), Direction.down);
      expect(directionFromVelocity(const Offset(100, -500)), Direction.up);
    });

    test('ignora gestos lentos', () {
      expect(directionFromVelocity(const Offset(50, 40)), isNull);
    });
  });

  group('directionFromDistance', () {
    test('arrasto longo define a direção pelo eixo dominante', () {
      expect(directionFromDistance(const Offset(-80, 10)), Direction.left);
      expect(directionFromDistance(const Offset(5, 60)), Direction.down);
    });

    test('toque ou arrasto curto não conta', () {
      expect(directionFromDistance(const Offset(10, 8)), isNull);
    });
  });
}
