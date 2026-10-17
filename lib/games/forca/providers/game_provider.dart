// lib/games/forca/providers/game_provider.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../data/word_list.dart';

class ForcaProvider extends ChangeNotifier {
  static const int maxErrors = 6;
  static const int maxLevel = 7;

  /// Letras do teclado: só A–Z, as palavras não têm acento.
  static const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  static const Map<String, String> _accents = {
    'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
    'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
    'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
    'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
    'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
    'Ç': 'C',
  };

  ForcaProvider({Random? random}) : _random = random ?? Random();

  final Random _random;
  int _level = 1;
  String _currentWord = '';
  final Map<String, LetterState> _letterStates = {};
  final Set<String> _usedWords = {};
  ForcaPhase _phase = ForcaPhase.setup;

  int get level => _level;

  /// Palavra da partida ('' na escolha de nível).
  String get currentWord => _currentWord;
  ForcaPhase get phase => _phase;
  Map<String, LetterState> get letterStates => Map.unmodifiable(_letterStates);

  /// No último nível, vencer não avança mais.
  bool get isLastLevel => _level == maxLevel;

  int get wrongCount =>
      _letterStates.values.where((s) => s == LetterState.wrong).length;

  /// Letras da palavra que já foram acertadas.
  Set<String> get correctLetters => {
        for (final e in _letterStates.entries)
          if (e.value == LetterState.correct) e.key,
      };

  /// Palavra revelada: letras acertadas no lugar, '_' para as demais.
  String get revealedWord => _currentWord
      .split('')
      .map((l) => _letterStates[l] == LetterState.correct ? l : '_')
      .join(' ');

  /// Começa a partida no [level] escolhido (1 a [maxLevel]).
  void start(int level) {
    if (_phase != ForcaPhase.setup) return;
    if (level < 1 || level > maxLevel) return;
    _level = level;
    _newWord();
  }

  /// Aceita minúsculas e letras com acento ('á' vale 'A'); o resto é ignorado.
  void guessLetter(String letter) {
    if (_phase != ForcaPhase.playing) return;
    final upper = letter.toUpperCase();
    final normalized = _accents[upper] ?? upper;
    if (normalized.length != 1 || !alphabet.contains(normalized)) return;
    if (_letterStates.containsKey(normalized)) return;

    if (_currentWord.contains(normalized)) {
      _letterStates[normalized] = LetterState.correct;
      if (_isWordComplete()) {
        _phase = ForcaPhase.won;
      }
    } else {
      _letterStates[normalized] = LetterState.wrong;
      if (wrongCount >= maxErrors) {
        _phase = ForcaPhase.lost;
      }
    }
    notifyListeners();
  }

  /// Avança para a próxima palavra (chamado após vitória). No último nível,
  /// continua nele.
  void nextWord() {
    if (_phase != ForcaPhase.won) return;
    if (_level < maxLevel) _level++;
    _newWord();
  }

  /// Nova palavra no mesmo nível (chamado após derrota).
  void retry() {
    if (_phase != ForcaPhase.lost) return;
    _newWord();
  }

  /// Volta para a escolha de nível ("Mudar nível").
  void exitToSetup() {
    if (_phase == ForcaPhase.setup) return;
    _letterStates.clear();
    _currentWord = '';
    _phase = ForcaPhase.setup;
    notifyListeners();
  }

  void _newWord() {
    _letterStates.clear();
    _pickWord();
    _phase = ForcaPhase.playing;
    notifyListeners();
  }

  /// Sorteia uma palavra do nível que ainda não saiu. Quando todas já
  /// saíram, recomeça, mas sem repetir a palavra que acabou de sair.
  void _pickWord() {
    final words = kWordsByLevel[_level]!;
    var pool = words.where((w) => !_usedWords.contains(w)).toList();
    if (pool.isEmpty) {
      _usedWords.removeAll(words);
      pool = words.where((w) => w != _currentWord).toList();
    }
    _currentWord = pool[_random.nextInt(pool.length)];
    _usedWords.add(_currentWord);
  }

  bool _isWordComplete() {
    return _currentWord.split('').every(
          (l) => _letterStates[l] == LetterState.correct,
        );
  }
}
