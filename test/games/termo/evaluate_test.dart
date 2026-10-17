// test/games/termo/evaluate_test.dart

import 'package:flutter_test/flutter_test.dart';
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

    test('todas no lugar errado', () {
      expect(evaluateGuess('ROCAR', 'CARRO'), [p, p, p, p, p]);
    });

    test('mistura de verde, amarelo e cinza', () {
      expect(evaluateGuess('PORTA', 'CARRO'), [a, p, c, a, p]);
    });

    test('a ordem do resultado segue a tentativa', () {
      expect(evaluateGuess('TERMO', 'METRO'), [p, c, p, p, c]);
    });

    group('letras repetidas', () {
      test('tentativa com mais cópias que a resposta: só colore quantas há',
          () {
        // CARRO tem dois R e um A.
        expect(evaluateGuess('ARARA', 'CARRO'), [p, p, a, c, a]);
      });

      test('verdes contam primeiro, mesmo vindo depois de uma amarela', () {
        // ASSAR tem dois S e dois A; o A da posição 3 é verde.
        expect(evaluateGuess('SALAS', 'ASSAR'), [p, p, a, c, p]);
      });

      test('repetida na tentativa, uma só na resposta, nenhuma no lugar', () {
        // Só o primeiro E vira amarelo.
        expect(evaluateGuess('EEXXX', 'ABCDE'), [p, a, a, a, a]);
      });

      test('repetida na tentativa, uma só na resposta, a segunda no lugar', () {
        // O E verde gasta a única cópia: o primeiro fica cinza.
        expect(evaluateGuess('EXXXE', 'ABCDE'), [a, a, a, a, c]);
      });

      test('repetida na resposta, uma só na tentativa', () {
        expect(evaluateGuess('XXXXA', 'AABBB'), [a, a, a, a, p]);
        expect(evaluateGuess('AXXXX', 'AABBB'), [c, a, a, a, a]);
      });

      test('duas cópias nos dois lados, ambas fora do lugar', () {
        expect(evaluateGuess('AAXYZ', 'BCDAA'), [p, p, a, a, a]);
      });

      test('duas cópias nos dois lados, uma no lugar', () {
        expect(evaluateGuess('AXAYZ', 'ABCDA'), [c, a, p, a, a]);
      });

      test('três cópias na tentativa, duas na resposta', () {
        // Um A verde, um amarelo e o terceiro cinza.
        expect(evaluateGuess('AAAYZ', 'BACAD'), [p, c, a, a, a]);
      });

      test('todas iguais na tentativa', () {
        expect(evaluateGuess('AAAAA', 'CARRO'), [a, c, a, a, a]);
        expect(evaluateGuess('RRRRR', 'CARRO'), [a, a, c, c, a]);
      });

      test('palavra inteira repetida na resposta', () {
        expect(evaluateGuess('ARARA', 'ARARA'), [c, c, c, c, c]);
        expect(evaluateGuess('RARAR', 'ARARA'), [p, p, p, p, a]);
      });
    });

    test('não modifica nada fora do resultado (chamadas repetidas iguais)', () {
      final first = evaluateGuess('SALAS', 'ASSAR');
      final second = evaluateGuess('SALAS', 'ASSAR');
      expect(first, second);
    });
  });
}
