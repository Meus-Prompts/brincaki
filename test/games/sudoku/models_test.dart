// test/games/sudoku/models_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/sudoku/models/sudoku_cell.dart';

import 'fixtures.dart';

void main() {
  group('SudokuCell', () {
    test('padrão é vazia, livre e sem erro', () {
      const cell = SudokuCell();
      expect(cell.value, 0);
      expect(cell.isEmpty, isTrue);
      expect(cell.isFixed, isFalse);
      expect(cell.isError, isFalse);
    });

    test('copyWith troca só o que foi pedido', () {
      const cell = SudokuCell(value: 4, isFixed: true);
      final copy = cell.copyWith(isError: true);
      expect(copy.value, 4);
      expect(copy.isFixed, isTrue);
      expect(copy.isError, isTrue);
      expect(copy.isEmpty, isFalse);

      final other = cell.copyWith(value: 0, isFixed: false);
      expect(other.isEmpty, isTrue);
      expect(other.isFixed, isFalse);
      expect(other.isError, isFalse);
    });
  });

  group('SudokuBoard', () {
    test('getCell e getHint leem o tabuleiro e a solução', () {
      final board = boardFrom(kPuzzle);
      expect(board.getCell(0, 0).value, 5);
      expect(board.getCell(0, 0).isFixed, isTrue);
      expect(board.getCell(0, 2).isEmpty, isTrue);
      expect(board.getHint(0, 2), 4);
    });

    test('setCell devolve um novo tabuleiro e não mexe no antigo', () {
      final board = boardFrom(kPuzzle);
      final next = board.setCell(0, 2, 4);
      expect(next, isNot(same(board)));
      expect(next.getCell(0, 2).value, 4);
      expect(board.getCell(0, 2).isEmpty, isTrue);
    });

    test('setCell numa casa fixa não muda nada', () {
      final board = boardFrom(kPuzzle);
      expect(board.setCell(0, 0, 9), same(board));
    });

    test('número repetido na linha, na coluna ou no bloco fica com erro', () {
      final board = boardFrom(kPuzzle);
      expect(board.setCell(0, 2, 5).getCell(0, 2).isError, isTrue); // linha
      expect(board.setCell(2, 0, 4).getCell(2, 0).isError, isTrue); // coluna
      expect(board.setCell(1, 1, 8).getCell(1, 1).isError, isTrue); // bloco
      expect(board.setCell(0, 2, 4).getCell(0, 2).isError, isFalse);
    });

    test('isValidMove olha linha, coluna e bloco', () {
      final board = boardFrom(kPuzzle);
      expect(board.isValidMove(0, 2, 3), isFalse); // 3 na linha
      expect(board.isValidMove(0, 2, 8), isFalse); // 8 na coluna
      expect(board.isValidMove(0, 2, 6), isFalse); // 6 no bloco
      expect(board.isValidMove(0, 2, 4), isTrue);
    });

    test('número certo que não conflita não tem erro, mesmo se diferente da solução', () {
      // O erro é por conflito, não por comparar com a solução.
      final board = boardFrom(kPuzzle).setCell(0, 2, 1);
      expect(board.getCell(0, 2).isError, isFalse);
    });

    test('desfazer o conflito tira o erro da outra casa', () {
      var board = boardFrom(kPuzzle);
      board = board.setCell(0, 2, 4).setCell(0, 3, 4);
      expect(board.getCell(0, 2).isError, isTrue);
      expect(board.getCell(0, 3).isError, isTrue);

      board = board.setCell(0, 3, 0);
      expect(board.getCell(0, 2).isError, isFalse);
      expect(board.getCell(0, 3).isEmpty, isTrue);
      expect(board.getCell(0, 3).isError, isFalse);
    });

    test('revalidateAll marca só as casas livres em conflito', () {
      final board = boardFrom(kPuzzle);
      // Monta o conflito "na mão", sem passar pelo setCell.
      board.cells[0][2] = const SudokuCell(value: 5);
      final checked = board.revalidateAll();
      expect(checked.getCell(0, 2).isError, isTrue);
      expect(checked.getCell(0, 0).isError, isFalse); // fixa nunca fica vermelha
    });

    test('isComplete só com tudo preenchido e sem erros', () {
      expect(boardFrom(kPuzzle).isComplete, isFalse);
      expect(boardFrom(kSolved).isComplete, isTrue);

      var board = boardFrom(kPuzzle);
      for (final (r, c) in emptyCells(board)) {
        board = board.setCell(r, c, kSolved[r][c]);
      }
      expect(board.isComplete, isTrue);

      // Troca dois números livres da linha 0: cheio, mas com conflitos.
      board = board.setCell(0, 2, 6);
      expect(board.isComplete, isFalse);
    });
  });
}
