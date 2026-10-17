// lib/games/tictactoe/providers/game_provider.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../widgets/player_setup.dart';
import '../logic/ai.dart';
import '../logic/board.dart';
import '../models/game_state.dart';

typedef AiRunner = Future<(int, int)> Function(List<List<int>> board, int me, AiLevel level);

class TicTacToeProvider extends ChangeNotifier {
  TicTacToeProvider({
    Random? random,
    this._thinkTime = const Duration(milliseconds: 500),
    AiRunner? aiRunner,
  }) : _random = random ?? Random() {
    _aiRunner = aiRunner ?? _defaultRunner;
  }

  /// O humano é sempre o jogador 1 (❌); o computador é o 2 (⭕).
  static const int computer = 2;

  final Random _random;
  final Duration _thinkTime;
  late final AiRunner _aiRunner;
  bool _disposed = false;

  /// Muda a cada partida nova: descarta jogadas do computador atrasadas.
  int _gameId = 0;

  GamePhase _phase = GamePhase.setup;
  PlayMode _mode = PlayMode.twoPlayers;
  String _name1 = '';
  String _name2 = '';
  AiLevel _aiLevel = AiLevel.medium;
  List<List<int>> _board = emptyBoard();
  int _currentPlayer = 1;
  int _startingPlayer = 1;
  int? _winner;
  List<(int, int)>? _winningCells;
  int _wins1 = 0;
  int _wins2 = 0;
  int _draws = 0;
  bool _aiThinking = false;

  GamePhase get phase => _phase;
  PlayMode get mode => _mode;
  String get name1 => _name1;
  String get name2 => _name2;
  AiLevel get aiLevel => _aiLevel;
  List<List<int>> get board => _board;
  int get currentPlayer => _currentPlayer;
  int get startingPlayer => _startingPlayer;
  int? get winner => _winner;
  List<(int, int)>? get winningCells => _winningCells;
  int get wins1 => _wins1;
  int get wins2 => _wins2;
  int get draws => _draws;
  bool get aiThinking => _aiThinking;
  bool get isComputerTurn =>
      _mode == PlayMode.solo && _phase == GamePhase.playing && _currentPlayer == computer;

  void start(PlayerSetupResult setup) {
    if (_phase != GamePhase.setup) return;
    _mode = setup.mode;
    _name1 = setup.player1;
    _name2 = setup.player2;
    _aiLevel = AiLevel.values[setup.levelIndex ?? AiLevel.medium.index];
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    _startingPlayer = 1;
    _newGame();
    notifyListeners();
  }

  void play(int row, int col) {
    if (_phase != GamePhase.playing || _aiThinking || isComputerTurn) return;
    if (!isInside(row, col) || _board[row][col] != 0) return;
    _apply(row, col);
  }

  void playAgain() {
    if (_phase != GamePhase.finished) return;
    _startingPlayer = 3 - _startingPlayer;
    _newGame();
    notifyListeners();
    if (isComputerTurn) _computerMove();
  }

  void exitToSetup() {
    if (_phase == GamePhase.setup) return;
    _gameId++;
    _phase = GamePhase.setup;
    _aiThinking = false;
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    notifyListeners();
  }

  void _apply(int row, int col) {
    _board = place(_board, row, col, _currentPlayer);

    final line = winningLine(_board);
    if (line != null) {
      _winner = _currentPlayer;
      _winningCells = line;
      _phase = GamePhase.finished;
      if (_winner == 1) {
        _wins1++;
      } else {
        _wins2++;
      }
    } else if (isFull(_board)) {
      _winner = null;
      _phase = GamePhase.finished;
      _draws++;
    } else {
      _currentPlayer = 3 - _currentPlayer;
    }
    notifyListeners();
    if (isComputerTurn) _computerMove();
  }

  Future<void> _computerMove() async {
    final game = _gameId;
    _aiThinking = true;
    notifyListeners();
    await Future<void>.delayed(_thinkTime);
    if (_disposed || game != _gameId) return;
    final snapshot = _board.map((r) => List<int>.from(r)).toList();
    (int, int) move;
    try {
      move = await _aiRunner(snapshot, computer, _aiLevel);
      if (!isInside(move.$1, move.$2) || snapshot[move.$1][move.$2] != 0) {
        throw StateError('Jogada inválida: $move');
      }
    } catch (_) {
      // Nunca deixar o jogo preso em "Pensando...": joga numa casa livre.
      final free = freeCells(snapshot);
      move = free[_random.nextInt(free.length)];
    }
    if (_disposed || game != _gameId) return;
    _aiThinking = false;
    _apply(move.$1, move.$2);
  }

  Future<(int, int)> _defaultRunner(List<List<int>> board, int me, AiLevel level) async =>
      chooseMove(board, me, level, _random);

  void _newGame() {
    _gameId++;
    _board = emptyBoard();
    _currentPlayer = _startingPlayer;
    _winner = null;
    _winningCells = null;
    _aiThinking = false;
    _phase = GamePhase.playing;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
