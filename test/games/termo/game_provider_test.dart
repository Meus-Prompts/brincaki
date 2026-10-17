// test/games/termo/game_provider_test.dart

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

  @override
  Future<DailyState?> load() async => state;

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

Future<TermoProvider> ready({
  MemoryDailyStore? store,
  DateTime? now,
  Random? random,
}) async {
  final provider = TermoProvider(
    bank: Future.value(bank),
    store: store ?? MemoryDailyStore(),
    now: () => now ?? day1,
    random: random ?? Random(1),
  );
  while (provider.loading) {
    await Future<void>.delayed(Duration.zero);
  }
  return provider;
}

void typeWord(TermoProvider p, String word) {
  for (final letter in word.split('')) {
    p.type(letter);
  }
}

/// Uma palavra válida que não é a resposta.
String wrongWord(TermoProvider p) =>
    ['PORTA', 'MESAS', 'ARARA'].firstWhere((w) => w != p.answer);

void main() {
  test('começa na palavra do dia', () async {
    final p = await ready();
    expect(p.mode, TermoMode.daily);
    expect(p.answer, dailyAnswer(bank, day1));
    expect(p.phase, TermoPhase.playing);
  });

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
  });

  test('digitar: no máximo 5 letras, aceita acento, backspace apaga', () async {
    final p = await ready();
    typeWord(p, 'avião');
    p.type('X');
    expect(p.current, 'AVIAO');
    p.backspace();
    expect(p.current, 'AVIA');
    p.type('1');
    expect(p.current, 'AVIA');
  });

  test('acertar vence e salva o dia', () async {
    final store = MemoryDailyStore();
    final p = await ready(store: store);
    typeWord(p, p.answer);
    p.submit();
    expect(p.phase, TermoPhase.won);
    expect(store.state!.date, '2026-10-04');
    expect(store.state!.guesses, [p.answer]);
    p.type('A'); // fim de jogo: nada mais entra
    expect(p.current, '');
  });

  test('6 erros perdem', () async {
    final p = await ready();
    for (var i = 0; i < TermoProvider.maxGuesses; i++) {
      typeWord(p, wrongWord(p));
      p.submit();
    }
    expect(p.phase, TermoPhase.lost);
    expect(p.answerDisplay, bank.display(p.answer));
  });

  test('teclado guarda o melhor resultado de cada letra', () async {
    final p = await ready();
    // Resposta fixa para o teste: modo ilimitado com o primeiro sorteio.
    await p.setMode(TermoMode.unlimited);
    final answer = p.answer;
    for (final guess in ['ARARA', 'CARRO', 'PORTA']) {
      if (guess == answer || p.phase != TermoPhase.playing) continue;
      typeWord(p, guess);
      p.submit();
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

  test('letra verde não volta a ser amarela no teclado', () async {
    final onlyCarro = WordBank(
      valid: {'CARRO': 'CARRO', 'PORTA': 'PORTA', 'ROCAR': 'ROÇAR'},
      answers: ['CARRO'],
    );
    final p = TermoProvider(
      bank: Future.value(onlyCarro),
      store: MemoryDailyStore(),
      now: () => day1,
      random: Random(1),
    );
    while (p.loading) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(p.answer, 'CARRO');
    typeWord(p, 'PORTA'); // R na posição certa: verde
    p.submit();
    typeWord(p, 'ROCAR'); // R só em posições erradas: amarelo
    p.submit();
    expect(p.keyboard['R'], LetterResult.correct);
    expect(p.keyboard['O'], LetterResult.present);
  });

  test('letra verde aparece como na resposta, sem acento da tentativa', () async {
    final onlyCasal = WordBank(
      valid: {'CASAL': 'CASAL', 'AVIAO': 'AVIÃO'},
      answers: ['CASAL'],
    );
    final p = TermoProvider(
      bank: Future.value(onlyCasal),
      store: MemoryDailyStore(),
      now: () => day1,
      random: Random(1),
    );
    while (p.loading) {
      await Future<void>.delayed(Duration.zero);
    }
    typeWord(p, 'AVIAO'); // o A da posição 4 é verde: CASAL não tem Ã
    p.submit();
    expect(p.resultsFor('AVIAO')[3], LetterResult.correct);
    expect(p.shown('AVIAO'), 'AVIAO');
  });

  test('reabrir no mesmo dia restaura as tentativas', () async {
    final store = MemoryDailyStore();
    final first = await ready(store: store);
    final wrong = wrongWord(first);
    typeWord(first, wrong);
    first.submit();

    final again = await ready(store: store);
    expect(again.guesses, [wrong]);
    expect(again.phase, TermoPhase.playing);
  });

  test('palavra do dia terminada continua terminada ao reabrir', () async {
    final store = MemoryDailyStore();
    final first = await ready(store: store);
    typeWord(first, first.answer);
    first.submit();

    final again = await ready(store: store);
    expect(again.phase, TermoPhase.won);
    again.type('A');
    expect(again.current, '');
  });

  test('novo dia começa do zero', () async {
    final store = MemoryDailyStore(
        DailyState(date: '2026-10-04', guesses: const ['PORTA']));
    final p = await ready(store: store, now: day2);
    expect(p.guesses, isEmpty);
    expect(p.answer, dailyAnswer(bank, day2));
  });

  test('estado salvo com palavras fora do dicionário é ignorado', () async {
    final store = MemoryDailyStore(
        DailyState(date: '2026-10-04', guesses: const ['ZZZZZ', 'PORTA']));
    final p = await ready(store: store);
    expect(p.guesses, ['PORTA']);
  });

  test('ilimitado não salva e sorteia nova palavra ao terminar', () async {
    final store = MemoryDailyStore();
    final p = await ready(store: store);
    await p.setMode(TermoMode.unlimited);
    typeWord(p, p.answer);
    p.submit();
    expect(p.phase, TermoPhase.won);
    expect(store.saves, 0);
    p.newUnlimited();
    expect(p.phase, TermoPhase.playing);
    expect(p.guesses, isEmpty);
  });

  test('voltar ao modo diário restaura o dia', () async {
    final store = MemoryDailyStore();
    final p = await ready(store: store);
    final wrong = wrongWord(p);
    typeWord(p, wrong);
    p.submit();
    await p.setMode(TermoMode.unlimited);
    await p.setMode(TermoMode.daily);
    expect(p.guesses, [wrong]);
    expect(p.answer, dailyAnswer(bank, day1));
  });

  test('DailyState.fromJson rejeita lixo', () {
    expect(DailyState.fromJson('oi'), isNull);
    expect(DailyState.fromJson({'date': 1}), isNull);
    final s = DailyState.fromJson({'date': '2026-10-04', 'guesses': ['PORTA', 3]});
    expect(s!.guesses, ['PORTA']);
  });
}
