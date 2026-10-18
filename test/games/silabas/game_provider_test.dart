// test/games/silabas/game_provider_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/silabas/data/word_list.dart';
import 'package:brincaki/games/silabas/logic/word.dart';
import 'package:brincaki/games/silabas/models/game_state.dart';
import 'package:brincaki/games/silabas/providers/game_provider.dart';

// 'ja-NE-la' tem cortes em 2 e 4; tônica 1; paroxítona.
const _tiny = {
  0: ['ja-NE-la', 'BO-la', 'ca-FÉ'],
  1: ['CAR-ro'],
  2: ['sa-Ú-de'],
};

SilabasProvider started({int level = 0, int seed = 1}) =>
    SilabasProvider(random: Random(seed))..start(level);

SilabasProvider one(String w) => SilabasProvider(
  random: Random(1),
  words: {
    0: [w],
  },
)..start(0);

SilabasProvider tiny() =>
    SilabasProvider(random: Random(1), words: _tiny)..start(0);

int wrongStressOf(SilabasProvider p) => p.word!.stressIndex == 0 ? 1 : 0;

StressClass wrongClassOf(SilabasProvider p) =>
    StressClass.values.firstWhere((c) => c != p.word!.stressClass);

void split(SilabasProvider p) {
  for (final c in p.word!.cutPositions) {
    p.toggleCut(c);
  }
  p.checkSplit();
}

/// Resolve a palavra atual sem erros.
void solve(SilabasProvider p) {
  split(p);
  p.chooseStress(p.word!.stressIndex);
  p.chooseClass(p.word!.stressClass);
}

/// Posição de corte que não existe na palavra atual.
int badCut(SilabasProvider p) => List.generate(
  p.word!.text.length - 1,
  (i) => i + 1,
).firstWhere((c) => !p.word!.cutPositions.contains(c));

