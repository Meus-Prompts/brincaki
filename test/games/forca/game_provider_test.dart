// test/games/forca/game_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/forca/providers/game_provider.dart';
import 'package:brincaki/games/forca/models/game_state.dart';

void main() {
  group('ForcaProvider', () {
    late ForcaProvider provider;

    setUp(() {
      provider = ForcaProvider();
    });

    test('começa no nível 1 com fase playing', () {
      expect(provider.level, 1);
      expect(provider.phase, ForcaPhase.playing);
      expect(provider.wrongCount, 0);
    });

    test('letra correta revela letra e fica verde', () {
      final firstLetter = provider.currentWord[0];
      provider.guessLetter(firstLetter);
      expect(provider.letterStates[firstLetter], LetterState.correct);
      expect(provider.revealedWord.contains(firstLetter), isTrue);
    });

    test('letra errada incrementa wrongCount e fica vermelha', () {
      // Encontra letra que não está na palavra
      final wrongLetter = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          .split('')
          .firstWhere((l) => !provider.currentWord.contains(l));
      provider.guessLetter(wrongLetter);
      expect(provider.wrongCount, 1);
      expect(provider.letterStates[wrongLetter], LetterState.wrong);
    });

    test('6 erros resulta em derrota (fase lost)', () {
      // Garante que temos 6 letras erradas disponíveis
      final wrongLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          .split('')
          .where((l) => !provider.currentWord.contains(l))
          .take(6)
          .toList();
      for (final l in wrongLetters) {
        provider.guessLetter(l);
      }
      expect(provider.phase, ForcaPhase.lost);
    });

    test('acertar a palavra inteira resulta em vitória (fase won)', () {
      for (final letter in provider.currentWord.split('').toSet()) {
        provider.guessLetter(letter);
      }
      expect(provider.phase, ForcaPhase.won);
    });

    test('avança de nível após vitória', () {
      expect(provider.level, 1);
      for (final letter in provider.currentWord.split('').toSet()) {
        provider.guessLetter(letter);
      }
      provider.nextWord(); // avança
      expect(provider.level, 2);
    });

    test('derrota reseta para nível 1', () {
      // Win the level 1 word to advance to level 2
      for (final letter in provider.currentWord.split('').toSet()) {
        provider.guessLetter(letter);
      }
      expect(provider.phase, ForcaPhase.won);
      provider.nextWord(); // vai para nível 2
      expect(provider.level, 2);

      // Now lose at level 2
      final wrongLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          .split('')
          .where((l) => !provider.currentWord.contains(l))
          .take(6)
          .toList();
      for (final l in wrongLetters) {
        provider.guessLetter(l);
      }
      expect(provider.phase, ForcaPhase.lost);
      provider.retry(); // reseta
      expect(provider.level, 1);
    });

    test('letra já tentada é ignorada', () {
      final firstLetter = provider.currentWord[0];
      provider.guessLetter(firstLetter);
      provider.guessLetter(firstLetter); // segunda tentativa ignorada
      expect(provider.letterStates[firstLetter], LetterState.correct);
      expect(provider.wrongCount, 0);
    });
  });
}
