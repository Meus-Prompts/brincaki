// lib/games/cacapalavras/models/game_state.dart

enum WordSearchPhase { setup, playing, won }

enum Direction {
  right(0, 1),
  down(1, 0),
  downRight(1, 1),
  upRight(-1, 1),
  left(0, -1),
  up(-1, 0),
  upLeft(-1, -1),
  downLeft(1, -1);

  const Direction(this.dr, this.dc);

  final int dr;
  final int dc;
}

class PlacedWord {
  const PlacedWord({
    required this.word,
    required this.direction,
    required this.cells,
  });

  final String word;
  final Direction direction;

  /// Células (linha, coluna) da primeira à última letra.
  final List<(int, int)> cells;
}
