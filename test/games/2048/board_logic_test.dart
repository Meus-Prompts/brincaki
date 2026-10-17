// test/games/2048/board_logic_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/2048/logic/board_logic.dart';

/// Tabuleiro 4x4 com [row] na primeira linha e o resto vazio.
List<List<int>> firstRow(List<int> row) => [
      row,
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ];

/// Tabuleiro 4x4 com [col] na primeira coluna (de cima para baixo).
List<List<int>> firstCol(List<int> col) => [
      for (final v in col) [v, 0, 0, 0],
    ];

List<int> colOf(List<List<int>> board, int c) => [for (final row in board) row[c]];

void main() {
  group('slide para a esquerda', () {
    final cases = <List<int>, List<int>>{
      [0, 0, 0, 0]: [0, 0, 0, 0],
      [0, 0, 0, 2]: [2, 0, 0, 0],
      [2, 0, 0, 2]: [4, 0, 0, 0],
      [2, 2, 2, 2]: [4, 4, 0, 0],
      [2, 2, 2, 0]: [4, 2, 0, 0],
      [4, 2, 2, 0]: [4, 4, 0, 0],
      [2, 2, 4, 0]: [4, 4, 0, 0],
      [4, 4, 8, 8]: [8, 16, 0, 0],
      [2, 4, 8, 16]: [2, 4, 8, 16],
      [8, 0, 8, 8]: [16, 8, 0, 0],
      [2, 2, 4, 4]: [4, 8, 0, 0],
    };
    cases.forEach((input, expected) {
      test('$input → $expected', () {
        expect(slide(firstRow(input), Direction.left).board[0], expected);
      });
    });

    test('[2,2,2,2] dá 8 pontos e marca as duas junções', () {
      final r = slide(firstRow([2, 2, 2, 2]), Direction.left);
      expect(r.points, 8);
      expect(r.moved, isTrue);
      expect(r.merged, {(0, 0), (0, 1)});
    });

    test('o 4 recém-formado não junta de novo: [2,2,4,0] dá só 4 pontos', () {
      final r = slide(firstRow([2, 2, 4, 0]), Direction.left);
      expect(r.points, 4);
      expect(r.merged, {(0, 0)});
    });

    test('[4,4,8,8] soma 24 pontos', () {
      expect(slide(firstRow([4, 4, 8, 8]), Direction.left).points, 24);
    });
  });

  group('slide para a direita', () {
    final cases = <List<int>, List<int>>{
      [2, 0, 2, 4]: [0, 0, 4, 4],
      [2, 2, 2, 2]: [0, 0, 4, 4],
      [0, 2, 2, 2]: [0, 0, 2, 4],
      [2, 0, 0, 0]: [0, 0, 0, 2],
      [2, 4, 8, 16]: [2, 4, 8, 16],
    };
    cases.forEach((input, expected) {
      test('$input → $expected', () {
        expect(slide(firstRow(input), Direction.right).board[0], expected);
      });
    });

    test('marca a junção na casa de destino', () {
      final r = slide(firstRow([2, 0, 2, 4]), Direction.right);
      expect(r.merged, {(0, 2)});
      expect(r.points, 4);
    });

    test('[2,2,2,2] junta na ponta direita primeiro', () {
      final r = slide(firstRow([2, 2, 2, 2]), Direction.right);
      expect(r.merged, {(0, 3), (0, 2)});
    });
  });

  group('slide para cima', () {
    final cases = <List<int>, List<int>>{
      [2, 2, 2, 2]: [4, 4, 0, 0],
      [0, 0, 0, 2]: [2, 0, 0, 0],
      [2, 2, 4, 0]: [4, 4, 0, 0],
      [0, 4, 0, 4]: [8, 0, 0, 0],
    };
    cases.forEach((input, expected) {
      test('$input → $expected', () {
        expect(colOf(slide(firstCol(input), Direction.up).board, 0), expected);
      });
    });

    test('marca as junções nas linhas de cima', () {
      final r = slide(firstCol([2, 2, 2, 2]), Direction.up);
      expect(r.merged, {(0, 0), (1, 0)});
    });
  });

  group('slide para baixo', () {
    final cases = <List<int>, List<int>>{
      [2, 2, 2, 2]: [0, 0, 4, 4],
      [2, 0, 0, 0]: [0, 0, 0, 2],
      [4, 2, 2, 0]: [0, 0, 4, 4],
      [8, 8, 0, 16]: [0, 0, 16, 16],
    };
    cases.forEach((input, expected) {
      test('$input → $expected', () {
        expect(colOf(slide(firstCol(input), Direction.down).board, 0), expected);
      });
    });

    test('marca as junções nas linhas de baixo', () {
      final r = slide(firstCol([2, 2, 2, 2]), Direction.down);
      expect(r.merged, {(3, 0), (2, 0)});
    });
  });

  test('cada linha e coluna é tratada de forma independente', () {
    final board = [
      [2, 0, 0, 0],
      [2, 0, 0, 0],
      [4, 0, 0, 0],
      [0, 0, 0, 8],
    ];
    final up = slide(board, Direction.up);
    expect(colOf(up.board, 0), [4, 4, 0, 0]);
    expect(up.board[0][3], 8);

    final down = slide(board, Direction.down);
    expect(colOf(down.board, 0), [0, 0, 4, 4]);
    expect(down.board[3][3], 8);
    expect(down.merged, {(2, 0)});
  });

  test('junta em várias linhas ao mesmo tempo', () {
    final r = slide([
      [2, 2, 0, 0],
      [4, 4, 0, 0],
      [8, 0, 8, 0],
      [0, 0, 0, 0],
    ], Direction.left);
    expect(r.board, [
      [4, 0, 0, 0],
      [8, 0, 0, 0],
      [16, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    expect(r.points, 28);
    expect(r.merged, {(0, 0), (1, 0), (2, 0)});
  });

  group('jogada sem mudança', () {
    for (final direction in Direction.values) {
      test('${direction.name}: moved == false, sem pontos nem junções', () {
        // Peças que não podem ir para lado nenhum.
        final board = [
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2],
        ];
        final r = slide(board, direction);
        expect(r.moved, isFalse);
        expect(r.points, 0);
        expect(r.merged, isEmpty);
        expect(r.board, board);
      });
    }

    test('peças já encostadas na borda não se movem', () {
      final r = slide(firstRow([2, 4, 0, 0]), Direction.left);
      expect(r.moved, isFalse);
    });

    test('tabuleiro vazio não se move', () {
      final r = slide(firstRow([0, 0, 0, 0]), Direction.down);
      expect(r.moved, isFalse);
    });
  });

  test('não modifica o tabuleiro recebido', () {
    final board = firstRow([2, 2, 0, 0]);
    final r = slide(board, Direction.left);
    expect(board[0], [2, 2, 0, 0]);
    expect(identical(r.board, board), isFalse);
  });

  test('funciona com outros tamanhos de tabuleiro', () {
    final r = slide([
      [2, 2, 2],
      [0, 0, 0],
      [0, 0, 0],
    ], Direction.right);
    expect(r.board[0], [0, 2, 4]);
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

    test('verdadeiro com vizinhas iguais na horizontal', () {
      expect(
        canMove([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 8, 8],
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

    test('verdadeiro com vizinhas iguais na última coluna', () {
      expect(
        canMove([
          [2, 4, 2, 4],
          [4, 2, 4, 8],
          [2, 4, 2, 8],
          [4, 2, 4, 2],
        ]),
        isTrue,
      );
    });

    test('falso com tabuleiro cheio sem vizinhas iguais (fim de jogo)', () {
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

    test('iguais só na diagonal não contam', () {
      expect(
        canMove([
          [2, 4, 8, 16],
          [4, 2, 16, 8],
          [8, 16, 2, 4],
          [16, 8, 4, 2],
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
      expect(directionFromVelocity(Offset.zero), isNull);
    });

    test('empate entre os eixos fica com o vertical', () {
      expect(directionFromVelocity(const Offset(300, 300)), Direction.down);
    });
  });

  group('directionFromDistance', () {
    test('arrasto longo define a direção pelo eixo dominante', () {
      expect(directionFromDistance(const Offset(-80, 10)), Direction.left);
      expect(directionFromDistance(const Offset(80, 10)), Direction.right);
      expect(directionFromDistance(const Offset(5, 60)), Direction.down);
      expect(directionFromDistance(const Offset(5, -60)), Direction.up);
    });

    test('toque ou arrasto curto não conta', () {
      expect(directionFromDistance(const Offset(10, 8)), isNull);
      expect(directionFromDistance(Offset.zero), isNull);
    });
  });
}
