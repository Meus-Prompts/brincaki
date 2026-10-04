// lib/games/memoria/providers/game_provider.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../widgets/player_setup.dart';
import '../data/emojis.dart';
import '../data/levels.dart';
import '../models/game_state.dart';

class MemoryProvider extends ChangeNotifier {
  MemoryProvider({Random? random}) : _random = random ?? Random();

  final Random _random;

  MemoryPhase _phase = MemoryPhase.setup;
  PlayMode _mode = PlayMode.solo;
  String _name1 = '';
  String _name2 = '';
  int _level = 1;
  String _duoSize = 'Média';
  List<MemoryCard> _cards = const [];
  int _currentPlayer = 1;
  int _startingPlayer = 1;
  int _pairs1 = 0;
  int _pairs2 = 0;
  int _moves = 0;
  int _wins1 = 0;
  int _wins2 = 0;
  int _draws = 0;
  bool _waitingToHide = false;

  /// Muda a cada grade nova: a tela recria as cartas (sem reaproveitar a
  /// animação da grade anterior, que mostraria as figuras novas).
  int _dealId = 0;

  /// Cartas viradas na jogada atual que ainda não formaram par.
  final List<int> _open = [];

  MemoryPhase get phase => _phase;
  PlayMode get mode => _mode;
  String get name1 => _name1;
  String get name2 => _name2;
  int get level => _level;
  String get duoSize => _duoSize;
  MemoryGrid get grid =>
      _mode == PlayMode.solo ? kSoloLevels[_level - 1] : kDuoSizes[_duoSize]!;
  bool get isLastLevel => _level == kSoloLevels.length;
  List<MemoryCard> get cards => List.unmodifiable(_cards);
  int get currentPlayer => _currentPlayer;
  int get pairs1 => _pairs1;
  int get pairs2 => _pairs2;
  int get moves => _moves;
  int get wins1 => _wins1;
  int get wins2 => _wins2;
  int get draws => _draws;
  bool get waitingToHide => _waitingToHide;
  int get dealId => _dealId;

  /// Nenhuma carta virada nesta partida (ainda dá para trocar o tamanho).
  bool get untouched => _moves == 0 && _open.isEmpty;

  /// Vencedor da partida em dois jogadores (null = empate ou ainda jogando).
  int? get winner {
    if (_phase != MemoryPhase.finished || _mode != PlayMode.twoPlayers) return null;
    if (_pairs1 == _pairs2) return null;
    return _pairs1 > _pairs2 ? 1 : 2;
  }

  void start(PlayerSetupResult setup) {
    _mode = setup.mode;
    _name1 = setup.player1;
    _name2 = setup.player2;
    _level = 1;
    _duoSize = 'Média';
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    _startingPlayer = 1;
    _deal();
    notifyListeners();
  }

  /// Troca o tamanho da grade em dois jogadores, antes da primeira jogada.
  void setDuoSize(String size) {
    if (_mode != PlayMode.twoPlayers ||
        _phase != MemoryPhase.playing ||
        !untouched ||
        !kDuoSizes.containsKey(size)) {
      return;
    }
    _duoSize = size;
    _deal();
    notifyListeners();
  }

  void flip(int id) {
    if (_phase != MemoryPhase.playing || _waitingToHide) return;
    if (id < 0 || id >= _cards.length) return;
    final card = _cards[id];
    if (card.faceUp || card.matched) return;

    _cards = [..._cards];
    _cards[id] = card.copyWith(faceUp: true);
    _open.add(id);

    if (_open.length == 2) {
      _moves++;
      final a = _cards[_open[0]];
      final b = _cards[_open[1]];
      if (a.emoji == b.emoji) {
        _cards[a.id] = a.copyWith(matched: true);
        _cards[b.id] = b.copyWith(matched: true);
        _open.clear();
        if (_currentPlayer == 1) {
          _pairs1++;
        } else {
          _pairs2++;
        }
        if (_cards.every((c) => c.matched)) _finish();
      } else {
        _waitingToHide = true;
      }
    }
    notifyListeners();
  }

  /// Desvira as duas cartas erradas; em dois jogadores, passa a vez.
  void hideMismatched() {
    if (!_waitingToHide) return;
    _cards = [..._cards];
    for (final id in _open) {
      _cards[id] = _cards[id].copyWith(faceUp: false);
    }
    _open.clear();
    _waitingToHide = false;
    if (_mode == PlayMode.twoPlayers) _currentPlayer = 3 - _currentPlayer;
    notifyListeners();
  }

  void nextLevel() {
    if (_mode != PlayMode.solo || _phase != MemoryPhase.finished) return;
    _level = isLastLevel ? 1 : _level + 1;
    _deal();
    notifyListeners();
  }

  void playAgain() {
    if (_mode != PlayMode.twoPlayers || _phase != MemoryPhase.finished) return;
    _startingPlayer = 3 - _startingPlayer;
    _deal();
    notifyListeners();
  }

  void exitToSetup() {
    _phase = MemoryPhase.setup;
    _cards = const [];
    _open.clear();
    _waitingToHide = false;
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    notifyListeners();
  }

  void _finish() {
    _phase = MemoryPhase.finished;
    if (_mode != PlayMode.twoPlayers) return;
    if (_pairs1 > _pairs2) {
      _wins1++;
    } else if (_pairs2 > _pairs1) {
      _wins2++;
    } else {
      _draws++;
    }
  }

  void _deal() {
    final pairs = grid.pairs;
    final emojis = ([...kMemoryEmojis]..shuffle(_random)).take(pairs).toList();
    final faces = [...emojis, ...emojis]..shuffle(_random);
    _cards = [
      for (var i = 0; i < faces.length; i++) MemoryCard(id: i, emoji: faces[i]),
    ];
    _open.clear();
    _waitingToHide = false;
    _pairs1 = 0;
    _pairs2 = 0;
    _moves = 0;
    _currentPlayer = _startingPlayer;
    _phase = MemoryPhase.playing;
    _dealId++;
  }
}
