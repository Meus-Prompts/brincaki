// lib/games/xadrez/models/game_state.dart

enum XadrezPhase { setup, playing, finished }

enum ChessSide {
  white,
  black;

  ChessSide get opponent => this == white ? black : white;
}

/// Como a partida terminou: mate, afogamento ou um dos empates.
enum XadrezEnd {
  checkmate,
  stalemate,
  insufficientMaterial,
  fiftyMoves,
  repetition,
}

// Peças nas casas: positivo para as brancas, negativo para as pretas.
const kPawn = 1;
const kKnight = 2;
const kBishop = 3;
const kRook = 4;
const kQueen = 5;
const kKing = 6;
