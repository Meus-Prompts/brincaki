// test/games/forca/game_provider_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/forca/data/word_list.dart';
import 'package:brincaki/games/forca/providers/game_provider.dart';
import 'package:brincaki/games/forca/models/game_state.dart';

const _alphabet = ForcaProvider.alphabet;

/// Acerta todas as letras da palavra atual.
void winWord(ForcaProvider p) {
  for (final letter in p.currentWord.split('').toSet()) {
    p.guessLetter(letter);
  }
}

/// Letras que não estão na palavra atual.
List<String> wrongLetters(ForcaProvider p) =>
    _alphabet.split('').where((l) => !p.currentWord.contains(l)).toList();

/// Erra seis letras.
void loseWord(ForcaProvider p) {
  for (final l in wrongLetters(p).take(ForcaProvider.maxErrors)) {
    p.guessLetter(l);
  }
}

ForcaProvider started(int level, {int seed = 1}) =>
    ForcaProvider(random: Random(seed))..start(level);

void main() {
  group('setup', () {
    test('começa na escolha de nível, sem palavra', () {
      final p = ForcaProvider();
      expect(p.phase, ForcaPhase.setup);
      expect(p.level, 1);
      expect(p.currentWord, '');
      expect(p.revealedWord, '');
      expect(p.wrongCount, 0);
      expect(p.letterStates, isEmpty);
      expect(p.correctLetters, isEmpty);
    });

    test('chutar letra na escolha de nível não faz nada', () {
      final p = ForcaProvider();
      var notified = 0;
      p.addListener(() => notified++);
      p.guessLetter('A');
      p.nextWord();
      p.retry();
      p.exitToSetup();
      expect(p.phase, ForcaPhase.setup);
      expect(p.letterStates, isEmpty);
      expect(notified, 0);
    });

    for (var level = 1; level <= ForcaProvider.maxLevel; level++) {
      test('start($level) começa no nível $level com uma palavra do nível', () {
        final p = ForcaProvider();
        var notified = 0;
        p.addListener(() => notified++);
        p.start(level);
        expect(p.phase, ForcaPhase.playing);
        expect(p.level, level);
        expect(kWordsByLevel[level], contains(p.currentWord));
        expect(p.revealedWord, List.filled(p.currentWord.length, '_').join(' '));
        expect(p.isLastLevel, level == ForcaProvider.maxLevel);
        expect(notified, 1);
      });
    }

    test('níveis inválidos são ignorados', () {
      final p = ForcaProvider();
      for (final level in [0, -1, 8, 100]) {
        p.start(level);
        expect(p.phase, ForcaPhase.setup);
        expect(p.level, 1);
      }
    });

    test('start durante a partida é ignorado', () {
      final p = started(2);
      final word = p.currentWord;
      p.start(5);
      expect(p.level, 2);
      expect(p.currentWord, word);
    });
  });

  group('chutes', () {
    test('letra correta revela a letra em todas as posições', () {
      final p = started(1);
      final letter = p.currentWord[0];
      p.guessLetter(letter);
      expect(p.letterStates[letter], LetterState.correct);
      expect(p.correctLetters, {letter});
      final revealed = p.revealedWord.split(' ');
      for (var i = 0; i < p.currentWord.length; i++) {
        expect(revealed[i], p.currentWord[i] == letter ? letter : '_');
      }
    });

    test('letra repetida na palavra conta uma vez só', () {
      // Nível 7 tem palavras com letras repetidas (ex.: DINOSSAURO).
      final p = started(7);
      final repeated = p.currentWord
          .split('')
          .firstWhere((l) => p.currentWord.indexOf(l) != p.currentWord.lastIndexOf(l));
      p.guessLetter(repeated);
      expect(p.revealedWord.split(' ').where((l) => l == repeated).length, greaterThan(1));
      expect(p.letterStates.length, 1);
    });

    test('letra errada aumenta os erros e fica vermelha', () {
      final p = started(1);
      final wrong = wrongLetters(p).first;
      p.guessLetter(wrong);
      expect(p.wrongCount, 1);
      expect(p.letterStates[wrong], LetterState.wrong);
      expect(p.revealedWord.contains(wrong), isFalse);
    });

    test('letra já tentada é ignorada e não avisa os ouvintes', () {
      final p = started(1);
      final right = p.currentWord[0];
      final wrong = wrongLetters(p).first;
      p.guessLetter(right);
      p.guessLetter(wrong);
      var notified = 0;
      p.addListener(() => notified++);
      p.guessLetter(right);
      p.guessLetter(wrong);
      expect(p.wrongCount, 1);
      expect(p.letterStates[right], LetterState.correct);
      expect(notified, 0);
    });

    test('minúsculas valem como maiúsculas', () {
      final p = started(1);
      final letter = p.currentWord[0];
      p.guessLetter(letter.toLowerCase());
      expect(p.letterStates[letter], LetterState.correct);
      expect(p.letterStates.containsKey(letter.toLowerCase()), isFalse);
    });

    test('letras com acento e cedilha viram a letra sem acento', () {
      const cases = {
        'á': 'A', 'à': 'A', 'â': 'A', 'ã': 'A', 'Ä': 'A',
        'é': 'E', 'ê': 'E', 'È': 'E', 'ë': 'E',
        'í': 'I', 'Ì': 'I', 'î': 'I', 'ï': 'I',
        'ó': 'O', 'ô': 'O', 'õ': 'O', 'Ò': 'O', 'ö': 'O',
        'ú': 'U', 'ü': 'U', 'Ù': 'U', 'û': 'U',
        'ç': 'C', 'Ç': 'C',
      };
      for (final entry in cases.entries) {
        final p = started(1);
        p.guessLetter(entry.key);
        expect(p.letterStates.keys, [entry.value], reason: entry.key);
      }
    });

    test('entradas que não são uma letra são ignoradas', () {
      final p = started(1);
      for (final input in ['', 'AB', '1', ' ', '-', 'ñ', '😀']) {
        p.guessLetter(input);
      }
      expect(p.letterStates, isEmpty);
      expect(p.phase, ForcaPhase.playing);
    });

    test('letterStates não pode ser alterado por fora', () {
      final p = started(1);
      expect(() => p.letterStates['A'] = LetterState.correct, throwsUnsupportedError);
    });
  });

  group('fim da palavra', () {
    test('cinco erros ainda não perdem; o sexto perde', () {
      final p = started(1);
      final wrong = wrongLetters(p);
      for (final l in wrong.take(5)) {
        p.guessLetter(l);
      }
      expect(p.phase, ForcaPhase.playing);
      expect(p.wrongCount, 5);
      p.guessLetter(wrong[5]);
      expect(p.phase, ForcaPhase.lost);
      expect(p.wrongCount, 6);
    });

    test('acertar a palavra inteira vence, mesmo com erros', () {
      final p = started(3);
      p.guessLetter(wrongLetters(p).first);
      winWord(p);
      expect(p.phase, ForcaPhase.won);
      expect(p.revealedWord.replaceAll(' ', ''), p.currentWord);
    });

    test('depois de vencer ou perder, chutes são ignorados', () {
      final won = started(1);
      winWord(won);
      final states = Map.of(won.letterStates);
      won.guessLetter(wrongLetters(won).last);
      expect(won.letterStates, states);

      final lost = started(1);
      loseWord(lost);
      lost.guessLetter(lost.currentWord[0]);
      expect(lost.letterStates.containsKey(lost.currentWord[0]), isFalse);
      expect(lost.phase, ForcaPhase.lost);
    });
  });

  group('próxima palavra', () {
    test('vencer avança um nível e sorteia palavra nova', () {
      final p = started(1);
      winWord(p);
      p.nextWord();
      expect(p.phase, ForcaPhase.playing);
      expect(p.level, 2);
      expect(kWordsByLevel[2], contains(p.currentWord));
      expect(p.letterStates, isEmpty);
    });

    test('vencendo sempre, passa por todos os níveis até o 7', () {
      final p = started(1);
      for (var level = 1; level <= ForcaProvider.maxLevel; level++) {
        expect(p.level, level);
        expect(kWordsByLevel[level], contains(p.currentWord));
        winWord(p);
        p.nextWord();
      }
      expect(p.level, ForcaProvider.maxLevel);
    });

    test('no último nível, vencer continua no nível 7 com outra palavra', () {
      final p = started(7);
      expect(p.isLastLevel, isTrue);
      final word = p.currentWord;
      winWord(p);
      p.nextWord();
      expect(p.level, 7);
      expect(p.currentWord, isNot(word));
      expect(p.phase, ForcaPhase.playing);
    });

    test('nextWord fora da vitória é ignorado', () {
      final p = started(2);
      final word = p.currentWord;
      p.nextWord();
      expect(p.level, 2);
      expect(p.currentWord, word);

      loseWord(p);
      p.nextWord();
      expect(p.phase, ForcaPhase.lost);
      expect(p.level, 2);
    });
  });

  group('tentar de novo', () {
    test('depois de perder, continua no mesmo nível com palavra nova', () {
      final p = started(4);
      final word = p.currentWord;
      loseWord(p);
      p.retry();
      expect(p.phase, ForcaPhase.playing);
      expect(p.level, 4);
      expect(p.currentWord, isNot(word));
      expect(kWordsByLevel[4], contains(p.currentWord));
      expect(p.wrongCount, 0);
      expect(p.letterStates, isEmpty);
    });

    test('retry fora da derrota é ignorado', () {
      final p = started(3);
      final word = p.currentWord;
      p.retry();
      expect(p.currentWord, word);
      winWord(p);
      p.retry();
      expect(p.phase, ForcaPhase.won);
    });
  });

  group('palavras sem repetir', () {
    for (var level = 1; level <= ForcaProvider.maxLevel; level++) {
      test('nível $level: todas as palavras saem antes de alguma repetir', () {
        final words = kWordsByLevel[level]!;
        for (var seed = 0; seed < 5; seed++) {
          final p = started(level, seed: seed);
          final seen = <String>[p.currentWord];
          for (var i = 1; i < words.length; i++) {
            loseWord(p);
            p.retry();
            seen.add(p.currentWord);
          }
          expect(seen.toSet(), words.toSet(), reason: 'seed $seed');
        }
      });
    }

    test('ao recomeçar a lista, não repete a palavra que acabou de sair', () {
      final words = kWordsByLevel[1]!;
      for (var seed = 0; seed < 20; seed++) {
        final p = started(1, seed: seed);
        var previous = p.currentWord;
        for (var i = 1; i < words.length * 3; i++) {
          loseWord(p);
          p.retry();
          expect(p.currentWord, isNot(previous), reason: 'seed $seed, rodada $i');
          previous = p.currentWord;
        }
      }
    });

    test('a lista de usadas vale também depois de mudar de nível', () {
      final p = started(1, seed: 3);
      final first = p.currentWord;
      p.exitToSetup();
      final seen = <String>{first};
      for (var i = 1; i < kWordsByLevel[1]!.length; i++) {
        p.start(1);
        seen.add(p.currentWord);
        p.exitToSetup();
      }
      expect(seen, kWordsByLevel[1]!.toSet());
    });
  });

  group('mudar nível', () {
    test('volta para a escolha de nível guardando o nível atual', () {
      for (final finish in [winWord, loseWord, (ForcaProvider _) {}]) {
        final p = started(5);
        finish(p);
        var notified = 0;
        p.addListener(() => notified++);
        p.exitToSetup();
        expect(p.phase, ForcaPhase.setup);
        expect(p.level, 5);
        expect(p.currentWord, '');
        expect(p.letterStates, isEmpty);
        expect(notified, 1);
      }
    });

    test('depois de mudar nível, dá para começar em outro', () {
      final p = started(5);
      winWord(p);
      p.exitToSetup();
      p.start(2);
      expect(p.level, 2);
      expect(p.phase, ForcaPhase.playing);
      expect(kWordsByLevel[2], contains(p.currentWord));
    });
  });

  group('lista de palavras', () {
    test('tem os níveis 1 a 7, com 15 palavras cada', () {
      expect(kWordsByLevel.keys.toList()..sort(), [1, 2, 3, 4, 5, 6, 7]);
      for (final words in kWordsByLevel.values) {
        expect(words.length, 15);
      }
    });

    test('só maiúsculas sem acento, todas no teclado', () {
      final valid = RegExp('^[$_alphabet]+\$');
      for (final words in kWordsByLevel.values) {
        for (final word in words) {
          expect(valid.hasMatch(word), isTrue, reason: word);
        }
      }
    });

    test('nenhuma palavra se repete, nem entre níveis', () {
      final all = kWordsByLevel.values.expand((w) => w).toList();
      expect(all.toSet().length, all.length);
    });

    test('tamanhos por nível', () {
      const ranges = {
        1: (3, 3),
        2: (4, 4),
        3: (5, 6),
        4: (4, 8),
        5: (6, 12),
        6: (7, 11),
        7: (8, 12),
      };
      for (final MapEntry(key: level, value: (min, max)) in ranges.entries) {
        for (final word in kWordsByLevel[level]!) {
          expect(word.length, inInclusiveRange(min, max), reason: '$level: $word');
        }
      }
    });

    test('dá para perder: toda palavra deixa pelo menos 6 letras erradas', () {
      for (final word in kWordsByLevel.values.expand((w) => w)) {
        final distinct = word.split('').toSet().length;
        expect(_alphabet.length - distinct, greaterThanOrEqualTo(ForcaProvider.maxErrors));
      }
    });
  });
}
