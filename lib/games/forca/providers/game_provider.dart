// lib/games/forca/providers/game_provider.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../data/word_list.dart';

class ForcaProvider extends ChangeNotifier {
  static const int _maxErrors = 6;
  static const int _maxLevel = 7;

  int _level = 1;
  late String _currentWord;
  final Map<String, LetterState> _letterStates = {};
  final Set<String> _usedWords = {};
  ForcaPhase _phase = ForcaPhase.playing;

  ForcaProvider() {
    _pickWord();
  }

  int get level => _level;
  String get currentWord => _currentWord;
  ForcaPhase get phase => _phase;
  Map<String, LetterState> get letterStates => Map.unmodifiable(_letterStates);

  int get wrongCount =>
      _letterStates.values.where((s) => s == LetterState.wrong).length;

  /// Palavra revelada: letras acertadas no lugar, '_' para as demais.
  String get revealedWord => _currentWord
      .split('')
      .map((l) => _letterStates[l] == LetterState.correct ? l : '_')
      .join(' ');

  void guessLetter(String letter) {
    if (_phase != ForcaPhase.playing) return;
    if (_letterStates.containsKey(letter)) return;

    if (_currentWord.contains(letter)) {
      _letterStates[letter] = LetterState.correct;
      if (_isWordComplete()) {
        _phase = ForcaPhase.won;
      }
    } else {
      _letterStates[letter] = LetterState.wrong;
      if (wrongCount >= _maxErrors) {
        _phase = ForcaPhase.lost;
      }
    }
    notifyListeners();
  }

  /// Avança para a próxima palavra (chamado após vitória).
  void nextWord() {
    if (_level < _maxLevel) _level++;
    _letterStates.clear();
    _phase = ForcaPhase.playing;
    _pickWord();
    notifyListeners();
  }

  /// Reseta para o nível 1 (chamado após derrota).
  void retry() {
    _level = 1;
    _letterStates.clear();
    _usedWords.clear();
    _phase = ForcaPhase.playing;
    _pickWord();
    notifyListeners();
  }

  void _pickWord() {
    final words = kWordsByLevel[_level]!;
    final available = words.where((w) => !_usedWords.contains(w)).toList();
    // Se esgotou as palavras do nível, reseta as usadas
    final pool = available.isEmpty ? words : available;
    if (available.isEmpty) _usedWords.removeWhere((w) => words.contains(w));
    _currentWord = pool[Random().nextInt(pool.length)];
    _usedWords.add(_currentWord);
  }

  bool _isWordComplete() {
    return _currentWord.split('').every(
          (l) => _letterStates[l] == LetterState.correct,
        );
  }
}
