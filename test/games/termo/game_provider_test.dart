// test/games/termo/game_provider_test.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/termo/data/daily_store.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/logic/daily.dart';
import 'package:brincaki/games/termo/logic/evaluate.dart';
import 'package:brincaki/games/termo/models/game_state.dart';
import 'package:brincaki/games/termo/providers/game_provider.dart';

class MemoryDailyStore implements DailyStore {
  MemoryDailyStore([this.state]);
  DailyState? state;
  int saves = 0;
  Completer<DailyState?>? pendingLoad;

  @override
  Future<DailyState?> load() => pendingLoad?.future ?? Future.value(state);

  @override
  Future<void> save(DailyState s) async {
    state = s;
    saves++;
  }
}

final bank = WordBank(
  valid: {
    'CARRO': 'CARRO', 'PEDRA': 'PEDRA', 'AVIAO': 'AVIÃO', 'TERMO': 'TERMO',
    'ARARA': 'ARARA', 'PORTA': 'PORTA', 'MESAS': 'MESAS', 'ROCAR': 'ROÇAR',
  },
  answers: ['CARRO', 'PEDRA', 'AVIAO', 'TERMO'],
);

final day1 = DateTime(2026, 10, 4, 10);
final day2 = DateTime(2026, 10, 5, 9);

