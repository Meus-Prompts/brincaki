// test/games/cacapalavras/levels_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/cacapalavras/data/levels.dart';
import 'package:brincaki/games/cacapalavras/models/game_state.dart';

/// O gerador sorteia letras de A a Z: palavras com acento ou Ç nunca
/// apareceriam iguais na grade.
final _word = RegExp(r'^[A-Z]+$');

void main() {
  group('kLevels', () {
    test('tem 10 níveis', () {
      expect(kLevels.length, 10);
    });

    test('os temas são os esperados, na ordem', () {
      expect(kLevels.map((l) => l.theme), [
        'Animais',
        'Frutas',
        'Cores',
        'Corpo humano',
        'Casa',
        'Profissões',
        'Natureza',
        'Esportes',
        'Países',
        'Ciência',
      ]);
    });

    test('a dificuldade nunca diminui de um nível para o outro', () {
      for (var i = 1; i < kLevels.length; i++) {
        final before = kLevels[i - 1];
        final now = kLevels[i];
        expect(now.size, greaterThanOrEqualTo(before.size), reason: now.theme);
        expect(
          now.wordCount,
          greaterThanOrEqualTo(before.wordCount),
          reason: now.theme,
        );
        expect(
          now.directions.length,
          greaterThanOrEqualTo(before.directions.length),
          reason: now.theme,
        );
      }
    });

    test('direções liberadas aos poucos', () {
      expect(kLevels[0].directions, [Direction.right, Direction.down]);
      expect(kLevels[3].directions, contains(Direction.downRight));
      expect(kLevels[4].directions, contains(Direction.upRight));
      expect(
        kLevels[6].directions,
        containsAll([Direction.left, Direction.up]),
      );
      expect(kLevels[9].directions, Direction.values);
    });

    for (var i = 0; i < 10; i++) {
      final level = kLevels[i];
      group('nível ${i + 1} (${level.theme})', () {
        test('grade e quantidade de palavras razoáveis', () {
          expect(level.size, inInclusiveRange(6, 12));
          expect(level.wordCount, inInclusiveRange(4, 12));
          expect(level.theme, isNotEmpty);
        });

        test('reserva suficiente para sortear', () {
          expect(level.words.length, greaterThanOrEqualTo(level.wordCount + 5));
        });

        test('sem palavras repetidas', () {
          expect(level.words.toSet().length, level.words.length);
        });

        test('só letras A-Z, sem acento', () {
          for (final w in level.words) {
            expect(w, matches(_word), reason: w);
          }
        });

        test('cada palavra cabe na grade', () {
          for (final w in level.words) {
            expect(w.length, inInclusiveRange(3, level.size), reason: w);
          }
        });

        test('direções sem repetição', () {
          expect(level.directions, isNotEmpty);
          expect(level.directions.toSet().length, level.directions.length);
        });
      });
    }
  });
}
