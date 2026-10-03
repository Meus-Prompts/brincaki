// lib/games/cacapalavras/providers/game_provider.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/levels.dart';
import '../models/game_state.dart';
import '../services/grid_generator.dart';
import '../services/selection.dart';

class WordSearchProvider extends ChangeNotifier {
  WordSearchProvider({Random? random}) : _random = random ?? Random() {
    _generate();
  }

  final Random _random;

  int _level = 1;
  late List<List<String>> _grid;
  late List<PlacedWord> _words;
  final Set<String> _found = {};
  (int, int)? _selectionStart;
  (int, int)? _selectionEnd;
  WordSearchPhase _phase = WordSearchPhase.playing;

  int get level => _level;
  LevelConfig get config => kLevels[_level - 1];
  bool get isLastLevel => _level == kLevels.length;
  List<List<String>> get grid => _grid;
  List<PlacedWord> get words => List.unmodifiable(_words);
  Set<String> get found => Set.unmodifiable(_found);
  WordSearchPhase get phase => _phase;

  List<(int, int)> get selectedCells {
    final start = _selectionStart;
    final end = _selectionEnd;
    if (start == null || end == null) return const [];
    return snapLine(start, end, config.size);
  }

  void startSelection(int row, int col) {
    if (_phase != WordSearchPhase.playing) return;
    _selectionStart = (row, col);
    _selectionEnd = (row, col);
    notifyListeners();
  }

  void updateSelection(int row, int col) {
    if (_selectionStart == null || _selectionEnd == (row, col)) return;
    _selectionEnd = (row, col);
    notifyListeners();
  }

  void endSelection() {
    final cells = selectedCells;
    _selectionStart = null;
    _selectionEnd = null;

    for (final w in _words) {
      if (_found.contains(w.word)) continue;
      if (listEquals(cells, w.cells) ||
          listEquals(cells, w.cells.reversed.toList())) {
        _found.add(w.word);
        if (_found.length == _words.length) _phase = WordSearchPhase.won;
        break;
      }
    }
    notifyListeners();
  }

  /// Vai para o próximo nível (depois do 10, volta ao 1).
  void nextLevel() {
    if (_phase != WordSearchPhase.won) return;
    _level = isLastLevel ? 1 : _level + 1;
    _generate();
    notifyListeners();
  }

  void _generate() {
    final level = config;
    final generated = generateGrid(
      candidates: level.words,
      wordCount: level.wordCount,
      size: level.size,
      directions: level.directions,
      random: _random,
    );
    _grid = generated.letters;
    _words = generated.words;
    _found.clear();
    _selectionStart = null;
    _selectionEnd = null;
    _phase = WordSearchPhase.playing;
  }
}
