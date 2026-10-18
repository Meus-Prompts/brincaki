// lib/games/damas/providers/game_provider.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../widgets/player_setup.dart';
import '../logic/ai.dart';
import '../logic/board.dart';
import '../logic/game.dart';
import '../models/game_state.dart';

typedef DamasAiRunner =
    Future<DamasMove> Function(DamasPosition position, AiLevel level);

class DamasProvider extends ChangeNotifier {
  DamasProvider({
    Random? random,
    this._thinkTime = const Duration(milliseconds: 500),
    DamasAiRunner? aiRunner,
  }) : _random = random ?? Random() {
    _aiRunner = aiRunner ?? _defaultRunner;
  }

  final Random _random;
  final Duration _thinkTime;
  late final DamasAiRunner _aiRunner;
  bool _disposed = false;

  /// Muda a cada partida nova: descarta lances do computador atrasados.
  int _gameId = 0;

  DamasPhase _phase = DamasPhase.setup;
  PlayMode _mode = PlayMode.twoPlayers;
  String _name1 = '';
  String _name2 = '';
  AiLevel _aiLevel = AiLevel.medium;
  DamasSide _player1Side = DamasSide.white;
  DamasGame _game = DamasGame.start();
  List<int> _partialPath = const [];
  int _wins1 = 0;
  int _wins2 = 0;
  int _draws = 0;
  bool _aiThinking = false;

  DamasPhase get phase => _phase;
  PlayMode get mode => _mode;
  String get name1 => _name1;
  String get name2 => _name2;
  AiLevel get aiLevel => _aiLevel;
  DamasSide get player1Side => _player1Side;
  DamasGame get game => _game;
  int get wins1 => _wins1;
  int get wins2 => _wins2;
  int get draws => _draws;
  bool get aiThinking => _aiThinking;
  DamasMove? get lastMove => _game.lastMove;

  /// Peça escolhida para mover (início do caminho parcial).
  int? get selected => _partialPath.isEmpty ? null : _partialPath.first;

  /// Casas por onde o lance escolhido já passou (começa na peça).
  List<int> get partialPath => List.unmodifiable(_partialPath);

  /// Próximas casas possíveis para o lance em andamento.
  Set<int> get targets {
    final n = _partialPath.length;
    return {
      for (final m in _matching())
        if (m.path.length > n) m.path[n],
    };
  }

  /// Peças já capturadas no lance em andamento.
  Set<int> get capturedSoFar {
    final n = _partialPath.length - 1;
    if (n <= 0) return const {};
    final matches = _matching();
    if (matches.isEmpty) return const {};
    return matches.first.captured.take(n).toSet();
  }

  /// Casas de peças que podem capturar quando a captura é obrigatória.
  Set<int> get mustCapture {
    if (_phase != DamasPhase.playing) return const {};
    final moves = _game.legalMoves;
    if (moves.isEmpty || !moves.first.isCapture) return const {};
    return {for (final m in moves) m.from};
  }

  bool get isComputerTurn =>
      _mode == PlayMode.solo &&
      _phase == DamasPhase.playing &&
      _game.position.turn != _player1Side;

  /// A parte de baixo da tela é das pretas (só contra o computador).
  bool get flipped => _mode == PlayMode.solo && _player1Side == DamasSide.black;

  int get currentPlayer => _game.position.turn == _player1Side ? 1 : 2;

  int? get winnerPlayer {
    final w = _game.winner;
    if (w == null) return null;
    return w == _player1Side ? 1 : 2;
  }

  void start(PlayerSetupResult setup) {
    _begin(setup, DamasGame.start());
  }

  @visibleForTesting
  void startFrom(PlayerSetupResult setup, DamasPosition position) {
    _begin(setup, DamasGame.start(position));
  }

  void _begin(PlayerSetupResult setup, DamasGame game) {
    _mode = setup.mode;
    _name1 = setup.player1;
    _name2 = setup.player2;
    _aiLevel = AiLevel.values[setup.levelIndex ?? 1];
    _player1Side = _mode == PlayMode.solo && (setup.sideIndex ?? 0) == 1
        ? DamasSide.black
        : DamasSide.white;
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    _newGame(game);
    notifyListeners();
    _afterMove();
  }

  void tapSquare(int index) {
    if (_phase != DamasPhase.playing || _aiThinking || isComputerTurn) return;
    if (index < 0 || index > 63) return;
    final moves = _game.legalMoves;
    if (_partialPath.length >= 2) {
      if (targets.contains(index)) _extend(index);
      return;
    }
    if (_partialPath.length == 1 && targets.contains(index)) {
      _extend(index);
      return;
    }
    final startsMove = moves.any((m) => m.from == index);
    _partialPath = startsMove && index != selected ? [index] : const [];
    notifyListeners();
  }

  void playAgain() {
    if (_phase != DamasPhase.finished) return;
    _newGame(DamasGame.start());
    notifyListeners();
    _afterMove();
  }

  void exitToSetup() {
    _gameId++;
    _phase = DamasPhase.setup;
    _aiThinking = false;
    _partialPath = const [];
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    notifyListeners();
  }

  List<DamasMove> _matching() {
    if (_partialPath.isEmpty) return const [];
    final n = _partialPath.length;
    return [
      for (final m in _game.legalMoves)
        if (m.path.length >= n &&
            listEquals(m.path.sublist(0, n), _partialPath))
          m,
    ];
  }

  void _extend(int index) {
    _partialPath = [..._partialPath, index];
    final done = _game.legalMoves.where(
      (m) => listEquals(m.path, _partialPath),
    );
    if (done.isNotEmpty) {
      _apply(done.first);
    } else {
      notifyListeners();
    }
  }

  void _apply(DamasMove move) {
    _game = _game.play(move);
    _partialPath = const [];
    if (_game.end != null) {
      _phase = DamasPhase.finished;
      switch (winnerPlayer) {
        case 1:
          _wins1++;
        case 2:
          _wins2++;
        default:
          _draws++;
      }
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
    DamasMove move;
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

  Future<DamasMove> _defaultRunner(
    DamasPosition position,
    AiLevel level,
  ) async {
    final seed = _random.nextInt(1 << 30);
    if (level == AiLevel.easy) {
      return chooseMove(position, level, Random(seed));
    }
    final index = await compute(chooseMoveInIsolate, (
      position.cells,
      position.turn.index,
      level.index,
      seed,
    ));
    return legalMoves(position)[index];
  }

  void _newGame(DamasGame game) {
    _gameId++;
    _game = game;
    _partialPath = const [];
    _aiThinking = false;
    _phase = game.end != null ? DamasPhase.finished : DamasPhase.playing;
    if (game.end != null) {
      switch (winnerPlayer) {
        case 1:
          _wins1++;
        case 2:
          _wins2++;
        default:
          _draws++;
      }
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
