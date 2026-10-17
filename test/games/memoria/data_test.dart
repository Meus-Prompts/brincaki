// test/games/memoria/data_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/memoria/data/emojis.dart';
import 'package:brincaki/games/memoria/data/levels.dart';
import 'package:brincaki/games/memoria/models/game_state.dart';

void main() {
  final allGrids = [...kSoloLevels, ...kDuoSizes.values];

  test('emojis são todos diferentes', () {
    expect(kMemoryEmojis.toSet(), hasLength(kMemoryEmojis.length));
    expect(kMemoryEmojis.every((e) => e.isNotEmpty), isTrue);
  });

  test('há emojis distintos suficientes para a maior grade', () {
    final maxPairs = allGrids.map((g) => g.pairs).reduce((a, b) => a > b ? a : b);
    expect(maxPairs, 18); // 6×6
    expect(kMemoryEmojis.length, greaterThanOrEqualTo(maxPairs));
  });

  test('toda grade tem número par de cartas', () {
    for (final grid in allGrids) {
      expect((grid.rows * grid.cols).isEven, isTrue,
          reason: '${grid.rows}×${grid.cols}');
      expect(grid.pairs * 2, grid.rows * grid.cols);
    }
  });

  test('são 5 níveis solo, cada um maior que o anterior e em pé', () {
    expect(kSoloLevels, hasLength(5));
    for (var i = 1; i < kSoloLevels.length; i++) {
      expect(kSoloLevels[i].pairs, greaterThan(kSoloLevels[i - 1].pairs));
    }
    for (final grid in kSoloLevels) {
      expect(grid.rows, greaterThanOrEqualTo(grid.cols));
    }
    expect([for (final g in kSoloLevels) g.pairs], [6, 8, 10, 15, 18]);
  });

  test('tamanhos em dois jogadores: Pequena, Média e Grande', () {
    expect(kDuoSizes.keys, ['Pequena', 'Média', 'Grande']);
    expect(kDuoSizes['Pequena']!.pairs, 6);
    expect(kDuoSizes['Média']!.pairs, 10);
    expect(kDuoSizes['Grande']!.pairs, 18);
  });

  test('MemoryCard começa virada para baixo e copyWith troca só o pedido', () {
    const card = MemoryCard(id: 3, emoji: '🐶');
    expect(card.faceUp, isFalse);
    expect(card.matched, isFalse);

    final up = card.copyWith(faceUp: true);
    expect((up.id, up.emoji, up.faceUp, up.matched), (3, '🐶', true, false));

    final matched = up.copyWith(matched: true);
    expect((matched.id, matched.emoji, matched.faceUp, matched.matched),
        (3, '🐶', true, true));

    final same = matched.copyWith();
    expect((same.faceUp, same.matched), (true, true));
  });
}
