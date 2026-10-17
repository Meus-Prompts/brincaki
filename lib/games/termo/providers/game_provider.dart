// lib/games/termo/providers/game_provider.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/daily_store.dart';
import '../data/word_bank.dart';
import '../logic/daily.dart';
import '../logic/evaluate.dart';
import '../logic/normalize.dart';
import '../models/game_state.dart';

class TermoProvider extends ChangeNotifier {
  TermoProvider({
    Future<WordBank>? bank,
    DailyStore? store,
    DateTime Function()? now,
    Random? random,
  })  : _store = store ?? SharedPrefsDailyStore(),
        _now = now ?? DateTime.now,
        _random = random ?? Random() {
    _init(bank ?? WordBank.load(rootBundle));
  }

  static const int wordLength = 5;
  static const int maxGuesses = 6;
  static final _letter = RegExp(r'^[A-Z]$');

  final DailyStore _store;
  final DateTime Function() _now;
  final Random _random;
  WordBank? _bank;
  bool _disposed = false;

  bool _loading = true;
  TermoMode _mode = TermoMode.daily;
  String _answer = '';
  String _dailyDate = '';
  final List<String> _guesses = [];
  String _current = '';
  TermoPhase _phase = TermoPhase.playing;
  String? _lastError;
  int _shakeCount = 0;

  bool get loading => _loading;
  TermoMode get mode => _mode;
  String get answer => _answer;
  String get answerDisplay => display(_answer);
  List<String> get guesses => List.unmodifiable(_guesses);
  String get current => _current;
  TermoPhase get phase => _phase;
  String? get lastError => _lastError;
  int get shakeCount => _shakeCount;

  /// Melhor resultado de cada letra já usada (verde > amarelo > cinza).
  Map<String, LetterResult> get keyboard {
    final best = <String, LetterResult>{};
    for (final guess in _guesses) {
      final results = evaluateGuess(guess, _answer);
      for (var i = 0; i < guess.length; i++) {
        final previous = best[guess[i]];
        if (previous == null || results[i].index < previous.index) {
          best[guess[i]] = results[i];
        }
      }
    }
    return best;
  }

  String display(String normal) => _bank?.display(normal) ?? normal;

  /// Como uma tentativa aparece na grade: letra verde copia a resposta, para
  /// não mostrar um acento que a palavra do dia não tem.
  String shown(String guess) {
    final letters = display(guess).split('');
    final answer = answerDisplay;
    final results = resultsFor(guess);
    for (var i = 0; i < letters.length; i++) {
      if (results[i] == LetterResult.correct) letters[i] = answer[i];
    }
    return letters.join();
  }

  List<LetterResult> resultsFor(String guess) => evaluateGuess(guess, _answer);

  void type(String letter) {
    if (_loading || _phase != TermoPhase.playing) return;
    if (_current.length >= wordLength) return;
    final normal = normalizeWord(letter);
    if (!_letter.hasMatch(normal)) return;
    _current += normal;
    _lastError = null;
    notifyListeners();
  }

  void backspace() {
    if (_loading || _phase != TermoPhase.playing || _current.isEmpty) return;
    _current = _current.substring(0, _current.length - 1);
    notifyListeners();
  }

  void submit() {
    if (_loading || _phase != TermoPhase.playing) return;
    if (_current.length < wordLength) {
      _error('Só palavras com 5 letras');
      return;
    }
    if (!_bank!.isValid(_current)) {
      _error('Palavra inválida');
      return;
    }
    _guesses.add(_current);
    _current = '';
    _lastError = null;
    _updatePhase();
    if (_mode == TermoMode.daily) {
      unawaited(_store.save(
          DailyState(date: _dailyDate, guesses: List.of(_guesses))));
    }
    notifyListeners();
  }

  Future<void> setMode(TermoMode mode) async {
    if (_loading || mode == _mode) return;
    if (mode == TermoMode.unlimited) {
      _mode = TermoMode.unlimited;
      _newUnlimitedWord();
      notifyListeners();
    } else {
      _loading = true;
      notifyListeners();
      await _startDaily();
    }
  }

  /// Nova palavra no modo ilimitado, depois de terminar a atual.
  void newUnlimited() {
    if (_mode != TermoMode.unlimited || _phase == TermoPhase.playing) return;
    _newUnlimitedWord();
    notifyListeners();
  }

  Future<void> _init(Future<WordBank> bank) async {
    _bank = await bank;
    if (_disposed) return;
    await _startDaily();
  }

  Future<void> _startDaily() async {
    final now = _now();
    _mode = TermoMode.daily;
    _dailyDate = dateKey(now);
    _answer = dailyAnswer(_bank!, now);
    _guesses.clear();
    _current = '';
    _lastError = null;

    final saved = await _store.load();
    if (_disposed) return;
    if (saved != null && saved.date == _dailyDate) {
      _guesses.addAll(saved.guesses.where(_bank!.isValid).take(maxGuesses));
    }
    _updatePhase();
    _loading = false;
    notifyListeners();
  }

  void _newUnlimitedWord() {
    final answers = _bank!.answers;
    _answer = answers[_random.nextInt(answers.length)];
    _guesses.clear();
    _current = '';
    _lastError = null;
    _phase = TermoPhase.playing;
  }

  void _updatePhase() {
    if (_guesses.contains(_answer)) {
      _phase = TermoPhase.won;
    } else if (_guesses.length >= maxGuesses) {
      _phase = TermoPhase.lost;
    } else {
      _phase = TermoPhase.playing;
    }
  }

  void _error(String message) {
    _lastError = message;
    _shakeCount++;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