void main() {
  group('início', () {
    test('começa na escolha de nível, sem palavra', () {
      final p = SilabasProvider();
      expect(p.phase, SilabasPhase.setup);
      expect(p.level, 0);
      expect(p.word, isNull);
      expect(p.score, 0);
      expect(p.isLastWord, isFalse);
    });

    test('start abre a partida com 10 palavras distintas do nível', () {
      for (var level = 0; level < 3; level++) {
        final p = started(level: level);
        expect(p.phase, SilabasPhase.playing);
        expect(p.level, level);
        expect(p.step, SilabasStep.split);
        expect(p.index, 0);
        expect(p.score, 0);
        expect(p.wordCount, 10);
        final seen = <String>{};
        final valid = kSilabasWordsByLevel[level]!
            .map((w) => parseWord(w).text)
            .toSet();
        while (p.phase == SilabasPhase.playing) {
          expect(valid, contains(p.word!.text));
          expect(seen.add(p.word!.text), isTrue);
          solve(p);
          p.nextWord();
        }
        expect(seen.length, 10);
      }
    });

    test('start com nível fora de 0 a 2 é ignorado', () {
      final p = SilabasProvider();
      var notified = 0;
      p.addListener(() => notified++);
      p.start(-1);
      p.start(3);
      expect(p.phase, SilabasPhase.setup);
      expect(notified, 0);
    });

    test('start fora da escolha de nível é ignorado', () {
      final p = started();
      final first = p.word!.text;
      p.start(2);
      expect(p.level, 0);
      expect(p.word!.text, first);
    });

    test('lista injetada menor que 10 usa as palavras que há', () {
      final p = tiny();
      expect(p.wordCount, 3);
      expect(p.isLastWord, isFalse);
      solve(p);
      p.nextWord();
      solve(p);
      p.nextWord();
      expect(p.isLastWord, isTrue);
      solve(p);
      p.nextWord();
      expect(p.phase, SilabasPhase.finished);
    });

    test('mesma semente sorteia as mesmas palavras', () {
      expect(started(seed: 5).word!.text, started(seed: 5).word!.text);
    });
  });

  group('etapa 1: separar', () {
    test('toggleCut liga e desliga', () {
      final p = started();
      p.toggleCut(1);
      expect(p.cuts, {1});
      p.toggleCut(1);
      expect(p.cuts, isEmpty);
    });

    test('posições fora de 1 até o tamanho menos 1 são ignoradas', () {
      final p = started();
      var notified = 0;
      p.addListener(() => notified++);
      p.toggleCut(0);
      p.toggleCut(-1);
      p.toggleCut(p.word!.text.length);
      expect(p.cuts, isEmpty);
      expect(notified, 0);
    });

    test('conferir sem cortes não faz nada nem conta erro', () {
      final p = tiny();
      var notified = 0;
      p.addListener(() => notified++);
      p.checkSplit();
      expect(notified, 0);
      expect(p.step, SilabasStep.split);
      split(p);
      p.chooseStress(p.word!.stressIndex);
      p.chooseClass(p.word!.stressClass);
      expect(p.wordPoints, 30);
    });

    test('corte errado fica vermelho, sem dica quando nada falta', () {
      final p = one('ja-NE-la');
      p.toggleCut(2);
      p.toggleCut(4);
      p.toggleCut(3);
      p.checkSplit();
      expect(p.step, SilabasStep.split);
      expect(p.wrongCuts, {3});
      expect(p.missingHint, isNull);
    });

    test('corte faltando dá a dica com o total de sílabas', () {
      final p = one('ja-NE-la');
      p.toggleCut(2);
      p.checkSplit();
      expect(p.wrongCuts, isEmpty);
      expect(p.missingHint, 3);
      expect(p.step, SilabasStep.split);
    });

    test('corte errado e faltando ao mesmo tempo mostram vermelho e dica', () {
      final p = tiny();
      final bad = badCut(p);
      p.toggleCut(bad);
      p.checkSplit();
      expect(p.wrongCuts, {bad});
      expect(p.missingHint, p.word!.syllables.length);
    });

    test('cada conferência errada conta um erro só', () {
      final p = tiny();
      p.toggleCut(badCut(p)); // vermelho e dica juntos
      p.checkSplit();
      p.toggleCut(badCut(p)); // desliga o errado; falta tudo
      p.toggleCut(badCut(p)); // liga de novo
      p.checkSplit();
      // dois erros na etapa: 2 pontos
      for (final c in p.word!.cutPositions) {
        p.toggleCut(c);
      }
      p.toggleCut(badCut(p));
      p.checkSplit();
      expect(p.step, SilabasStep.stress);
      expect(p.score, 2);
    });

    test('tocar num corte limpa o vermelho e a dica', () {
      final p = tiny();
      p.toggleCut(badCut(p));
      p.checkSplit();
      expect(p.wrongCuts, isNotEmpty);
      expect(p.missingHint, isNotNull);
      p.toggleCut(badCut(p));
      expect(p.wrongCuts, isEmpty);
      expect(p.missingHint, isNull);
      for (final c in p.word!.cutPositions) {
        p.toggleCut(c);
      }
      p.checkSplit();
      expect(p.step, SilabasStep.stress);
    });

    test('cortes certos abrem a etapa da tônica', () {
      final p = tiny();
      split(p);
      expect(p.step, SilabasStep.stress);
      expect(p.score, 10);
    });
  });

  group('etapa 2: tônica', () {
    test('errada vai para wrongStress e continua na etapa', () {
      final p = tiny()..toString();
      split(p);
      final wrong = wrongStressOf(p);
      p.chooseStress(wrong);
      expect(p.wrongStress, {wrong});
      expect(p.step, SilabasStep.stress);
    });

    test('tocar numa errada já marcada não faz nada', () {
      final p = tiny();
      split(p);
      final wrong = wrongStressOf(p);
      p.chooseStress(wrong);
      var notified = 0;
      p.addListener(() => notified++);
      p.chooseStress(wrong);
      p.chooseStress(-1);
      p.chooseStress(99);
      expect(notified, 0);
      // só um erro: 5 pontos
      p.chooseStress(p.word!.stressIndex);
      expect(p.score, 15);
    });

    test('certa abre a classificação', () {
      final p = tiny();
      split(p);
      p.chooseStress(p.word!.stressIndex);
      expect(p.step, SilabasStep.classify);
    });
  });

  group('etapa 3: classificar', () {
    test('errada vai para wrongClasses; certa resolve a palavra', () {
      final p = tiny();
      split(p);
      p.chooseStress(p.word!.stressIndex);
      final wrong = wrongClassOf(p);
      p.chooseClass(wrong);
      expect(p.wrongClasses, {wrong});
      expect(p.step, SilabasStep.classify);
      var notified = 0;
      p.addListener(() => notified++);
      p.chooseClass(wrong);
      expect(notified, 0);
      p.chooseClass(p.word!.stressClass);
      expect(p.step, SilabasStep.solved);
    });
  });

  group('pontos', () {
    for (final c in [(0, 10), (1, 5), (2, 2), (3, 2)]) {
      test('${c.$1} erros na etapa dão ${c.$2} pontos', () {
        final p = one('ja-NE-la');
        for (var i = 0; i < c.$1; i++) {
          p.toggleCut(badCut(p));
          p.checkSplit();
          p.toggleCut(badCut(p));
        }
        for (final cut in p.word!.cutPositions) {
          p.toggleCut(cut);
        }
        p.checkSplit();
        expect(p.step, SilabasStep.stress);
        expect(p.score, c.$2);
        expect(p.wordPoints, c.$2);
      });
    }

    test('erros de uma etapa não passam para a seguinte', () {
      final p = one('ja-NE-la');
      split(p);
      p.chooseStress(0);
      p.chooseStress(p.word!.stressIndex);
      expect(p.score, 15);
      p.chooseClass(p.word!.stressClass);
      expect(p.score, 25);
    });

    test('palavra perfeita vale 30 e a soma vai para o score', () {
      final p = tiny();
      solve(p);
      expect(p.wordPoints, 30);
      expect(p.score, 30);
      p.nextWord();
      expect(p.wordPoints, 0);
      expect(p.score, 30);
    });

    test('toque repetido não pontua duas vezes', () {
      final p = tiny();
      split(p);
      p.chooseStress(p.word!.stressIndex);
      final afterStress = p.score;
      p.chooseStress(p.word!.stressIndex);
      expect(p.score, afterStress);
      p.chooseClass(p.word!.stressClass);
      final afterClass = p.score;
      p.chooseClass(p.word!.stressClass);
      expect(p.score, afterClass);
      expect(afterClass, 30);
    });

    test('estrelas nos limites 270 e 180', () {
      // pontuação máxima por partida é 300; chega aos limites errando
      int starsFor(int score) {
        final p = SilabasProvider(
          random: Random(1),
          words: {0: List.filled(1, 'ja-NE-la')},
        )..start(0);
        // força a pontuação com palavras perfeitas e depois ajusta
        // por reflexão indireta: usa o getter com partidas simuladas.
        return _starsFromScore(p, score);
      }

      expect(starsFor(300), 3);
      expect(starsFor(270), 3);
      expect(starsFor(269), 2);
      expect(starsFor(180), 2);
      expect(starsFor(179), 1);
    });
  });

  group('andamento', () {
    test('nextWord só funciona em solved', () {
      final p = tiny();
      var notified = 0;
      p.addListener(() => notified++);
      p.nextWord();
      expect(p.index, 0);
      expect(notified, 0);
    });

    test('nextWord avança e zera o estado da palavra', () {
      final p = tiny();
      split(p);
      p.chooseStress(wrongStressOf(p));
      p.chooseStress(p.word!.stressIndex);
      p.chooseClass(wrongClassOf(p));
      p.chooseClass(p.word!.stressClass);
      p.nextWord();
      expect(p.index, 1);
      expect(p.step, SilabasStep.split);
      expect(p.cuts, isEmpty);
      expect(p.wrongCuts, isEmpty);
      expect(p.missingHint, isNull);
      expect(p.wrongStress, isEmpty);
      expect(p.wrongClasses, isEmpty);
      expect(p.wordPoints, 0);
    });

    test('a 10a palavra leva ao fim e mantém a palavra', () {
      final p = started();
      for (var i = 0; i < 10; i++) {
        expect(p.index, i);
        expect(p.isLastWord, i == 9);
        solve(p);
        if (i == 9) {
          final last = p.word!.text;
          p.nextWord();
          expect(p.phase, SilabasPhase.finished);
          expect(p.word!.text, last);
        } else {
          p.nextWord();
        }
      }
      expect(p.score, 300);
      expect(p.stars, 3);
    });

    test('playAgain só no fim: mesmo nível, zerado, novas palavras', () {
      final p = started(level: 1);
      p.playAgain();
      expect(p.index, 0);
      for (var i = 0; i < 10; i++) {
        solve(p);
        p.nextWord();
      }
      expect(p.phase, SilabasPhase.finished);
      p.playAgain();
      expect(p.phase, SilabasPhase.playing);
      expect(p.level, 1);
      expect(p.score, 0);
      expect(p.index, 0);
      expect(p.step, SilabasStep.split);
      expect(p.wordCount, 10);
    });

    test('exitToSetup volta à escolha mantendo o nível', () {
      final p = started(level: 2);
      split(p);
      p.exitToSetup();
      expect(p.phase, SilabasPhase.setup);
      expect(p.level, 2);
      expect(p.word, isNull);
      expect(p.score, 0);
      expect(p.cuts, isEmpty);
      p.start(2);
      expect(p.phase, SilabasPhase.playing);
      for (var i = 0; i < 10; i++) {
        solve(p);
        p.nextWord();
      }
      p.exitToSetup();
      expect(p.phase, SilabasPhase.setup);
      expect(p.level, 2);
    });
  });

  group('guardas', () {
    test('na escolha de nível, nada funciona nem notifica', () {
      final p = SilabasProvider();
      var notified = 0;
      p.addListener(() => notified++);
      p.toggleCut(1);
      p.checkSplit();
      p.chooseStress(0);
      p.chooseClass(StressClass.oxitona);
      p.nextWord();
      p.playAgain();
      p.exitToSetup();
      expect(p.phase, SilabasPhase.setup);
      expect(notified, 0);
    });

    test('métodos fora da etapa são ignorados', () {
      final p = tiny();
      var notified = 0;
      p.addListener(() => notified++);
      p.chooseStress(0);
      p.chooseClass(StressClass.oxitona);
      p.nextWord();
      p.playAgain();
      expect(p.step, SilabasStep.split);
      expect(notified, 0);

      split(p);
      notified = 0;
      p.toggleCut(1);
      p.checkSplit();
      p.chooseClass(StressClass.oxitona);
      expect(p.step, SilabasStep.stress);
      expect(notified, 0);

      p.chooseStress(p.word!.stressIndex);
      notified = 0;
      p.chooseStress(0);
      p.nextWord();
      expect(p.step, SilabasStep.classify);
      expect(notified, 0);

      p.chooseClass(p.word!.stressClass);
      notified = 0;
      p.toggleCut(1);
      p.checkSplit();
      p.chooseStress(0);
      p.chooseClass(StressClass.oxitona);
      expect(p.step, SilabasStep.solved);
      expect(notified, 0);
    });

    test('depois do fim, só playAgain e exitToSetup funcionam', () {
      final p = SilabasProvider(
        random: Random(1),
        words: {
          0: ['BO-la'],
        },
      )..start(0);
      solve(p);
      p.nextWord();
      expect(p.phase, SilabasPhase.finished);
      var notified = 0;
      p.addListener(() => notified++);
      p.toggleCut(1);
      p.checkSplit();
      p.chooseStress(0);
      p.chooseClass(StressClass.oxitona);
      p.nextWord();
      p.start(1);
      expect(p.phase, SilabasPhase.finished);
      expect(notified, 0);
    });
  });
}

