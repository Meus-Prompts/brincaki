// lib/games/contas/providers/game_provider.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/record_store.dart';
import '../logic/problem.dart';
import '../models/game_state.dart';

class ContasProvider extends ChangeNotifier {
  ContasProvider({
    RecordStore? store,
    Random? random,
    this.inputDelay = const Duration(milliseconds: 300),
  })  : _store = store ?? SharedPrefsRecordStore(),
        _random = random ?? Random() {
    _load();
  }

  static const int maxLives = 3;
  static const int pointsPerHit = 10;

  /// A cada [streakStep] acertos seguidos o multiplicador sobe 1.
  static const int streakStep = 5;
  static const int maxMultiplier = 5;

  /// A maior resposta é 1000.
  static const int maxDigits = 4;
  static const int maxLevel = 3;

  /// Depois de responder ou de tocar em "Continuar", toques nas opções e no
  /// "Continuar" ficam ignorados por esse tempo: um toque duplo não responde
  /// a conta seguinte.
  final Duration inputDelay;

  final RecordStore _store;
  final Random _random;
  bool _disposed = false;

  /// Os recordes salvos já foram lidos. Antes disso (ou se a leitura falhar)
  /// nada é gravado, para não trocar um recorde maior por um menor.
  bool _loaded = false;
  Timer? _inputLock;

  /// A criança mexeu na escolha antes de a última escolha salva chegar.
  bool _touched = false;

  ContasPhase _phase = ContasPhase.setup;
  Operation _operation = Operation.addition;
  int _level = 1;
  AnswerMode _answerMode = AnswerMode.keyboard;
  final Map<(Operation, int), int> _records = {};

  Problem? _problem;
  List<int> _choices = const [];
  String _typed = '';
  int _lives = maxLives;
  int _streak = 0;
  int _bestStreak = 0;
  int _score = 0;
  int _lastPoints = 0;
  int _correctCount = 0;
  bool _isNewRecord = false;
  bool _endedByMistake = false;
  bool _revealedAtEnd = false;

  ContasPhase get phase => _phase;
  Operation get operation => _operation;
  int get level => _level;
  AnswerMode get answerMode => _answerMode;

  /// Conta da vez; `null` na escolha.
  Problem? get problem => _problem;

  /// As 4 opções no modo opções; vazia no teclado.
  List<int> get choices => _choices;

  /// O que foi digitado no teclado.
  String get typed => _typed;
  int get lives => _lives;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  int get score => _score;

  /// Quanto vale o próximo acerto, em múltiplos de [pointsPerHit].
  int get multiplier => min(1 + _streak ~/ streakStep, maxMultiplier);

  /// Pontos do último acerto.
  int get lastPoints => _lastPoints;

  /// Sobe a cada acerto: a tela usa como chave do aviso animado.
  int get correctCount => _correctCount;

  /// A sequência acabou de fechar um múltiplo de [streakStep].
  bool get isMilestone => _streak > 0 && _streak % streakStep == 0;

  int record(Operation op, int level) => _records[(op, level)] ?? 0;
  int get currentRecord => record(_operation, _level);
  bool get isNewRecord => _isNewRecord;

  /// A rodada acabou no 3º erro, e não pelo "Parar".
  bool get endedByMistake => _endedByMistake;

  /// A tela mostra a resposta certa: depois de um erro, e no fim se a rodada
  /// acabou num erro (no 3º ou com "Parar" logo depois de errar).
  bool get answerRevealed =>
      _phase == ContasPhase.mistake ||
      (_phase == ContasPhase.finished && _revealedAtEnd);

  /// Muda a escolha da tela de início; o que não for passado fica igual.
  void select({Operation? operation, int? level, AnswerMode? mode}) {
    if (_phase != ContasPhase.setup) return;
    if (level != null && (level < 1 || level > maxLevel)) return;
    _touched = true;
    _operation = operation ?? _operation;
    _level = level ?? _level;
    _answerMode = mode ?? _answerMode;
    notifyListeners();
  }

  void start() {
    if (_phase != ContasPhase.setup) return;
    _touched = true;
    unawaited(_safely(() =>
        _store.saveLastChoice(LastChoice(_operation, _level, _answerMode))));
    _newRound();
  }

  void typeDigit(int digit) {
    if (!_acceptsKeyboard || digit < 0 || digit > 9) return;
    if (_typed == '0') {
      _typed = '$digit';
    } else if (_typed.length < maxDigits) {
      _typed += '$digit';
    } else {
      return;
    }
    notifyListeners();
  }

