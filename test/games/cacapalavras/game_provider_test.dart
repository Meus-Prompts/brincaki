// test/games/cacapalavras/game_provider_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/cacapalavras/models/game_state.dart';
import 'package:brincaki/games/cacapalavras/providers/game_provider.dart';

void select(WordSearchProvider p, (int, int) from, (int, int) to) {
  p.startSelection(from.$1, from.$2);
  p.updateSelection(to.$1, to.$2);
  p.endSelection();
}

void findAll(WordSearchProvider p) {
  for (final w in p.words) {
    select(p, w.cells.first, w.cells.last);
  }
}

void main() {
  group('WordSearchProvider', () {
    late WordSearchProvider provider;

    setUp(() {
      provider = WordSearchProvider(random: Random(7));
    });

    test('começa no nível 1 com grade 6×6 e 4 palavras', () {
      expect(provider.level, 1);
      expect(provider.phase, WordSearchPhase.playing);
      expect(provider.grid.length, 6);
      expect(provider.words.length, 4);
      expect(provider.found, isEmpty);
    });

    test('selecionar da primeira à última letra marca a palavra', () {
      final w = provider.words.first;
      select(provider, w.cells.first, w.cells.last);
      expect(provider.found, {w.word});
      expect(provider.selectedCells, isEmpty);
    });

    test('selecionar de trás para frente também marca', () {
      final w = provider.words.first;
      select(provider, w.cells.last, w.cells.first);
      expect(provider.found, {w.word});
    });

    test('seleção parcial ou de uma célula não marca nada', () {
      final w = provider.words.first;
      select(provider, w.cells.first, w.cells.first);
      select(provider, w.cells.first, w.cells[w.cells.length - 2]);
      expect(provider.found, isEmpty);
    });

    test('selectedCells acompanha o arrasto', () {
      final w = provider.words.first;
      provider.startSelection(w.cells.first.$1, w.cells.first.$2);
      provider.updateSelection(w.cells.last.$1, w.cells.last.$2);
      expect(provider.selectedCells, w.cells);
    });

    test('encontrar todas vence; seleção é ignorada depois', () {
      findAll(provider);
      expect(provider.phase, WordSearchPhase.won);
      provider.startSelection(0, 0);
      expect(provider.selectedCells, isEmpty);
    });

    test('nextLevel só funciona depois de vencer', () {
      provider.nextLevel();
      expect(provider.level, 1);

      findAll(provider);
      provider.nextLevel();
      expect(provider.level, 2);
      expect(provider.grid.length, 7);
      expect(provider.words.length, 5);
      expect(provider.found, isEmpty);
      expect(provider.phase, WordSearchPhase.playing);
    });

    test('depois do nível 10 volta ao nível 1', () {
      for (var level = 1; level <= 10; level++) {
        expect(provider.level, level);
        expect(provider.isLastLevel, level == 10);
        findAll(provider);
        provider.nextLevel();
      }
      expect(provider.level, 1);
    });
  });
}
