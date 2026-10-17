// test/games/cacapalavras/grid_generator_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/cacapalavras/data/levels.dart';
import 'package:brincaki/games/cacapalavras/models/game_state.dart';
import 'package:brincaki/games/cacapalavras/services/grid_generator.dart';

final _letter = RegExp(r'^[A-Z]$');

void main() {
  group('generateGrid', () {
    for (var i = 0; i < 10; i++) {
      test('nível ${i + 1}: cada palavra aparece uma única vez na grade', () {
        final level = kLevels[i];
        for (var seed = 0; seed < 100; seed++) {
          final g = generateGrid(
            candidates: level.words,
            wordCount: level.wordCount,
            size: level.size,
            directions: level.directions,
            random: Random(seed),
          );
          for (final w in g.words) {
            expect(
              _occurrences(g.letters, w.word),
              1,
              reason: 'seed $seed: ${w.word} aparece mais de uma vez',
            );
          }
        }
      });
    }

    test(
      'mesma seed gera a mesma grade; seeds diferentes, grades diferentes',
      () {
        final level = kLevels[7];
        GeneratedGrid make(int seed) => generateGrid(
          candidates: level.words,
          wordCount: level.wordCount,
          size: level.size,
          directions: level.directions,
          random: Random(seed),
        );
        final a = make(5);
        final b = make(5);
        expect(a.letters, b.letters);
        expect(a.words.map((w) => w.word), b.words.map((w) => w.word));
        expect(
          a.words.map((w) => w.direction),
          b.words.map((w) => w.direction),
        );
        expect(a.words.map((w) => w.cells), b.words.map((w) => w.cells));
        expect(make(6).letters, isNot(a.letters));
      },
    );

    test('usa só as direções permitidas e, com todas liberadas, usa as 8', () {
      for (var i = 0; i < kLevels.length; i++) {
        final level = kLevels[i];
        final used = <Direction>{};
        for (var seed = 0; seed < 40; seed++) {
          final g = generateGrid(
            candidates: level.words,
            wordCount: level.wordCount,
            size: level.size,
            directions: level.directions,
            random: Random(seed),
          );
          used.addAll(g.words.map((w) => w.direction));
        }
        expect(level.directions, containsAll(used), reason: level.theme);
        expect(used, level.directions.toSet(), reason: level.theme);
      }
    });

    test('com uma direção só, todas as palavras seguem ela', () {
      for (final d in Direction.values) {
        final g = generateGrid(
          candidates: const ['SOL', 'LUA', 'MAR', 'RIO', 'CEU'],
          wordCount: 3,
          size: 6,
          directions: [d],
          random: Random(1),
        );
        for (final w in g.words) {
          expect(w.direction, d);
          expect(w.cells.map((c) => g.letters[c.$1][c.$2]).join(), w.word);
        }
      }
    });

    test('grade fica cheia mesmo quando as palavras ocupam pouco', () {
      final g = generateGrid(
        candidates: const ['OI'],
        wordCount: 1,
        size: 8,
        directions: const [Direction.right],
        random: Random(2),
      );
      expect(g.letters.length, 8);
      for (final row in g.letters) {
        expect(row.length, 8);
        for (final l in row) {
          expect(l, matches(_letter));
        }
      }
    });

    test('palavra maior que a grade não cabe: erro', () {
      expect(
        () => generateGrid(
          candidates: const ['ELEFANTE'],
          wordCount: 1,
          size: 5,
          directions: Direction.values,
          random: Random(0),
        ),
        throwsStateError,
      );
    });

    test('palavras demais para a grade: erro', () {
      expect(
        () => generateGrid(
          candidates: const ['ABC', 'DEF', 'GHI', 'JKL'],
          wordCount: 4,
          size: 3,
          directions: const [Direction.right],
          random: Random(0),
        ),
        throwsStateError,
      );
    });

    test('poucas candidatas para o pedido: erro', () {
      expect(
        () => generateGrid(
          candidates: const ['SOL', 'LUA'],
          wordCount: 3,
          size: 8,
          directions: Direction.values,
          random: Random(0),
        ),
        throwsStateError,
      );
    });

    test('se a palavra sempre aparece duas vezes, desiste com erro', () {
      // Grade 2×2 só com AB nas duas linhas: AB aparece duas vezes.
      expect(
        () => generateGrid(
          candidates: const ['AB', 'AB'],
          wordCount: 2,
          size: 2,
          directions: const [Direction.right],
          random: Random(0),
        ),
        throwsStateError,
      );
    });

    test('palavra que não encaixa é trocada por uma da reserva', () {
      for (var seed = 0; seed < 20; seed++) {
        final g = generateGrid(
          candidates: const ['ABCDEFGHIJ', 'SOL', 'LUA'],
          wordCount: 2,
          size: 4,
          directions: const [Direction.right, Direction.down],
          random: Random(seed),
        );
        expect(g.words.map((w) => w.word).toSet(), {'SOL', 'LUA'});
      }
    });

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
            final shared = g.words[a].cells.toSet().intersection(
              g.words[b].cells.toSet(),
            );
            expect(
              shared.length,
              lessThanOrEqualTo(1),
              reason: 'seed $seed: ${g.words[a].word} x ${g.words[b].word}',
            );
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
              final shared = g.words[a].cells.toSet().intersection(
                g.words[b].cells.toSet(),
              );
              expect(
                shared.length,
                lessThanOrEqualTo(1),
                reason: '${g.words[a].word} x ${g.words[b].word}',
              );
            }
          }
        }
      });
    }
  });
}

/// Quantos trechos retos da grade (em qualquer das 8 direções) formam [word].
/// Um palíndromo lido nos dois sentidos conta uma vez só.
int _occurrences(List<List<String>> letters, String word) {
  final size = letters.length;
  final found = <String>{};
  for (final d in Direction.values) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final cells = [
          for (var k = 0; k < word.length; k++) (r + d.dr * k, c + d.dc * k),
        ];
        if (cells.any(
          (p) => p.$1 < 0 || p.$1 >= size || p.$2 < 0 || p.$2 >= size,
        )) {
          continue;
        }
        if (cells.map((p) => letters[p.$1][p.$2]).join() != word) continue;
        final key =
            (cells.toList()..sort(
                  (a, b) => a.$1 != b.$1
                      ? a.$1.compareTo(b.$1)
                      : a.$2.compareTo(b.$2),
                ))
                .join();
        found.add(key);
      }
    }
  }
  return found.length;
}
