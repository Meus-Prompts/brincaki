// lib/games/damas/models/game_state.dart

enum DamasPhase { setup, playing, finished }

enum DamasSide {
  white,
  black;

  DamasSide get opponent => this == white ? black : white;
}

/// Como a partida terminou: sem peças, sem lances ou um dos empates.
enum DamasEnd { noPieces, noMoves, repetition, twentyMoves, fiveMoves }
