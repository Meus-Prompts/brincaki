// lib/games/tictactoe/providers/game_provider.dart

import 'package:flutter/foundation.dart';
import '../models/game_state.dart';

class TicTacToeProvider extends ChangeNotifier {
  GamePhase _phase = GamePhase.setup;
  String _player1Name = '';
  String _player2Name = '';
  List<List<Cell>> _board = _emptyBoard();
  int _currentPlayer = 1;
  int _score1 = 0;
  int _score2 = 0;
  int _draws = 0;
  int? _winner;
  List<(int, int)>? _winningCells;

  GamePhase get phase => _phase;
  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  List<List<Cell>> get board => _board;
  int get currentPlayer => _currentPlayer;
  int get score1 => _score1;
  int get score2 => _score2;
  int get draws => _draws;
  int? get winner => _winner;
  List<(int, int)>? get winningCells => _winningCells;

  static List<List<Cell>> _emptyBoard() =>
      List.generate(3, (_) => List.filled(3, Cell.empty));

  void setNames(String p1, String p2) {
    _player1Name = p1;
    _player2Name = p2;
    _startGame();
  }

  void _startGame() {
    _board = _emptyBoard();
    _currentPlayer = 1;
    _winner = null;
    _winningCells = null;
    _phase = GamePhase.playing;
    notifyListeners();
  }

  void makeMove(int row, int col) {
    if (_phase != GamePhase.playing) return;
    if (_board[row][col] != Cell.empty) return;

    final newBoard = _board.map((r) => List<Cell>.from(r)).toList();
    newBoard[row][col] = _currentPlayer == 1 ? Cell.x : Cell.o;
    _board = newBoard;

    final winning = _checkWin(newBoard, row, col);
    if (winning != null) {
      _winningCells = winning;
      _winner = _currentPlayer;
      if (_currentPlayer == 1) {
        _score1++;
      } else {
        _score2++;
      }
      _phase = GamePhase.result;
    } else if (_isBoardFull(newBoard)) {
      _winner = null;
      _winningCells = null;
      _draws++;
      _phase = GamePhase.result;
    } else {
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
    }

    notifyListeners();
  }

  void playAgain() {
    _startGame();
  }

  void exitGame() {
    _score1 = 0;
    _score2 = 0;
    _draws = 0;
    _player1Name = '';
    _player2Name = '';
    _board = _emptyBoard();
    _currentPlayer = 1;
    _winner = null;
    _winningCells = null;
    _phase = GamePhase.setup;
    notifyListeners();
  }

  bool _isBoardFull(List<List<Cell>> board) {
    return board.every((row) => row.every((c) => c != Cell.empty));
  }

  List<(int, int)>? _checkWin(List<List<Cell>> board, int row, int col) {
    final cell = board[row][col];
    if (cell == Cell.empty) return null;

    // Linhas
    for (int r = 0; r < 3; r++) {
      if (board[r][0] == cell && board[r][1] == cell && board[r][2] == cell) {
        return [(r, 0), (r, 1), (r, 2)];
      }
    }
    // Colunas
    for (int c = 0; c < 3; c++) {
      if (board[0][c] == cell && board[1][c] == cell && board[2][c] == cell) {
        return [(0, c), (1, c), (2, c)];
      }
    }
    // Diagonal principal
    if (board[0][0] == cell && board[1][1] == cell && board[2][2] == cell) {
      return [(0, 0), (1, 1), (2, 2)];
    }
    // Diagonal secundária
    if (board[0][2] == cell && board[1][1] == cell && board[2][0] == cell) {
      return [(0, 2), (1, 1), (2, 0)];
    }
    return null;
  }
}
