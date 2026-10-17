// test/games/termo/daily_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/logic/daily.dart';

void main() {
  final words = ['CARRO', 'PEDRA', 'AVIAO', 'TERMO', 'PORTA', 'MESAS', 'GATOS'];
  final bank = WordBank(valid: {for (final w in words) w: w}, answers: words);

  group('dailyAnswer', () {
    test('mesma data, mesma palavra (ignora a hora)', () {
      expect(dailyAnswer(bank, DateTime(2026, 10, 4, 0, 0)),
          dailyAnswer(bank, DateTime(2026, 10, 4, 23, 59, 59)));
    });

    test('data local e UTC do mesmo dia dão a mesma palavra', () {
      expect(dailyAnswer(bank, DateTime(2026, 10, 4, 12)),
          dailyAnswer(bank, DateTime.utc(2026, 10, 4, 12)));
    });

    test('é sempre uma das respostas', () {
      for (var d = 0; d < 60; d++) {
        final day = DateTime(2026, 1, 1).add(Duration(days: d));
        expect(words, contains(dailyAnswer(bank, day)));
      }
    });

    test('dias seguidos têm palavras diferentes', () {
      for (var d = 0; d < 30; d++) {
        final day = DateTime(2026, 3, 1).add(Duration(days: d));
        expect(dailyAnswer(bank, day),
            isNot(dailyAnswer(bank, day.add(const Duration(days: 1)))));
      }
    });

    test('um ciclo inteiro usa cada resposta uma vez', () {
      final cycle = {
        for (var d = 0; d < words.length; d++)
          dailyAnswer(bank, DateTime(2026, 5, 1).add(Duration(days: d))),
      };
      expect(cycle, words.toSet());
    });

    test('depois de um ciclo inteiro a palavra se repete', () {
      final day = DateTime(2026, 6, 10);
      expect(dailyAnswer(bank, day.add(Duration(days: words.length))),
          dailyAnswer(bank, day));
    });

    test('virada de ano: 31/12 e 1/1 têm palavras diferentes', () {
      expect(dailyAnswer(bank, DateTime(2026, 12, 31)),
          isNot(dailyAnswer(bank, DateTime(2027, 1, 1))));
      expect(words, contains(dailyAnswer(bank, DateTime(2027, 1, 1))));
    });

    test('ano bissexto e datas antes do início também funcionam', () {
      expect(words, contains(dailyAnswer(bank, DateTime(2028, 2, 29))));
      expect(words, contains(dailyAnswer(bank, DateTime(2025, 12, 31))));
      expect(dailyAnswer(bank, DateTime(2025, 12, 31)),
          isNot(dailyAnswer(bank, DateTime(2026, 1, 1))));
    });

    test('não muda a ordem das respostas do banco', () {
      dailyAnswer(bank, DateTime(2026, 10, 4));
      expect(bank.answers, words);
    });
  });

  group('dateKey', () {
    test('formata como yyyy-MM-dd com zeros', () {
      expect(dateKey(DateTime(2026, 1, 5, 13)), '2026-01-05');
      expect(dateKey(DateTime(2026, 12, 31)), '2026-12-31');
      expect(dateKey(DateTime(987, 3, 4)), '0987-03-04');
    });

    test('ignora a hora', () {
      expect(dateKey(DateTime(2026, 10, 4, 0, 1)), dateKey(DateTime(2026, 10, 4, 23, 59)));
    });
  });
}
