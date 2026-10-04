// lib/games/lig4/providers/game_provider.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../widgets/player_setup.dart';
import '../logic/ai.dart';
import '../logic/board.dart';
import '../models/game_state.dart';

typedef AiRunner = Future<int> Function(List<List<int>> board, int me, AiLevel level);

class Lig4Provider extends ChangeNotifier {
  Lig4Provider({
    Random? random,
    this._thinkTime = const Duration(milliseconds: 500),
    AiRunner? aiRunner,
  }) : _random = random ?? Random() {
    _aiRunner = aiRunner ?? _defaultRunner;
  }

  /// O humano é sempre o jogador 1 (🔴); o computador é o 2 (🟡).
  static const int computer = 2;

  final Random _random;
  final Duration _thinkTime;
  late final AiRunner _aiRunner;
  bool _disposed = false;

  /// Muda a cada partida nova: descarta jogadas do computador atrasadas.
  int _gameId = 0;

  Lig4Phase _phase = Lig4Phase.setup;
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
  (int, int)? _lastMove;
  int _moveCount = 0;

  Lig4Phase get phase => _phase;
  PlayMode get mode => _mode;
  String get name1 => _name1;
  String get name2 => _name2;
  AiLevel get aiLevel => _aiLevel;
  List<List<int>> get board => _board;
  int get currentPlayer => _currentPlayer;
  int? get winner => _winner;
  List<(int, int)>? get winningCells => _winningCells;
  int get wins1 => _wins1;
  int get wins2 => _wins2;
  int get draws => _draws;
  bool get aiThinking => _aiThinking;
  (int, int)? get lastMove => _lastMove;
  int get moveCount => _moveCount;
  bool get isComputerTurn =>
      _mode == PlayMode.solo &&
      _phase == Lig4Phase.playing &&
      _currentPlayer == computer;

  void start(PlayerSetupResult setup) {
    _mode = setup.mode;
    _name1 = setup.player1;
    _name2 = setup.player2;
    _aiLevel = AiLevel.values[setup.levelIndex ?? 1];
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    _startingPlayer = 1;
    _newGame();
    notifyListeners();
  }

  void play(int col) {
    if (_phase != Lig4Phase.playing || _aiThinking || isComputerTurn) return;
    _apply(col);
  }

  void playAgain() {
    if (_phase != Lig4Phase.finished) return;
    _startingPlayer = 3 - _startingPlayer;
    _newGame();
    notifyListeners();
    if (isComputerTurn) _computerMove();
  }

  void exitToSetup() {
    _gameId++;
    _phase = Lig4Phase.setup;
    _aiThinking = false;
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    notifyListeners();
  }

  void _apply(int col) {
    final row = dropRow(_board, col);
    if (row == null) return;
    _board = drop(_board, col, _currentPlayer);
    _lastMove = (row, col);
    _moveCount++;

    final line = winningLine(_board);
    if (line != null) {
      _winner = _currentPlayer;
      _winningCells = line;
      _phase = Lig4Phase.finished;
      if (_winner == 1) {
        _wins1++;
      } else {
        _wins2++;
      }
    } else if (isFull(_board)) {
      _winner = null;
      _phase = Lig4Phase.finished;
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
    int col;
    try {
      col = await _aiRunner(snapshot, computer, _aiLevel);
    } catch (_) {
      // Nunca deixar o jogo preso em "Pensando...": joga numa coluna livre.
      final valid = validColumns(snapshot);
      col = valid[_random.nextInt(valid.length)];
    }
    if (_disposed || game != _gameId) return;
    _aiThinking = false;
    _apply(col);
  }

  Future<int> _defaultRunner(List<List<int>> board, int me, AiLevel level) {
    final seed = _random.nextInt(1 << 30);
    if (level == AiLevel.hard) {
      return compute(chooseColumnInIsolate, (board, me, level.index, seed));
    }
    return Future.value(chooseColumn(board, me, level, Random(seed)));
  }

  void _newGame() {
    _gameId++;
    _board = emptyBoard();
    _currentPlayer = _startingPlayer;
    _winner = null;
    _winningCells = null;
    _lastMove = null;
    _moveCount = 0;
    _aiThinking = false;
    _phase = Lig4Phase.playing;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
