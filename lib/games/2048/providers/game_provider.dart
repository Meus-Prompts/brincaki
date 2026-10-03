// lib/games/2048/providers/game_provider.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/high_score_store.dart';
import '../logic/board_logic.dart';
import '../models/game_state.dart';

class Game2048Provider extends ChangeNotifier {
  Game2048Provider({HighScoreStore? store, Random? random})
      : _store = store ?? SharedPrefsHighScoreStore(),
        _random = random ?? Random() {
    _resetBoard();
    _loadBest();
  }

  static const int size = 4;
  static const int target = 2048;

  final HighScoreStore _store;
  final Random _random;
  bool _disposed = false;

  late List<List<int>> _board;
  int _score = 0;
  int _best = 0;
  Game2048Phase _phase = Game2048Phase.playing;
  bool _keepPlaying = false;
  int _moveCount = 0;
  (int, int)? _newTile;
  Set<(int, int)> _mergedTiles = const {};

  List<List<int>> get board => _board;
  int get score => _score;
  int get best => _best;
  Game2048Phase get phase => _phase;
  int get moveCount => _moveCount;
  (int, int)? get newTile => _newTile;
  Set<(int, int)> get mergedTiles => _mergedTiles;

  void move(Direction direction) {
    if (_phase != Game2048Phase.playing) return;
    final result = slide(_board, direction);
    if (!result.moved) return;

    _board = result.board;
    _score += result.points;
    _mergedTiles = result.merged;
    _newTile = _spawnTile();
    _moveCount++;

    if (_score > _best) {
      _best = _score;
      unawaited(_store.save(_best));
    }

    if (!_keepPlaying && _board.any((row) => row.contains(target))) {
      _phase = Game2048Phase.won;
    } else if (!canMove(_board)) {
      _phase = Game2048Phase.lost;
    }
    notifyListeners();
  }

  /// Fecha o aviso de vitória. Se não sobrou jogada, vai direto ao fim de jogo.
  void continuePlaying() {
    if (_phase != Game2048Phase.won) return;
    _keepPlaying = true;
    _phase = canMove(_board) ? Game2048Phase.playing : Game2048Phase.lost;
    notifyListeners();
  }

  void newGame() {
    _resetBoard();
    notifyListeners();
  }

  @visibleForTesting
  void debugSetBoard(List<List<int>> board) {
    _board = board.map((row) => List<int>.from(row)).toList();
    _phase = Game2048Phase.playing;
    notifyListeners();
  }

  void _resetBoard() {
    _board = List.generate(size, (_) => List.filled(size, 0));
    _score = 0;
    _phase = Game2048Phase.playing;
    _keepPlaying = false;
    _moveCount = 0;
    _mergedTiles = const {};
    _spawnTile();
    _newTile = _spawnTile();
  }

  (int, int)? _spawnTile() {
    final empty = [
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++)
          if (_board[r][c] == 0) (r, c),
    ];
    if (empty.isEmpty) return null;
    final (r, c) = empty[_random.nextInt(empty.length)];
    _board[r][c] = _random.nextDouble() < 0.9 ? 2 : 4;
    return (r, c);
  }

  Future<void> _loadBest() async {
    final saved = await _store.load();
    if (_disposed || saved <= _best) return;
    _best = saved;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
