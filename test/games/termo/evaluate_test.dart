// test/games/termo/evaluate_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/logic/daily.dart';
import 'package:brincaki/games/termo/logic/evaluate.dart';

const c = LetterResult.correct;
const p = LetterResult.present;
const a = LetterResult.absent;

void main() {
  group('evaluateGuess', () {
    test('todas certas', () {
      expect(evaluateGuess('CARRO', 'CARRO'), [c, c, c, c, c]);
    });

    test('nenhuma letra na palavra', () {
      expect(evaluateGuess('TUMBI', 'CARRO'), [a, a, a, a, a]);
    });

    test('letras no lugar errado', () {
      expect(evaluateGuess('ROCAR', 'CARRO'), [p, p, p, p, p]);
    });

    test('repetidas: só colore quantas a resposta tem (ARARA × CARRO)', () {
      expect(evaluateGuess('ARARA', 'CARRO'), [p, p, a, c, a]);
    });

    test('repetidas: verdes contam primeiro (SALAS × ASSAR)', () {
      expect(evaluateGuess('SALAS', 'ASSAR'), [p, p, a, c, p]);
    });
  });

  group('dailyAnswer', () {
    final bank = WordBank(
      valid: {for (final w in ['CARRO', 'PEDRA', 'AVIAO', 'TERMO']) w: w},
      answers: ['CARRO', 'PEDRA', 'AVIAO', 'TERMO'],
    );

    test('mesma data, mesma palavra (ignora a hora)', () {
      expect(dailyAnswer(bank, DateTime(2026, 10, 4, 8)),
          dailyAnswer(bank, DateTime(2026, 10, 4, 23, 59)));
    });

    test('dias seguidos têm palavras diferentes', () {
      for (var d = 0; d < 30; d++) {
        final day = DateTime(2026, 3, 1).add(Duration(days: d));
        expect(dailyAnswer(bank, day),
            isNot(dailyAnswer(bank, day.add(const Duration(days: 1)))));
      }
    });

    test('dateKey', () {
      expect(dateKey(DateTime(2026, 1, 5, 13)), '2026-01-05');
    });
  });
}
