// test/games/termo/normalize_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/termo/logic/normalize.dart';

void main() {
  group('normalizeWord', () {
    test('põe em maiúsculas', () {
      expect(normalizeWord('carro'), 'CARRO');
      expect(normalizeWord('CaRrO'), 'CARRO');
    });

    test('tira o til, o acento agudo e o circunflexo', () {
      expect(normalizeWord('avião'), 'AVIAO');
      expect(normalizeWord('ÔNIBUS'), 'ONIBUS');
      expect(normalizeWord('Açúcar'), 'ACUCAR');
      expect(normalizeWord('café'), 'CAFE');
      expect(normalizeWord('você'), 'VOCE');
    });

    test('cobre todas as vogais acentuadas, o Ç e o Ñ', () {
      expect(normalizeWord('áàâãä'), 'AAAAA');
      expect(normalizeWord('éèêë'), 'EEEE');
      expect(normalizeWord('íìîï'), 'IIII');
      expect(normalizeWord('óòôõö'), 'OOOOO');
      expect(normalizeWord('úùûü'), 'UUUU');
      expect(normalizeWord('çñ'), 'CN');
    });

    test('mantém o que não é letra acentuada', () {
      expect(normalizeWord('A1-B'), 'A1-B');
      expect(normalizeWord(''), '');
    });

    test('é idempotente', () {
      const word = 'Pão de Açúcar';
      expect(normalizeWord(normalizeWord(word)), normalizeWord(word));
    });
  });
}
