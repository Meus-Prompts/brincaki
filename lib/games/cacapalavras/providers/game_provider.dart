// lib/games/cacapalavras/providers/game_provider.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/levels.dart';
import '../models/game_state.dart';
import '../services/grid_generator.dart';
import '../services/selection.dart';

class WordSearchProvider extends ChangeNotifier {
  /// [random] só para testes: deixa a grade previsível.
  WordSearchProvider({Random? random}) : _random = random ?? Random();

  final Random _random;

  int _level = 1;
  List<List<String>> _grid = const [];
  List<PlacedWord> _words = const [];
  final Set<String> _found = {};
  (int, int)? _selectionStart;
  (int, int)? _selectionEnd;
  WordSearchPhase _phase = WordSearchPhase.setup;

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

  /// Começa uma partida no nível [level] (de 1 a 10), saindo da tela de início.
  void start(int level) {
    if (_phase != WordSearchPhase.setup) return;
    if (level < 1 || level > kLevels.length) return;
    _level = level;
    _generate();
    notifyListeners();
  }

  /// Volta para a tela de início, onde dá para escolher outro nível.
  void exitToSetup() {
    if (_phase == WordSearchPhase.setup) return;
    _phase = WordSearchPhase.setup;
    _grid = const [];
    _words = const [];
    _found.clear();
    _selectionStart = null;
    _selectionEnd = null;
    notifyListeners();
  }

  void startSelection(int row, int col) {
    if (_phase != WordSearchPhase.playing) return;
    _selectionStart = (row, col);
    _selectionEnd = (row, col);
    notifyListeners();
  }

  void updateSelection(int row, int col) {
    if (_phase != WordSearchPhase.playing) return;
    if (_selectionStart == null || _selectionEnd == (row, col)) return;
    _selectionEnd = (row, col);
    notifyListeners();
  }

  void endSelection() {
    if (_phase != WordSearchPhase.playing || _selectionStart == null) return;
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