Future<void> settle(TermoProvider p) async {
  while (p.loading) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<TermoProvider> ready({
  WordBank? words,
  MemoryDailyStore? store,
  DateTime? now,
  Random? random,
}) async {
  final provider = TermoProvider(
    bank: Future.value(words ?? bank),
    store: store ?? MemoryDailyStore(),
    now: () => now ?? day1,
    random: random ?? Random(1),
  );
  await settle(provider);
  return provider;
}

/// Banco com uma resposta só, para saber qual é a palavra.
Future<TermoProvider> withAnswer(String answer, Map<String, String> valid) => ready(
      words: WordBank(valid: {answer: answer, ...valid}, answers: [answer]),
    );

void typeWord(TermoProvider p, String word) {
  for (final letter in word.split('')) {
    p.type(letter);
  }
}

void guess(TermoProvider p, String word) {
  typeWord(p, word);
  p.submit();
}

/// Uma palavra válida que não é a resposta.
String wrongWord(TermoProvider p) =>
    ['PORTA', 'MESAS', 'ARARA'].firstWhere((w) => w != p.answer);

void main() {
  group('carregamento', () {
    test('fica carregando até o banco de palavras chegar', () async {
      final words = Completer<WordBank>();
      final p = TermoProvider(
        bank: words.future,
        store: MemoryDailyStore(),
        now: () => day1,
      );
      expect(p.loading, isTrue);
      // Nada funciona enquanto carrega.
      p.type('A');
      p.backspace();
      p.submit();
      await p.setMode(TermoMode.unlimited);
      expect(p.current, '');
      expect(p.mode, TermoMode.daily);
      expect(p.display('AVIAO'), 'AVIAO');

      words.complete(bank);
      await settle(p);
      expect(p.loading, isFalse);
      expect(p.display('AVIAO'), 'AVIÃO');
    });

    test('começa na palavra do dia', () async {
      final p = await ready();
      expect(p.mode, TermoMode.daily);
      expect(p.answer, dailyAnswer(bank, day1));
      expect(p.phase, TermoPhase.playing);
      expect(p.guesses, isEmpty);
      expect(p.current, '');
      expect(p.lastError, isNull);
      expect(p.shakeCount, 0);
      expect(p.keyboard, isEmpty);
    });

    test('avisa quando termina de carregar', () async {
      var notified = 0;
      final p = TermoProvider(
        bank: Future.value(bank),
        store: MemoryDailyStore(),
        now: () => day1,
      )..addListener(() => notified++);
      await settle(p);
      expect(notified, 1);
    });

    test('descartar antes do banco chegar não avisa depois', () async {
      final words = Completer<WordBank>();
      final store = MemoryDailyStore();
      final p = TermoProvider(bank: words.future, store: store, now: () => day1);
      p.dispose();
      words.complete(bank);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(p.loading, isTrue);
    });

    test('descartar durante a leitura do dia salvo não avisa depois', () async {
      final store = MemoryDailyStore()..pendingLoad = Completer<DailyState?>();
      final p = TermoProvider(bank: Future.value(bank), store: store, now: () => day1);
      await Future<void>.delayed(Duration.zero);
      p.dispose();
      store.pendingLoad!.complete(DailyState(date: dateKey(day1), guesses: const ['PORTA']));
      await Future<void>.delayed(Duration.zero);
      expect(p.loading, isTrue);
    });
  });

  group('digitar', () {
    test('no máximo 5 letras, aceita acento e minúscula', () async {
      final p = await ready();
      typeWord(p, 'avião');
      expect(p.current, 'AVIAO');
      var notified = 0;
      p.addListener(() => notified++);
      p.type('X');
      expect(p.current, 'AVIAO');
      expect(notified, 0);
    });

    test('ignora o que não é uma letra só', () async {
      final p = await ready();
      p.type('1');
      p.type(' ');
      p.type('AB');
      p.type('');
      p.type('-');
      expect(p.current, '');
    });

    test('backspace apaga a última letra e não faz nada se vazio', () async {
      final p = await ready();
      typeWord(p, 'CAR');
      p.backspace();
      expect(p.current, 'CA');
      p.backspace();
      p.backspace();
      var notified = 0;
      p.addListener(() => notified++);
      p.backspace();
      expect(p.current, '');
      expect(notified, 0);
    });

    test('digitar apaga o aviso de erro', () async {
      final p = await ready();
      p.submit();
      expect(p.lastError, isNotNull);
      p.type('C');
      expect(p.lastError, isNull);
    });
  });

  group('enviar', () {
    test('menos de 5 letras e palavra inválida dão erro e tremor', () async {
      final p = await ready();
      typeWord(p, 'CAR');
      p.submit();
      expect(p.lastError, 'Só palavras com 5 letras');
      expect(p.shakeCount, 1);
      typeWord(p, 'XY');
      p.submit();
      expect(p.lastError, 'Palavra inválida');
      expect(p.shakeCount, 2);
      expect(p.guesses, isEmpty);
      // A palavra errada continua digitada para corrigir.
      expect(p.current, 'CARXY');
    });

    test('vazio também dá erro', () async {
      final p = await ready();
      p.submit();
      expect(p.lastError, 'Só palavras com 5 letras');
    });

    test('tentativa válida entra na lista, limpa o atual e o erro', () async {
      final p = await ready();
      p.submit();
      final wrong = wrongWord(p);
      guess(p, wrong);
      expect(p.guesses, [wrong]);
      expect(p.current, '');
      expect(p.lastError, isNull);
      expect(p.phase, TermoPhase.playing);
    });

    test('guesses não pode ser alterada de fora', () async {
      final p = await ready();
      expect(() => p.guesses.add('PORTA'), throwsUnsupportedError);
    });

    test('acertar vence e salva o dia', () async {
      final store = MemoryDailyStore();
      final p = await ready(store: store);
      guess(p, p.answer);
      expect(p.phase, TermoPhase.won);
      expect(store.state!.date, '2026-10-04');
      expect(store.state!.guesses, [p.answer]);
    });

    test('salva o dia a cada tentativa', () async {
      final store = MemoryDailyStore();
      final p = await ready(store: store);
      final wrong = wrongWord(p);
      guess(p, wrong);
      guess(p, wrong);
      expect(store.saves, 2);
      expect(store.state!.guesses, [wrong, wrong]);
    });

    test('6 erros perdem', () async {
      final p = await ready();
      for (var i = 0; i < TermoProvider.maxGuesses; i++) {
        expect(p.phase, TermoPhase.playing);
        guess(p, wrongWord(p));
      }
      expect(p.phase, TermoPhase.lost);
      expect(p.guesses.length, TermoProvider.maxGuesses);
      expect(p.answerDisplay, bank.display(p.answer));
    });

    test('acertar na sexta tentativa ainda vence', () async {
      final p = await ready();
      for (var i = 0; i < TermoProvider.maxGuesses - 1; i++) {
        guess(p, wrongWord(p));
      }
      guess(p, p.answer);
      expect(p.phase, TermoPhase.won);
    });

    test('depois do fim nada mais entra', () async {
      final p = await ready();
      guess(p, p.answer);
      var notified = 0;
      p.addListener(() => notified++);
      p.type('A');
      p.backspace();
      p.submit();
      expect(p.current, '');
      expect(p.guesses.length, 1);
      expect(notified, 0);
    });
  });

  group('teclado', () {
    test('guarda o melhor resultado de cada letra', () async {
      final p = await ready();
      await p.setMode(TermoMode.unlimited);
      final answer = p.answer;
      for (final word in ['ARARA', 'CARRO', 'PORTA']) {
        if (word == answer || p.phase != TermoPhase.playing) continue;
        guess(p, word);
      }
      for (final entry in p.keyboard.entries) {
        final best = p.guesses
            .expand((g) => [
                  for (var i = 0; i < 5; i++)
                    if (g[i] == entry.key) evaluateGuess(g, answer)[i],
                ])
            .reduce((x, y) => x.index < y.index ? x : y);
        expect(entry.value, best, reason: entry.key);
      }
    });

    test('verde não volta a ser amarelo; amarelo não volta a ser cinza', () async {
      final p = await withAnswer('CARRO', {'PORTA': 'PORTA', 'ROCAR': 'ROÇAR', 'TUMBI': 'TUMBI'});
      expect(p.answer, 'CARRO');
      guess(p, 'PORTA'); // R na posição certa: verde; O amarelo
      guess(p, 'ROCAR'); // R só em posições erradas
      expect(p.keyboard['R'], LetterResult.correct);
      expect(p.keyboard['O'], LetterResult.present);
      expect(p.keyboard['P'], LetterResult.absent);
      expect(p.keyboard['T'], LetterResult.absent);
    });

    test('amarelo melhora para verde', () async {
      final p = await withAnswer('CARRO', {'ROCAR': 'ROÇAR', 'PORTA': 'PORTA'});
      guess(p, 'ROCAR');
      expect(p.keyboard['C'], LetterResult.present);
      guess(p, 'CARRO');
      expect(p.keyboard['C'], LetterResult.correct);
    });
  });

  group('display e shown', () {
    test('display usa a forma acentuada do banco', () async {
      final p = await ready();
      expect(p.display('AVIAO'), 'AVIÃO');
      expect(p.display('ZZZZZ'), 'ZZZZZ');
    });

    test('answerDisplay mostra a resposta com acento', () async {
      final q = await ready(
        words: WordBank(valid: const {'AVIAO': 'AVIÃO'}, answers: const ['AVIAO']),
      );
      expect(q.answerDisplay, 'AVIÃO');
    });

    test('letra verde mostra a grafia da resposta; amarela e cinza, a da tentativa',
        () async {
      final p = await ready(
        words: WordBank(
          valid: const {'CASAL': 'CASAL', 'MACAS': 'MAÇÃS'},
          answers: const ['CASAL'],
        ),
      );
      guess(p, 'MACAS');
      // M cinza, A verde, C amarelo, A verde, S amarelo.
      expect(p.resultsFor('MACAS'), [
        LetterResult.absent,
        LetterResult.correct,
        LetterResult.present,
        LetterResult.correct,
        LetterResult.present,
      ]);
      // O Ç amarelo fica como na tentativa; o Ã verde vira o A da resposta.
      expect(p.shown('MACAS'), 'MAÇAS');
    });

    test('letra verde ganha o acento da resposta', () async {
      final p = await ready(
        words: WordBank(
          valid: const {'AVIAO': 'AVIÃO', 'MAMAO': 'MAMAO'},
          answers: const ['AVIAO'],
        ),
      );
      expect(p.shown('MAMAO'), 'MAMÃO');
    });

    test('letra verde sem acento na resposta perde o da tentativa', () async {
      final p = await ready(
        words: WordBank(
          valid: const {'CASAL': 'CASAL', 'AVIAO': 'AVIÃO'},
          answers: const ['CASAL'],
        ),
      );
      expect(p.resultsFor('AVIAO')[3], LetterResult.correct);
      expect(p.shown('AVIAO'), 'AVIAO');
    });

    test('tentativa toda cinza aparece como no banco', () async {
      final p = await ready(
        words: WordBank(
          valid: const {'CARRO': 'CARRO', 'BUQUE': 'BUQUÊ'},
          answers: const ['CARRO'],
        ),
      );
      expect(p.shown('BUQUE'), 'BUQUÊ');
    });
  });

  group('palavra do dia salva', () {
    test('reabrir no mesmo dia restaura as tentativas', () async {
      final store = MemoryDailyStore();
      final first = await ready(store: store);
      final wrong = wrongWord(first);
      guess(first, wrong);

      final again = await ready(store: store);
      expect(again.guesses, [wrong]);
      expect(again.phase, TermoPhase.playing);
    });

    test('vitória continua vitória ao reabrir', () async {
      final store = MemoryDailyStore();
      final first = await ready(store: store);
      guess(first, first.answer);

      final again = await ready(store: store);
      expect(again.phase, TermoPhase.won);
      again.type('A');
      expect(again.current, '');
    });

    test('derrota continua derrota ao reabrir', () async {
      final store = MemoryDailyStore();
      final first = await ready(store: store);
      for (var i = 0; i < TermoProvider.maxGuesses; i++) {
        guess(first, wrongWord(first));
      }
      final again = await ready(store: store);
      expect(again.phase, TermoPhase.lost);
    });

    test('novo dia começa do zero', () async {
      final store = MemoryDailyStore(
          const DailyState(date: '2026-10-04', guesses: ['PORTA']));
      final p = await ready(store: store, now: day2);
      expect(p.guesses, isEmpty);
      expect(p.answer, dailyAnswer(bank, day2));
    });

    test('palavras fora do dicionário são ignoradas', () async {
      final store = MemoryDailyStore(
          const DailyState(date: '2026-10-04', guesses: ['ZZZZZ', 'PORTA']));
      final p = await ready(store: store);
      expect(p.guesses, ['PORTA']);
    });

    test('mais de 6 tentativas salvas ficam só as 6 primeiras', () async {
      final store = MemoryDailyStore(DailyState(
        date: '2026-10-04',
        guesses: List.filled(9, 'PORTA'),
      ));
      final p = await ready(store: store, words: WordBank(
        valid: const {'PORTA': 'PORTA', 'CARRO': 'CARRO'},
        answers: const ['CARRO'],
      ));
      expect(p.guesses.length, TermoProvider.maxGuesses);
      expect(p.phase, TermoPhase.lost);
    });

    test('não salva nada só por abrir', () async {
      final store = MemoryDailyStore();
      await ready(store: store);
      expect(store.saves, 0);
    });
  });

  group('modos', () {
    test('ilimitado sorteia entre as respostas e não salva', () async {
      final store = MemoryDailyStore();
      final p = await ready(store: store);
      var notified = 0;
      p.addListener(() => notified++);
      await p.setMode(TermoMode.unlimited);
      expect(p.mode, TermoMode.unlimited);
      expect(bank.answers, contains(p.answer));
      expect(notified, 1);
      guess(p, p.answer);
      expect(p.phase, TermoPhase.won);
      expect(store.saves, 0);
    });

    test('ilimitado começa limpo mesmo com tentativas do dia', () async {
      final p = await ready();
      guess(p, wrongWord(p));
      typeWord(p, 'CA');
      p.submit(); // deixa letras digitadas e um erro
      expect(p.lastError, isNotNull);
      await p.setMode(TermoMode.unlimited);
      expect(p.guesses, isEmpty);
      expect(p.current, '');
      expect(p.lastError, isNull);
      expect(p.phase, TermoPhase.playing);
    });

    test('escolher o modo atual não faz nada', () async {
      final p = await ready();
      var notified = 0;
      p.addListener(() => notified++);
      await p.setMode(TermoMode.daily);
      expect(notified, 0);
      await p.setMode(TermoMode.unlimited);
      final answer = p.answer;
      await p.setMode(TermoMode.unlimited);
      expect(p.answer, answer);
    });

    test('voltar ao modo diário recarrega e restaura o dia', () async {
      final store = MemoryDailyStore();
      final p = await ready(store: store);
      final wrong = wrongWord(p);
      guess(p, wrong);
      await p.setMode(TermoMode.unlimited);

      final states = <bool>[];
      p.addListener(() => states.add(p.loading));
      await p.setMode(TermoMode.daily);
      expect(states, [true, false]);
      expect(p.mode, TermoMode.daily);
      expect(p.guesses, [wrong]);
      expect(p.answer, dailyAnswer(bank, day1));
    });

    test('newUnlimited sorteia outra palavra depois de terminar', () async {
      final p = await ready(random: Random(5));
      await p.setMode(TermoMode.unlimited);
      guess(p, p.answer);
      var notified = 0;
      p.addListener(() => notified++);
      p.newUnlimited();
      expect(p.phase, TermoPhase.playing);
      expect(p.guesses, isEmpty);
      expect(bank.answers, contains(p.answer));
      expect(notified, 1);
    });

    test('newUnlimited funciona depois de perder', () async {
      final p = await ready();
      await p.setMode(TermoMode.unlimited);
      for (var i = 0; i < TermoProvider.maxGuesses; i++) {
        guess(p, wrongWord(p));
      }
      expect(p.phase, TermoPhase.lost);
      p.newUnlimited();
      expect(p.phase, TermoPhase.playing);
    });

    test('newUnlimited é ignorado no meio da partida e no modo diário', () async {
      final p = await ready();
      guess(p, p.answer);
      p.newUnlimited(); // diário terminado: continua igual
      expect(p.phase, TermoPhase.won);
      expect(p.mode, TermoMode.daily);

      await p.setMode(TermoMode.unlimited);
      final wrong = wrongWord(p);
      guess(p, wrong);
      p.newUnlimited(); // ainda jogando
      expect(p.guesses, [wrong]);
    });
  });
}
