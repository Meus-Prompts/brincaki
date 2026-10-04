// test/games/termo/word_data_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/logic/normalize.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalizeWord tira acentos e põe em maiúsculas', () {
    expect(normalizeWord('avião'), 'AVIAO');
    expect(normalizeWord('Açúcar'), 'ACUCAR');
    expect(normalizeWord('ÔNIBUS'), 'ONIBUS');
  });

  test('WordBank em memória', () {
    final bank = WordBank(
      valid: {'AVIAO': 'AVIÃO', 'CARRO': 'CARRO'},
      answers: ['CARRO'],
    );
    expect(bank.isValid('AVIAO'), isTrue);
    expect(bank.isValid('ZZZZZ'), isFalse);
    expect(bank.display('AVIAO'), 'AVIÃO');
    expect(bank.display('ZZZZZ'), 'ZZZZZ');
    expect(bank.answers, ['CARRO']);
  });

  test('listas reais do app são válidas', () async {
    final bank = await WordBank.load(rootBundle);
    final five = RegExp(r'^[A-Z]{5}$');

    expect(bank.answers.length, greaterThanOrEqualTo(500));
    expect(bank.validCount, greaterThanOrEqualTo(3000));
    expect(bank.answers.toSet().length, bank.answers.length,
        reason: 'resposta repetida');
    for (final answer in bank.answers) {
      expect(answer, matches(five));
      expect(bank.isValid(answer), isTrue, reason: answer);
      final shown = bank.display(answer);
      expect(shown.length, 5, reason: shown);
      expect(normalizeWord(shown), answer, reason: shown);
    }
  });

  test('plurais e femininos comuns são aceitos como tentativa', () async {
    final bank = await WordBank.load(rootBundle);
    for (final word in ['GATOS', 'MESAS', 'RATOS', 'OUTRA', 'CASAS', 'BOLAS']) {
      expect(bank.isValid(word), isTrue, reason: word);
    }
  });

  test('respostas não incluem palavras impróprias para a família', () async {
    final bank = await WordBank.load(rootBundle);
    for (final word in ['NEGRO', 'NEGRA', 'INDIO', 'BURRO', 'BESTA', 'PERUA', 'ESSES']) {
      expect(bank.answers, isNot(contains(word)), reason: word);
    }
  });
}
