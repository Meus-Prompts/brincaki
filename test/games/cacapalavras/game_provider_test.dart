// test/games/cacapalavras/game_provider_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/cacapalavras/data/levels.dart';
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

/// Conta as notificações do provider.
int Function() countNotifications(WordSearchProvider p) {
  var count = 0;
  p.addListener(() => count++);
  return () => count;
}

void main() {
  group('WordSearchProvider: setup', () {
    late WordSearchProvider provider;

    setUp(() {
      provider = WordSearchProvider(random: Random(7));
    });

    test('começa na tela de início, sem grade', () {
      expect(provider.phase, WordSearchPhase.setup);
      expect(provider.level, 1);
      expect(provider.grid, isEmpty);
      expect(provider.words, isEmpty);
      expect(provider.found, isEmpty);
      expect(provider.selectedCells, isEmpty);
    });

    test('funciona sem Random injetado', () {
      final p = WordSearchProvider()..start(5);
      expect(p.words.length, kLevels[4].wordCount);
    });

    test('start(1) monta a grade 6×6 com 4 palavras', () {
      final notifications = countNotifications(provider);
      provider.start(1);
      expect(notifications(), 1);
      expect(provider.phase, WordSearchPhase.playing);
      expect(provider.level, 1);
      expect(provider.grid.length, 6);
      expect(provider.words.length, 4);
      expect(provider.found, isEmpty);
    });

    for (var level = 1; level <= 10; level++) {
      test('start($level) usa a configuração do nível', () {
        provider.start(level);
        final config = kLevels[level - 1];
        expect(provider.level, level);
        expect(provider.config, same(config));
        expect(provider.isLastLevel, level == 10);
        expect(provider.grid.length, config.size);
        expect(provider.words.length, config.wordCount);
        for (final w in provider.words) {
          expect(config.words, contains(w.word));
          expect(config.directions, contains(w.direction));
        }
      });
    }

    test('start com nível inválido é ignorado', () {
      final notifications = countNotifications(provider);
      for (final level in [0, -1, 11, 99]) {
        provider.start(level);
      }
      expect(provider.phase, WordSearchPhase.setup);
      expect(provider.level, 1);
      expect(notifications(), 0);
    });

    test('start fora do setup é ignorado', () {
      provider.start(2);
      final grid = provider.grid;
      provider.start(5);
      expect(provider.level, 2);
      expect(provider.grid, same(grid));

      findAll(provider);
      provider.start(5);
      expect(provider.level, 2);
      expect(provider.phase, WordSearchPhase.won);
    });

    test('exitToSetup durante a partida limpa tudo e guarda o nível', () {
      provider.start(4);
      final w = provider.words.first;
      select(provider, w.cells.first, w.cells.last);
      provider.startSelection(0, 0);
      final notifications = countNotifications(provider);
      provider.exitToSetup();
      expect(notifications(), 1);
      expect(provider.phase, WordSearchPhase.setup);
      expect(provider.level, 4);
      expect(provider.grid, isEmpty);
      expect(provider.words, isEmpty);
      expect(provider.found, isEmpty);
      expect(provider.selectedCells, isEmpty);
    });

    test('exitToSetup depois de vencer permite escolher outro nível', () {
      provider.start(3);
      findAll(provider);
      provider.exitToSetup();
      expect(provider.phase, WordSearchPhase.setup);
      provider.start(7);
      expect(provider.level, 7);
      expect(provider.phase, WordSearchPhase.playing);
    });

    test('exitToSetup no setup não faz nada', () {
      final notifications = countNotifications(provider);
      provider.exitToSetup();
      expect(notifications(), 0);
      expect(provider.phase, WordSearchPhase.setup);
    });

    test('seleção no setup é ignorada', () {
      final notifications = countNotifications(provider);
      provider.startSelection(0, 0);
      provider.updateSelection(0, 3);
      provider.endSelection();
      expect(provider.selectedCells, isEmpty);
      expect(notifications(), 0);
    });

    test('nextLevel no setup é ignorado', () {
      provider.nextLevel();
      expect(provider.phase, WordSearchPhase.setup);
      expect(provider.level, 1);
    });

    test('mesma seed gera a mesma grade', () {
      final a = WordSearchProvider(random: Random(42))..start(8);
      final b = WordSearchProvider(random: Random(42))..start(8);
      expect(a.grid, b.grid);
      expect(a.words.map((w) => w.word), b.words.map((w) => w.word));
    });
  });

  group('WordSearchProvider: partida', () {
    late WordSearchProvider provider;

    setUp(() {
      provider = WordSearchProvider(random: Random(7))..start(1);
    });

    test('selecionar da primeira à última letra marca a palavra', () {
      final w = provider.words.first;
      select(provider, w.cells.first, w.cells.last);
      expect(provider.found, {w.word});
      expect(provider.selectedCells, isEmpty);
      expect(provider.phase, WordSearchPhase.playing);
    });

    test('selecionar de trás para frente também marca', () {
      final w = provider.words.first;
      select(provider, w.cells.last, w.cells.first);
      expect(provider.found, {w.word});
    });

    test('ao contrário funciona em todas as direções (nível 10)', () {
      final p = WordSearchProvider(random: Random(3))..start(10);
      for (final w in p.words) {
        select(p, w.cells.last, w.cells.first);
        expect(p.found, contains(w.word), reason: '${w.word} ${w.direction}');
      }
      expect(p.phase, WordSearchPhase.won);
    });

    test('selecionar de novo uma palavra já encontrada não muda nada', () {
      final w = provider.words.first;
      select(provider, w.cells.first, w.cells.last);
      select(provider, w.cells.last, w.cells.first);
      select(provider, w.cells.first, w.cells.last);
      expect(provider.found, {w.word});
      expect(provider.phase, WordSearchPhase.playing);
    });

    test('seleção parcial, longa demais ou de uma célula não marca nada', () {
      final w = provider.words.first;
      select(provider, w.cells.first, w.cells.first);
      select(provider, w.cells.first, w.cells[w.cells.length - 2]);
      select(provider, w.cells[1], w.cells.last);
      expect(provider.found, isEmpty);
    });

    test('seleção que não é uma palavra não marca nada', () {
      // Uma diagonal no nível 1 nunca é palavra (só → e ↓).
      select(provider, (0, 0), (5, 5));
      select(provider, (5, 0), (0, 5));
      expect(provider.found, isEmpty);
      expect(provider.selectedCells, isEmpty);
    });

    test('selectedCells acompanha o arrasto', () {
      final w = provider.words.first;
      provider.startSelection(w.cells.first.$1, w.cells.first.$2);
      expect(provider.selectedCells, [w.cells.first]);
      provider.updateSelection(w.cells.last.$1, w.cells.last.$2);
      expect(provider.selectedCells, w.cells);
    });

    test('updateSelection na mesma célula não notifica', () {
      provider.startSelection(2, 2);
      provider.updateSelection(2, 4);
      final notifications = countNotifications(provider);
      provider.updateSelection(2, 4);
      expect(notifications(), 0);
    });

    test('updateSelection e endSelection sem startSelection são ignorados', () {
      final notifications = countNotifications(provider);
      provider.updateSelection(3, 3);
      provider.endSelection();
      expect(provider.selectedCells, isEmpty);
      expect(notifications(), 0);
    });

    test('encontrar todas vence; seleção é ignorada depois', () {
      findAll(provider);
      expect(provider.phase, WordSearchPhase.won);
      expect(provider.found.length, provider.words.length);
      final notifications = countNotifications(provider);
      provider.startSelection(0, 0);
      provider.updateSelection(0, 3);
      provider.endSelection();
      expect(provider.selectedCells, isEmpty);
      expect(notifications(), 0);
    });

    test('a última palavra só vence quando todas foram achadas', () {
      final words = provider.words;
      for (var i = 0; i < words.length; i++) {
        expect(provider.phase, WordSearchPhase.playing);
        select(provider, words[i].cells.first, words[i].cells.last);
        expect(provider.found.length, i + 1);
      }
      expect(provider.phase, WordSearchPhase.won);
    });

    test('words e found não podem ser alterados de fora', () {
      expect(() => provider.words.clear(), throwsUnsupportedError);
      expect(() => provider.found.add('X'), throwsUnsupportedError);
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

    test('avança até o nível 10 e depois volta ao nível 1', () {
      for (var level = 1; level <= 10; level++) {
        expect(provider.level, level);
        expect(provider.isLastLevel, level == 10);
        expect(provider.grid.length, kLevels[level - 1].size);
        findAll(provider);
        expect(provider.phase, WordSearchPhase.won);
        provider.nextLevel();
      }
      expect(provider.level, 1);
      expect(provider.phase, WordSearchPhase.playing);
      expect(provider.grid.length, 6);
    });
  });
}