  void deleteDigit() {
    if (!_acceptsKeyboard || _typed.isEmpty) return;
    _typed = _typed.substring(0, _typed.length - 1);
    notifyListeners();
  }

  void submit() {
    if (!_acceptsKeyboard || _typed.isEmpty) return;
    _answer(int.parse(_typed));
  }

  void choose(int value) {
    if (_inputLocked ||
        _phase != ContasPhase.playing ||
        _answerMode != AnswerMode.choices ||
        !_choices.contains(value)) {
      return;
    }
    _answer(value);
  }

  void continueAfterMistake() {
    if (_phase != ContasPhase.mistake || _inputLocked) return;
    _lockInput();
    _phase = ContasPhase.playing;
    _nextProblem();
    notifyListeners();
  }

  /// "Parar": termina a rodada e os pontos contam para o recorde.
  void stop() {
    if (_phase != ContasPhase.playing && _phase != ContasPhase.mistake) return;
    _finish(byMistake: false);
    notifyListeners();
  }

  void playAgain() {
    if (_phase != ContasPhase.finished) return;
    _newRound();
  }

  /// "Mudar nível": volta para a tela de início.
  void exitToSetup() {
    if (_phase != ContasPhase.finished) return;
    _phase = ContasPhase.setup;
    _problem = null;
    _choices = const [];
    _typed = '';
    notifyListeners();
  }

  bool get _acceptsKeyboard =>
      _phase == ContasPhase.playing && _answerMode == AnswerMode.keyboard;

  bool get _inputLocked => _inputLock?.isActive ?? false;

  void _lockInput() {
    if (inputDelay == Duration.zero) return;
    _inputLock?.cancel();
    _inputLock = Timer(inputDelay, () {});
  }

  void _answer(int value) {
    _lockInput();
    if (value == _problem!.answer) {
      _lastPoints = pointsPerHit * multiplier;
      _score += _lastPoints;
      _streak++;
      _bestStreak = max(_bestStreak, _streak);
      _correctCount++;
      _nextProblem();
    } else {
      _lives--;
      _streak = 0;
      if (_lives == 0) {
        _finish(byMistake: true);
      } else {
        _phase = ContasPhase.mistake;
      }
    }
    notifyListeners();
  }

  void _newRound() {
    _lives = maxLives;
    _streak = 0;
    _bestStreak = 0;
    _score = 0;
    _lastPoints = 0;
    _correctCount = 0;
    _isNewRecord = false;
    _endedByMistake = false;
    _phase = ContasPhase.playing;
    _nextProblem();
    notifyListeners();
  }

  void _nextProblem() {
    _problem = generateProblem(_operation, _level, _random, avoid: _problem);
    _choices = _answerMode == AnswerMode.choices
        ? generateChoices(_problem!, _random)
        : const [];
    _typed = '';
  }

  void _finish({required bool byMistake}) {
    _revealedAtEnd = byMistake || _phase == ContasPhase.mistake;
    _phase = ContasPhase.finished;
    _endedByMistake = byMistake;
    _isNewRecord = _score > currentRecord;
    if (_isNewRecord) {
      _records[(_operation, _level)] = _score;
      if (_loaded) _saveRecord(_operation, _level, _score);
    }
  }

  void _saveRecord(Operation op, int level, int score) =>
      unawaited(_safely(() => _store.saveRecord(op, level, score)));

  /// Falha ao salvar não atrapalha o jogo.
  Future<void> _safely(Future<void> Function() save) async {
    try {
      await save();
    } catch (_) {}
  }

  /// Lê os recordes e a última escolha. Se a leitura falhar, segue com zeros.
  Future<void> _load() async {
    final Map<(Operation, int), int> saved = {};
    final LastChoice? last;
    try {
      for (final op in Operation.values) {
        for (var level = 1; level <= maxLevel; level++) {
          saved[(op, level)] = await _store.loadRecord(op, level);
        }
      }
      last = await _store.loadLastChoice();
    } catch (_) {
      return;
    }
    if (_disposed) return;
    // Um recorde feito enquanto carregava vale mais que o salvo, se for maior,
    // e só agora é gravado.
    _loaded = true;
    for (final MapEntry(:key, :value) in saved.entries) {
      final inSession = _records[key] ?? 0;
      if (inSession > value) {
        _saveRecord(key.$1, key.$2, inSession);
      } else {
        _records[key] = value;
      }
    }
    if (last != null && !_touched) {
      _operation = last.operation;
      _level = last.level;
      _answerMode = last.mode;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _inputLock?.cancel();
    super.dispose();
  }
}
