// test/games/tictactoe/game_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/tictactoe/providers/game_provider.dart';
import 'package:brincaki/games/tictactoe/models/game_state.dart';

void main() {
  group('TicTacToeProvider', () {
    late TicTacToeProvider provider;

    setUp(() {
      provider = TicTacToeProvider();
    });

    test('starts in setup phase', () {
      expect(provider.phase, GamePhase.setup);
    });

    test('setNames transitions to playing phase', () {
      provider.setNames('Alice', 'Bob');
      expect(provider.phase, GamePhase.playing);
      expect(provider.player1Name, 'Alice');
      expect(provider.player2Name, 'Bob');
    });

    test('board starts empty after setNames', () {
      provider.setNames('Alice', 'Bob');
      for (final row in provider.board) {
        for (final cell in row) {
          expect(cell, Cell.empty);
        }
      }
    });

    test('first move places X, currentPlayer becomes 2', () {
      provider.setNames('Alice', 'Bob');
      provider.makeMove(0, 0);
      expect(provider.board[0][0], Cell.x);
      expect(provider.currentPlayer, 2);
    });

    test('second move places O, currentPlayer becomes 1', () {
      provider.setNames('Alice', 'Bob');
      provider.makeMove(0, 0);
      provider.makeMove(1, 1);
      expect(provider.board[1][1], Cell.o);
      expect(provider.currentPlayer, 1);
    });

    test('cannot play in already-filled cell', () {
      provider.setNames('Alice', 'Bob');
      provider.makeMove(0, 0);
      provider.makeMove(0, 0); // same cell
      expect(provider.board[0][0], Cell.x); // unchanged
      expect(provider.currentPlayer, 2); // still player 2's turn
    });

    test('row win detected — player 1 wins top row', () {
      provider.setNames('Alice', 'Bob');
      provider.makeMove(0, 0); // X
      provider.makeMove(1, 0); // O
      provider.makeMove(0, 1); // X
      provider.makeMove(1, 1); // O
      provider.makeMove(0, 2); // X wins
      expect(provider.phase, GamePhase.result);
      expect(provider.winner, 1);
      expect(provider.score1, 1);
    });

    test('column win detected — player 2 wins first column', () {
      provider.setNames('Alice', 'Bob');
      provider.makeMove(0, 1); // X
      provider.makeMove(0, 0); // O
      provider.makeMove(1, 1); // X
      provider.makeMove(1, 0); // O
      provider.makeMove(2, 2); // X
      provider.makeMove(2, 0); // O wins
      expect(provider.phase, GamePhase.result);
      expect(provider.winner, 2);
      expect(provider.score2, 1);
    });

    test('diagonal win detected', () {
      provider.setNames('Alice', 'Bob');
      provider.makeMove(0, 0); // X
      provider.makeMove(0, 1); // O
      provider.makeMove(1, 1); // X
      provider.makeMove(0, 2); // O
      provider.makeMove(2, 2); // X wins diagonal
      expect(provider.phase, GamePhase.result);
      expect(provider.winner, 1);
    });

    test('draw detected — all cells filled, no winner', () {
      provider.setNames('Alice', 'Bob');
      // X O X
      // X X O
      // O X O
      provider.makeMove(0, 0); // X
      provider.makeMove(0, 1); // O
      provider.makeMove(0, 2); // X
      provider.makeMove(1, 2); // O
      provider.makeMove(1, 0); // X
      provider.makeMove(2, 0); // O
      provider.makeMove(1, 1); // X
      provider.makeMove(2, 2); // O
      provider.makeMove(2, 1); // X
      expect(provider.phase, GamePhase.result);
      expect(provider.winner, null);
      expect(provider.draws, 1);
    });

    test('playAgain resets board but keeps score and names', () {
      provider.setNames('Alice', 'Bob');
      provider.makeMove(0, 0);
      provider.makeMove(0, 1);
      provider.makeMove(1, 0);
      provider.makeMove(1, 1);
      provider.makeMove(2, 0); // X wins
      final score = provider.score1;
      provider.playAgain();
      expect(provider.phase, GamePhase.playing);
      expect(provider.score1, score); // placar mantido
      expect(provider.player1Name, 'Alice');
      expect(provider.board[0][0], Cell.empty); // tabuleiro limpo
    });

    test('exitGame resets to setup and clears score', () {
      provider.setNames('Alice', 'Bob');
      provider.makeMove(0, 0);
      provider.exitGame();
      expect(provider.phase, GamePhase.setup);
      expect(provider.score1, 0);
      expect(provider.score2, 0);
      expect(provider.draws, 0);
    });

    test('winningCells returns correct cells for row win', () {
      provider.setNames('Alice', 'Bob');
      provider.makeMove(0, 0); // X
      provider.makeMove(1, 0); // O
      provider.makeMove(0, 1); // X
      provider.makeMove(1, 1); // O
      provider.makeMove(0, 2); // X wins top row
      expect(provider.winningCells, containsAll([(0, 0), (0, 1), (0, 2)]));
    });
  });
}