int _starsFromScore(SilabasProvider p, int score) {
  // Joga partidas com erros controlados até chegar na pontuação pedida.
  // Cada etapa vale 10, 5 ou 2: 300 = tudo perfeito; para outros valores,
  // monta a combinação certa de etapas.
  final q = SilabasProvider(
    random: Random(1),
    words: {0: List.generate(10, (_) => 'ja-NE-la')},
  )..start(0);
  return _drive(q, score);
}

int _drive(SilabasProvider q, int target) {
  // 30 etapas no total. Escolhe quantas valem 10, 5 e 2 para somar target.
  for (var fives = 0; fives <= 30; fives++) {
    for (var twos = 0; twos + fives <= 30; twos++) {
      final tens = 30 - fives - twos;
      if (tens * 10 + fives * 5 + twos * 2 == target) {
        _play(q, tens, fives, twos);
        return q.stars;
      }
    }
  }
  fail('pontuação $target inalcançável');
}

void _play(SilabasProvider q, int tens, int fives, int twos) {
  // Etapa de erros: a tônica de 'ja-NE-la' tem 2 erradas (0 e 2); a de
  // classificar tem 2 erradas; a de separar aceita quantos erros quiser.
  final plan = [
    ...List.filled(tens, 0),
    ...List.filled(fives, 1),
    ...List.filled(twos, 2),
  ];
  var k = 0;
  while (q.phase == SilabasPhase.playing) {
    for (final step in SilabasStep.values.take(3)) {
      final errs = plan[k++];
      switch (step) {
        case SilabasStep.split:
          for (var e = 0; e < errs; e++) {
            q.toggleCut(badCut(q));
            q.checkSplit();
            q.toggleCut(badCut(q));
          }
          for (final c in q.word!.cutPositions) {
            q.toggleCut(c);
          }
          q.checkSplit();
        case SilabasStep.stress:
          final wrong = [0, 2];
          for (var e = 0; e < errs; e++) {
            q.chooseStress(wrong[e]);
          }
          q.chooseStress(q.word!.stressIndex);
        default:
          final wrong = StressClass.values
              .where((c) => c != q.word!.stressClass)
              .toList();
          for (var e = 0; e < errs; e++) {
            q.chooseClass(wrong[e]);
          }
          q.chooseClass(q.word!.stressClass);
      }
    }
    q.nextWord();
  }
}
