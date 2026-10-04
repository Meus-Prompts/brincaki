// test/games/lig4/board_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/lig4/logic/board.dart';

/// Monta um tabuleiro a partir de 6 strings de 7 caracteres ('.', '1', '2'),
/// da linha de cima para a de baixo.
List<List<int>> board(List<String> rows) => [
      for (final r in rows) [for (final ch in r.split('')) ch == '.' ? 0 : int.parse(ch)],
    ];

void main() {
  test('peça cai na posição livre mais baixa', () {
    var b = emptyBoard();
    expect(dropRow(b, 3), 5);
    b = drop(b, 3, 1);
    expect(b[5][3], 1);
    expect(dropRow(b, 3), 4);
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

  test('vitória horizontal, vertical e nas duas diagonais', () {
    expect(winningLine(board([
      '.......', '.......', '.......', '.......', '.......', '.1111..',
    ])), [(5, 1), (5, 2), (5, 3), (5, 4)]);
    expect(winningLine(board([
      '.......', '.......', '..2....', '..2....', '..2....', '..2....',
    ])), isNotNull);
    expect(winningLine(board([
      '.......', '.......', '...1...', '..12...', '.122...', '1222...',
    ])), isNotNull); // diagonal ↗
    expect(winningLine(board([
      '.......', '.......', '1......', '21.....', '221....', '2221...',
    ])), isNotNull); // diagonal ↘
  });

  test('peças de jogadores diferentes não formam linha', () {
    expect(winningLine(board([
      '.......', '.......', '.......', '.......', '.......', '.1121..',
    ])), isNull);
    expect(hasLine(board([
      '.......', '.......', '.......', '.......', '.......', '2222...',
    ]), 1), isFalse);
  });

  test('isFull', () {
    expect(isFull(emptyBoard()), isFalse);
    expect(isFull(List.generate(kRows, (r) => List.filled(kCols, 1 + r % 2))), isTrue);
  });
}
