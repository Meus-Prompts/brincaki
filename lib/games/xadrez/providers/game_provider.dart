// lib/games/xadrez/providers/game_provider.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../widgets/player_setup.dart';
import '../logic/ai.dart';
import '../logic/game.dart';
import '../logic/position.dart';
import '../models/game_state.dart';

typedef XadrezAiRunner =
    Future<ChessMove> Function(ChessPosition position, AiLevel level);

class XadrezProvider extends ChangeNotifier {
  XadrezProvider({
    Random? random,
    this._thinkTime = const Duration(milliseconds: 500),
    XadrezAiRunner? aiRunner,
  }) : _random = random ?? Random() {
    _aiRunner = aiRunner ?? _defaultRunner;
  }

  final Random _random;
  final Duration _thinkTime;
  late final XadrezAiRunner _aiRunner;
  bool _disposed = false;

  /// Muda a cada partida nova: descarta lances do computador atrasados.
  int _gameId = 0;

  XadrezPhase _phase = XadrezPhase.setup;
  PlayMode _mode = PlayMode.twoPlayers;
  String _name1 = '';
  String _name2 = '';
  AiLevel _aiLevel = AiLevel.medium;
  ChessSide _player1Side = ChessSide.white;
  ChessGame _game = ChessGame.start();
  int? _selected;
  (int, int)? _pendingPromotion;
  int _wins1 = 0;
  int _wins2 = 0;
  int _draws = 0;
  bool _aiThinking = false;

  XadrezPhase get phase => _phase;
  PlayMode get mode => _mode;
  String get name1 => _name1;
  String get name2 => _name2;
  AiLevel get aiLevel => _aiLevel;
  ChessSide get player1Side => _player1Side;
  ChessGame get game => _game;
  int get wins1 => _wins1;
  int get wins2 => _wins2;
  int get draws => _draws;
  bool get aiThinking => _aiThinking;
  ChessMove? get lastMove => _game.lastMove;
  (int, int)? get pendingPromotion => _pendingPromotion;

  /// Peça escolhida para mover.
  int? get selected => _selected;

  /// Casas para onde a peça escolhida pode ir (inclui o roque do rei).
  Set<int> get targets {
    final from = _selected;
    if (from == null) return const {};
    return {
      for (final m in _game.legalMoves)
        if (m.from == from) m.to,
    };
  }

  /// Casa do rei de quem tem a vez quando está em xeque (também no mate).
  int? get checkSquare {
    final p = _game.position;
    if (_phase == XadrezPhase.setup || !p.inCheck) return null;
    return p.kingSquare(p.turn);
  }

  bool get isComputerTurn =>
      _mode == PlayMode.solo &&
      _phase == XadrezPhase.playing &&
      _game.position.turn != _player1Side;

  /// A parte de baixo da tela é das pretas (só contra o computador).
  bool get flipped => _mode == PlayMode.solo && _player1Side == ChessSide.black;

  int get currentPlayer => _game.position.turn == _player1Side ? 1 : 2;

  int? get winnerPlayer {
    final w = _game.winner;
    if (w == null) return null;
    return w == _player1Side ? 1 : 2;
  }

  void start(PlayerSetupResult setup) {
    _begin(setup, ChessGame.start());
  }

  @visibleForTesting
  void startFrom(PlayerSetupResult setup, ChessPosition position) {
    _begin(setup, ChessGame.start(position));
  }

  void _begin(PlayerSetupResult setup, ChessGame game) {
    _mode = setup.mode;
    _name1 = setup.player1;
    _name2 = setup.player2;
    _aiLevel = AiLevel.values[setup.levelIndex ?? 1];
    _player1Side = _mode == PlayMode.solo && (setup.sideIndex ?? 0) == 1
        ? ChessSide.black
        : ChessSide.white;
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    _newGame(game);
    notifyListeners();
    _afterMove();
  }

  void tapSquare(int index) {
    if (_phase != XadrezPhase.playing || _aiThinking || isComputerTurn) return;
    if (_pendingPromotion != null) return;
    if (index < 0 || index > 63) return;
    final from = _selected;
    if (from != null) {
      final matching = [
        for (final m in _game.legalMoves)
          if (m.from == from && m.to == index) m,
      ];
      if (matching.length == 1) {
        _apply(matching.single);
        return;
      }
      if (matching.length > 1) {
        // Promoção: espera a escolha da peça.
        _pendingPromotion = (from, index);
        _selected = null;
        notifyListeners();
        return;
      }
    }
    final startsMove = _game.legalMoves.any((m) => m.from == index);
    _selected = startsMove && index != from ? index : null;
    notifyListeners();
  }

  /// Escolhe a peça da promoção pendente (2 cavalo, 3 bispo, 4 torre, 5 dama).
  void promote(int pieceType) {
    final pending = _pendingPromotion;
    if (pending == null || _phase != XadrezPhase.playing) return;
    for (final m in _game.legalMoves) {
      if (m.from == pending.$1 &&
          m.to == pending.$2 &&
          m.promotion == pieceType) {
        _apply(m);
        return;
      }
    }
  }

  void cancelPromotion() {
    if (_pendingPromotion == null) return;
    _pendingPromotion = null;
    _selected = null;
    notifyListeners();
  }

  void playAgain() {
    if (_phase != XadrezPhase.finished) return;
    _newGame(ChessGame.start());
    notifyListeners();
    _afterMove();
  }

  void exitToSetup() {
    _gameId++;
    _phase = XadrezPhase.setup;
    _aiThinking = false;
    _selected = null;
    _pendingPromotion = null;
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    notifyListeners();
  }

  void _apply(ChessMove move) {
    _game = _game.play(move);
    _selected = null;
    _pendingPromotion = null;
    if (_game.end != null) {
      _phase = XadrezPhase.finished;
      _tally();
    }
    notifyListeners();
    _afterMove();
  }

  void _afterMove() {
    if (isComputerTurn) _computerMove();
  }

  Future<void> _computerMove() async {
    final id = _gameId;
    _aiThinking = true;
    notifyListeners();
    await Future<void>.delayed(_thinkTime);
    if (_disposed || id != _gameId) return;
    final position = _game.position;
    final legal = _game.legalMoves;
    ChessMove move;
    try {
      move = await _aiRunner(position, _aiLevel);
      if (!legal.contains(move)) throw StateError('lance ilegal');
    } catch (_) {
      // Nunca deixar o jogo preso em "Pensando...": joga um lance legal.
      move = legal[_random.nextInt(legal.length)];
    }
    if (_disposed || id != _gameId) return;
    _aiThinking = false;
    _apply(move);
  }

  Future<ChessMove> _defaultRunner(
    ChessPosition position,
    AiLevel level,
  ) async {
    final seed = _random.nextInt(1 << 30);
    // Copia antes do await: o histórico é o da posição que está sendo jogada.
    final history = List<String>.of(_game.recentKeys);
    if (level == AiLevel.easy) {
      return chooseMove(position, level, Random(seed), history: history);
    }
    final index = await compute(chooseMoveInIsolate, (
      position.toFen(),
      level.index,
      seed,
      history,
    ));
    return position.legalMoves()[index];
  }

  void _newGame(ChessGame game) {
    _gameId++;
    _game = game;
    _selected = null;
    _pendingPromotion = null;
    _aiThinking = false;
    _phase = game.end != null ? XadrezPhase.finished : XadrezPhase.playing;
    if (game.end != null) _tally();
  }

  /// Soma o resultado da partida terminada no placar.
  void _tally() {
    switch (winnerPlayer) {
      case 1:
        _wins1++;
      case 2:
        _wins2++;
      default:
        _draws++;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
