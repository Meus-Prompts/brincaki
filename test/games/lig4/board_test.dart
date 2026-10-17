// test/games/lig4/board_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/lig4/logic/board.dart';

/// Monta um tabuleiro a partir de 6 strings de 7 caracteres ('.', '1', '2'),
/// da linha de cima para a de baixo.
List<List<int>> board(List<String> rows) => [
      for (final r in rows) [for (final ch in r.split('')) ch == '.' ? 0 : int.parse(ch)],
    ];

void main() {
  test('tabuleiro vazio tem 6 linhas de 7 casas zeradas', () {
    final b = emptyBoard();
    expect(b, hasLength(kRows));
    for (final row in b) {
      expect(row, List.filled(kCols, 0));
    }
    expect(validColumns(b), [0, 1, 2, 3, 4, 5, 6]);
    expect(winningLine(b), isNull);
  });

  test('peça cai na posição livre mais baixa', () {
    var b = emptyBoard();
    expect(dropRow(b, 3), 5);
    b = drop(b, 3, 1);
    expect(b[5][3], 1);
    expect(dropRow(b, 3), 4);
    b = drop(b, 3, 2);
    expect(b[4][3], 2);
    expect(dropRow(b, 3), 3);
  });

  test('drop devolve um tabuleiro novo sem mexer no original', () {
    final b = emptyBoard();
    final next = drop(b, 0, 1);
    expect(b[5][0], 0);
    expect(next[5][0], 1);
    expect(identical(next[0], b[0]), isFalse);
  });

  test('coluna cheia não aceita peça', () {
    var b = emptyBoard();
    for (var i = 0; i < kRows; i++) {
      b = drop(b, 0, i.isEven ? 1 : 2);
    }
    expect(dropRow(b, 0), isNull);
    expect(validColumns(b), [1, 2, 3, 4, 5, 6]);
    expect(() => drop(b, 0, 1), throwsArgumentError);
  });

  group('vitória horizontal', () {
    test('no meio da linha de baixo devolve as quatro casas', () {
      expect(winningLine(board([
        '.......', '.......', '.......', '.......', '.......', '.1111..',
      ])), [(5, 1), (5, 2), (5, 3), (5, 4)]);
    });

    test('encostada na borda esquerda', () {
      expect(winningLine(board([
        '.......', '.......', '.......', '.......', '.......', '2222...',
      ])), [(5, 0), (5, 1), (5, 2), (5, 3)]);
    });

    test('encostada na borda direita, na linha de cima', () {
      expect(winningLine(board([
        '...1111', '...2222', '...1111', '...2222', '...1111', '...2222',
      ])), [(0, 3), (0, 4), (0, 5), (0, 6)]);
    });

    test('cinco seguidas também vencem', () {
      expect(hasLine(board([
        '.......', '.......', '.......', '.......', '.......', '11111..',
      ]), 1), isTrue);
    });
  });

  group('vitória vertical', () {
    test('na coluna da esquerda, de baixo', () {
      expect(winningLine(board([
        '.......', '.......', '1......', '1......', '1......', '1......',
      ])), [(2, 0), (3, 0), (4, 0), (5, 0)]);
    });

    test('na coluna da direita, até o topo', () {
      expect(winningLine(board([
        '......2', '......2', '......2', '......2', '......1', '......1',
      ])), [(0, 6), (1, 6), (2, 6), (3, 6)]);
    });

    test('no meio', () {
      expect(winningLine(board([
        '.......', '.......', '..2....', '..2....', '..2....', '..2....',
      ])), isNotNull);
    });
  });

  group('vitória diagonal', () {
    test('↗ começando no canto de baixo à esquerda', () {
      expect(winningLine(board([
        '.......', '.......', '...1...', '..12...', '.122...', '1222...',
      ])), [(5, 0), (4, 1), (3, 2), (2, 3)]);
    });

    test('↗ terminando no canto de cima à direita', () {
      expect(hasLine(board([
        '......2', '.....21', '....212', '...2121', '...1212', '...2121',
      ]), 2), isTrue);
    });

    test('↘ começando no canto de cima à esquerda', () {
      expect(winningLine(board([
        '1......', '21.....', '121....', '2121...', '1212...', '2121...',
      ])), [(0, 0), (1, 1), (2, 2), (3, 3)]);
    });

    test('↘ terminando no canto de baixo à direita', () {
      expect(hasLine(board([
        '.......', '.......', '...2...', '...12..', '...212.', '...1212',
      ]), 2), isTrue);
    });
  });

  test('peças de jogadores diferentes não formam linha', () {
    expect(winningLine(board([
      '.......', '.......', '.......', '.......', '.......', '.1121..',
    ])), isNull);
    expect(hasLine(board([
      '.......', '.......', '.......', '.......', '.......', '2222...',
    ]), 1), isFalse);
  });

  test('três seguidas não vencem', () {
    expect(winningLine(board([
      '.......', '.......', '.......', '1......', '1......', '1112...',
    ])), isNull);
  });

  test('linha não dá a volta de uma fileira para a outra', () {
    // 2 nas duas últimas casas de uma linha e nas duas primeiras da de baixo.
    expect(winningLine(board([
      '.......', '.......', '.......', '.......', '.....22', '22.....',
    ])), isNull);
  });

  test('vitória do jogador 2 é encontrada pelo winningLine', () {
    final b = board([
      '.......', '.......', '.......', '.......', '.......', '..2222.',
    ]);
    expect(winningLine(b), [(5, 2), (5, 3), (5, 4), (5, 5)]);
    expect(hasLine(b, 2), isTrue);
    expect(hasLine(b, 1), isFalse);
  });

  test('isFull e validColumns com o tabuleiro cheio', () {
    expect(isFull(emptyBoard()), isFalse);
    final full = List.generate(kRows, (r) => List.filled(kCols, 1 + r % 2));
    expect(isFull(full), isTrue);
    expect(validColumns(full), isEmpty);
  });

  test('isFull olha só a linha de cima', () {
    final almost = List.generate(kRows, (r) => List.filled(kCols, 1 + r % 2));
    almost[0][6] = 0;
    expect(isFull(almost), isFalse);
    expect(validColumns(almost), [6]);
  });
}
