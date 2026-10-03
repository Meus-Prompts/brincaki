// test/games/cacapalavras/grid_generator_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/cacapalavras/data/levels.dart';
import 'package:brincaki/games/cacapalavras/models/game_state.dart';
import 'package:brincaki/games/cacapalavras/services/grid_generator.dart';

final _word = RegExp(r'^[A-Z]+$');
final _letter = RegExp(r'^[A-Z]$');

void main() {
  group('kLevels', () {
    test('tem 10 níveis', () {
      expect(kLevels.length, 10);
    });

    for (var i = 0; i < 10; i++) {
      test('nível ${i + 1}: palavras válidas e reserva suficiente', () {
        final level = kLevels[i];
        expect(level.words.length, greaterThanOrEqualTo(level.wordCount + 5));
        expect(level.words.toSet().length, level.words.length,
            reason: 'palavra repetida no tema ${level.theme}');
        for (final w in level.words) {
          expect(w, matches(_word), reason: w);
          expect(w.length, inInclusiveRange(3, level.size), reason: w);
        }
      });
    }
  });

  group('generateGrid', () {
    test('palavras parecidas não compartilham mais de uma célula', () {
      for (var seed = 0; seed < 30; seed++) {
        final g = generateGrid(
          // Trechos em comum (BCD, CDE...) permitem encaixes deslocados.
          candidates: const ['ABCD', 'BCDE', 'CDEA', 'DEAB'],
          wordCount: 4,
          size: 5,
          directions: const [Direction.right],
          random: Random(seed),
        );
        for (var a = 0; a < g.words.length; a++) {
          for (var b = a + 1; b < g.words.length; b++) {
            final shared = g.words[a].cells
                .toSet()
                .intersection(g.words[b].cells.toSet());
            expect(shared.length, lessThanOrEqualTo(1),
                reason: 'seed $seed: ${g.words[a].word} x ${g.words[b].word}');
          }
        }
      }
    });

    for (var i = 0; i < 10; i++) {
      test('nível ${i + 1}: 20 grades válidas', () {
        final level = kLevels[i];
        for (var seed = 0; seed < 20; seed++) {
          final g = generateGrid(
            candidates: level.words,
            wordCount: level.wordCount,
            size: level.size,
            directions: level.directions,
            random: Random(seed),
          );

          expect(g.letters.length, level.size);
          for (final row in g.letters) {
            expect(row.length, level.size);
            for (final l in row) {
              expect(l, matches(_letter));
            }
          }

          expect(g.words.length, level.wordCount);
          expect(g.words.map((w) => w.word).toSet().length, level.wordCount);

          for (final w in g.words) {
            expect(level.words, contains(w.word));
            expect(level.directions, contains(w.direction));
            expect(w.cells.length, w.word.length);
            expect(w.cells.map((c) => g.letters[c.$1][c.$2]).join(), w.word);
            for (var k = 1; k < w.cells.length; k++) {
              expect(w.cells[k].$1 - w.cells[k - 1].$1, w.direction.dr);
              expect(w.cells[k].$2 - w.cells[k - 1].$2, w.direction.dc);
            }
          }

          for (var a = 0; a < g.words.length; a++) {
            for (var b = a + 1; b < g.words.length; b++) {
              final shared = g.words[a].cells
                  .toSet()
                  .intersection(g.words[b].cells.toSet());
              expect(shared.length, lessThanOrEqualTo(1),
                  reason: '${g.words[a].word} x ${g.words[b].word}');
            }
          }
        }
      });
    }
  });
}
