// lib/games/tictactoe/models/game_state.dart

enum GamePhase { setup, playing, result }

enum Cell { empty, x, o }

extension CellEmoji on Cell {
  String get emoji {
    switch (this) {
      case Cell.x:
        return '❌';
      case Cell.o:
        return '⭕';
      case Cell.empty:
        return '';
    }
  }
}
