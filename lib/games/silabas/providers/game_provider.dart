// lib/games/silabas/providers/game_provider.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/word_list.dart';
import '../logic/word.dart';
import '../models/game_state.dart';

class SilabasProvider extends ChangeNotifier {
  static const int wordsPerGame = 10;
  static const List<String> levelNames = ['Fácil', 'Médio', 'Difícil'];

  SilabasProvider({Random? random, Map<int, List<String>>? words})
    : _random = random ?? Random(),
      _wordsByLevel = words ?? kSilabasWordsByLevel;

  final Random _random;
  final Map<int, List<String>> _wordsByLevel;

  SilabasPhase _phase = SilabasPhase.setup;
  int _level = 0;
  List<SilabasWord> _words = [];
  int _index = 0;
  SilabasStep _step = SilabasStep.split;
  int _score = 0;
  int _wordPoints = 0;
  int _errors = 0;
  final Set<int> _cuts = {};
  final Set<int> _wrongCuts = {};
  int? _missingHint;
  final Set<int> _wrongStress = {};
  final Set<StressClass> _wrongClasses = {};

  SilabasPhase get phase => _phase;
  int get level => _level;
  int get index => _index;

  /// Quantas palavras tem esta partida (10, salvo listas menores injetadas).
  int get wordCount => _words.length;

  /// Palavra atual (null na escolha de nível).
  SilabasWord? get word =>
      _phase == SilabasPhase.setup || _words.isEmpty ? null : _words[_index];
  SilabasStep get step => _step;
  int get score => _score;
  int get wordPoints => _wordPoints;
  Set<int> get cuts => Set.unmodifiable(_cuts);
  Set<int> get wrongCuts => Set.unmodifiable(_wrongCuts);

  /// Total de sílabas, quando a conferência achou que falta corte.
  int? get missingHint => _missingHint;
  Set<int> get wrongStress => Set.unmodifiable(_wrongStress);
  Set<StressClass> get wrongClasses => Set.unmodifiable(_wrongClasses);
  bool get isLastWord => _index == _words.length - 1;

  int get stars => _score >= 270 ? 3 : (_score >= 180 ? 2 : 1);

  void start(int level) {
    if (_phase != SilabasPhase.setup) return;
    if (level < 0 || level >= levelNames.length) return;
    if (_wordsByLevel[level]?.isEmpty ?? true) return;
    _level = level;
    _newGame();
  }

  void toggleCut(int pos) {
    if (_phase != SilabasPhase.playing || _step != SilabasStep.split) return;
    if (pos < 1 || pos > word!.text.length - 1) return;
    if (!_cuts.remove(pos)) _cuts.add(pos);
    _wrongCuts.clear();
    _missingHint = null;
    notifyListeners();
  }

  void checkSplit() {
    if (_phase != SilabasPhase.playing || _step != SilabasStep.split) return;
    if (_cuts.isEmpty) return;
    final correct = word!.cutPositions;
    final wrong = _cuts.difference(correct);
    final missing = correct.difference(_cuts);
    if (wrong.isEmpty && missing.isEmpty) {
      _wrongCuts.clear();
      _missingHint = null;
      _finishStep(SilabasStep.stress);
    } else {
      _errors++;
      _wrongCuts
        ..clear()
        ..addAll(wrong);
      _missingHint = missing.isEmpty ? null : word!.syllables.length;
    }
    notifyListeners();
  }

  void chooseStress(int i) {
    if (_phase != SilabasPhase.playing || _step != SilabasStep.stress) return;
    if (i < 0 || i >= word!.syllables.length) return;
    if (_wrongStress.contains(i)) return;
    if (i == word!.stressIndex) {
      _finishStep(SilabasStep.classify);
    } else {
      _wrongStress.add(i);
      _errors++;
    }
    notifyListeners();
  }

  void chooseClass(StressClass c) {
    if (_phase != SilabasPhase.playing || _step != SilabasStep.classify) return;
    if (_wrongClasses.contains(c)) return;
    if (c == word!.stressClass) {
      _finishStep(SilabasStep.solved);
    } else {
      _wrongClasses.add(c);
      _errors++;
    }
    notifyListeners();
  }

  void nextWord() {
    if (_phase != SilabasPhase.playing || _step != SilabasStep.solved) return;
    if (isLastWord) {
      _phase = SilabasPhase.finished;
    } else {
      _index++;
      _resetWord();
    }
    notifyListeners();
  }

  /// Nova partida no mesmo nível.
  void playAgain() {
    if (_phase != SilabasPhase.finished) return;
    _newGame();
  }

  /// Volta para a escolha de nível ("Mudar nível").
  void exitToSetup() {
    if (_phase == SilabasPhase.setup) return;
    _words = [];
    _index = 0;
    _score = 0;
    _resetWord();
    _phase = SilabasPhase.setup;
    notifyListeners();
  }

  void _finishStep(SilabasStep next) {
    final points = _errors == 0 ? 10 : (_errors == 1 ? 5 : 2);
    _score += points;
    _wordPoints += points;
    _errors = 0;
    _step = next;
  }

  void _newGame() {
    final pool = List<String>.of(_wordsByLevel[_level]!)..shuffle(_random);
    _words = pool.take(wordsPerGame).map(parseWord).toList();
    _index = 0;
    _score = 0;
    _resetWord();
    _phase = SilabasPhase.playing;
    notifyListeners();
  }

  void _resetWord() {
    _step = SilabasStep.split;
    _wordPoints = 0;
    _errors = 0;
    _cuts.clear();
    _wrongCuts.clear();
    _missingHint = null;
    _wrongStress.clear();
    _wrongClasses.clear();
  }
}
