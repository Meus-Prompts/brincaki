// lib/games/memoria/models/game_state.dart

enum MemoryPhase { setup, playing, finished }

class MemoryCard {
  const MemoryCard({
    required this.id,
    required this.emoji,
    this.faceUp = false,
    this.matched = false,
  });

  /// Posição na grade.
  final int id;
  final String emoji;
  final bool faceUp;
  final bool matched;

  MemoryCard copyWith({bool? faceUp, bool? matched}) => MemoryCard(
        id: id,
        emoji: emoji,
        faceUp: faceUp ?? this.faceUp,
        matched: matched ?? this.matched,
      );
}
