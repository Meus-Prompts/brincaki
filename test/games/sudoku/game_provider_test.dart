// test/games/sudoku/game_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/sudoku/models/difficulty.dart';
import 'package:brincaki/games/sudoku/providers/game_provider.dart';

void main() {
  group('Sudoku GameProvider', () {
    late GameProvider provider;

    setUp(() {
      provider = GameProvider();
    });

    tearDown(() {
      provider.dispose(); // cancela o cronômetro
    });

    int countEmpty() {
      var empty = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (provider.board!.getCell(r, c).isEmpty) empty++;
        }
      }
      return empty;
    }

    (int, int) firstEmptyCell() {
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (provider.board!.getCell(r, c).isEmpty) return (r, c);
        }
      }
      throw StateError('tabuleiro sem casas vazias');
    }

    for (final difficulty in Difficulty.values) {
      test('startGame(${difficulty.name}) deixa casas vazias dentro da faixa', () {
        provider.startGame(difficulty);
        expect(
          countEmpty(),
          inInclusiveRange(difficulty.minEmpty, difficulty.maxEmpty),
        );
      });
    }

    test('enterNumber marca erro quando o número já está na linha', () {
      provider.startGame(Difficulty.easy);
      final (row, col) = firstEmptyCell();
      // Um número fixo da mesma linha sempre conflita.
      final fixedInRow = List.generate(9, (c) => provider.board!.getCell(row, c))
          .firstWhere((cell) => cell.isFixed)
          .value;

      provider.selectCell(row, col);
      provider.enterNumber(fixedInRow);

      expect(provider.board!.getCell(row, col).value, fixedInRow);
      expect(provider.board!.getCell(row, col).isError, isTrue);
    });

    test('useHint preenche a casa com a solução e consome uma dica', () {
      provider.startGame(Difficulty.easy);
      final (row, col) = firstEmptyCell();

      provider.selectCell(row, col);
      provider.useHint();

      expect(provider.hintsRemaining, 2);
      expect(provider.board!.getCell(row, col).value,
          provider.board!.getHint(row, col));
      expect(provider.board!.getCell(row, col).isError, isFalse);
    });

    test('dicas acabam depois de 3 usos', () {
      provider.startGame(Difficulty.easy);
      for (var i = 0; i < 4; i++) {
        final (row, col) = firstEmptyCell();
        provider.selectCell(row, col);
        provider.useHint();
      }
      expect(provider.hintsRemaining, 0);
    });
  });
}
