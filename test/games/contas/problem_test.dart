// test/games/contas/problem_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/contas/logic/problem.dart';
import 'package:brincaki/games/contas/models/game_state.dart';

const _rounds = 500;

/// Sorteia [_rounds] contas da operação e do nível.
List<Problem> sample(Operation op, int level, [int seed = 1]) {
  final random = Random(seed);
  return [for (var i = 0; i < _rounds; i++) generateProblem(op, level, random)];
}

void main() {
  group('Problem', () {
    test('texto usa os sinais da conta', () {
      expect(const Problem(Operation.addition, [3, 4]).text, '3 + 4');
      expect(const Problem(Operation.subtraction, [850, 320, 75]).text,
          '850 − 320 − 75');
      expect(const Problem(Operation.multiplication, [7, 8]).text, '7 × 8');
      expect(const Problem(Operation.division, [56, 8]).text, '56 ÷ 8');
    });

    test('resposta de cada operação', () {
      expect(const Problem(Operation.addition, [120, 30, 5]).answer, 155);
      expect(const Problem(Operation.subtraction, [850, 320, 75]).answer, 455);
      expect(const Problem(Operation.multiplication, [7, 8]).answer, 56);
      expect(const Problem(Operation.division, [56, 8]).answer, 7);
    });

    test('contas iguais são ==, com a mesma ordem dos números', () {
      const a = Problem(Operation.multiplication, [7, 8]);
      expect(a, const Problem(Operation.multiplication, [7, 8]));
      expect(a.hashCode,
          const Problem(Operation.multiplication, [7, 8]).hashCode);
      expect(a, isNot(const Problem(Operation.multiplication, [8, 7])));
      expect(a, isNot(const Problem(Operation.addition, [7, 8])));
      expect(a, isNot(const Problem(Operation.multiplication, [7, 8, 1])));
    });

    test('símbolo de cada operação', () {
      expect(operationSymbol(Operation.addition), '+');
      expect(operationSymbol(Operation.subtraction), '−');
      expect(operationSymbol(Operation.multiplication), '×');
      expect(operationSymbol(Operation.division), '÷');
    });
  });

  group('adição', () {
    test('nível 1: dois números, resultado de 2 a 100', () {
      for (final p in sample(Operation.addition, 1)) {
        expect(p.operands, hasLength(2));
        expect(p.operands.every((n) => n >= 1), isTrue, reason: p.text);
        expect(p.answer, inInclusiveRange(2, 100), reason: p.text);
      }
    });

    test('nível 2: dois números, resultado de 101 a 1000', () {
      for (final p in sample(Operation.addition, 2)) {
        expect(p.operands, hasLength(2));
        expect(p.operands.every((n) => n >= 1), isTrue, reason: p.text);
        expect(p.answer, inInclusiveRange(101, 1000), reason: p.text);
      }
    });

    test('nível 3: três números, resultado até 1000', () {
      for (final p in sample(Operation.addition, 3)) {
        expect(p.operands, hasLength(3));
        expect(p.operands.every((n) => n >= 1), isTrue, reason: p.text);
        expect(p.answer, inInclusiveRange(3, 1000), reason: p.text);
      }
    });
  });

  group('subtração', () {
    test('nível 1: primeiro número até 100, resultado nunca negativo', () {
      for (final p in sample(Operation.subtraction, 1)) {
        expect(p.operands, hasLength(2));
        expect(p.operands[0], inInclusiveRange(2, 100), reason: p.text);
        expect(p.operands[1], greaterThanOrEqualTo(1), reason: p.text);
        expect(p.answer, greaterThanOrEqualTo(0), reason: p.text);
      }
    });

    test('nível 2: primeiro número de 101 a 1000', () {
      for (final p in sample(Operation.subtraction, 2)) {
        expect(p.operands, hasLength(2));
        expect(p.operands[0], inInclusiveRange(101, 1000), reason: p.text);
        expect(p.operands[1], greaterThanOrEqualTo(1), reason: p.text);
        expect(p.answer, greaterThanOrEqualTo(0), reason: p.text);
      }
    });

    test('nível 3: três números, resultado nunca negativo', () {
      for (final p in sample(Operation.subtraction, 3)) {
        expect(p.operands, hasLength(3));
        expect(p.operands[0], inInclusiveRange(101, 1000), reason: p.text);
        expect(p.operands.skip(1).every((n) => n >= 1), isTrue, reason: p.text);
        expect(p.answer, greaterThanOrEqualTo(0), reason: p.text);
      }
    });
  });

  group('multiplicação', () {
    void checkTable(int level, int from, int to) {
      final orders = <bool>{};
      for (final p in sample(Operation.multiplication, level)) {
        expect(p.operands, hasLength(2));
        final [a, b] = p.operands;
        final aIsTable = a >= from && a <= to && b >= 1 && b <= 10;
        final bIsTable = b >= from && b <= to && a >= 1 && a <= 10;
        expect(aIsTable || bIsTable, isTrue, reason: p.text);
        if (aIsTable != bIsTable) orders.add(aIsTable);
      }
      expect(orders, {true, false}, reason: 'as duas ordens aparecem');
    }

    test('nível 1: tabuada do 1 ao 5', () => checkTable(1, 1, 5));
    test('nível 2: tabuada do 6 ao 10', () => checkTable(2, 6, 10));
    test('nível 3: tabuada do 1 ao 10', () {
      for (final p in sample(Operation.multiplication, 3)) {
        expect(p.operands.every((n) => n >= 1 && n <= 10), isTrue,
            reason: p.text);
      }
    });
  });

  group('divisão', () {
    void checkDivisor(int level, int from, int to) {
      for (final p in sample(Operation.division, level)) {
        expect(p.operands, hasLength(2));
        final [dividend, divisor] = p.operands;
        expect(dividend % divisor, 0, reason: p.text);
        expect(divisor, inInclusiveRange(from, to), reason: p.text);
        expect(p.answer, inInclusiveRange(1, 10), reason: p.text);
      }
    }

    test('nível 1: divisor de 1 a 5, sempre exata', () => checkDivisor(1, 1, 5));
    test('nível 2: divisor de 6 a 10', () => checkDivisor(2, 6, 10));
    test('nível 3: divisor de 1 a 10', () => checkDivisor(3, 1, 10));
  });

  test('a mesma conta não sai duas vezes seguidas', () {
    for (final op in Operation.values) {
      for (var level = 1; level <= 3; level++) {
        final random = Random(3);
        var previous = generateProblem(op, level, random);
        for (var i = 0; i < 2000; i++) {
          final next = generateProblem(op, level, random, avoid: previous);
          expect(next, isNot(previous), reason: '${op.name} $level');
          previous = next;
        }
      }
    }
  });

  group('opções', () {
    void checkChoices(Problem p, List<int> choices) {
      expect(choices, hasLength(4), reason: p.text);
      expect(choices.toSet(), hasLength(4), reason: '$choices em ${p.text}');
      expect(choices, contains(p.answer), reason: p.text);
      expect(choices.every((c) => c >= 0), isTrue, reason: '$choices');
    }

    test('4 opções distintas, sem negativos, com a resposta certa', () {
      for (final op in Operation.values) {
        for (var level = 1; level <= 3; level++) {
          final random = Random(5);
          for (final p in sample(op, level)) {
            checkChoices(p, generateChoices(p, random));
          }
        }
      }
    });

    test('respostas 0 e 1 também têm 4 opções', () {
      final random = Random(1);
      for (final p in const [
        Problem(Operation.subtraction, [5, 5]),
        Problem(Operation.division, [3, 3]),
        Problem(Operation.multiplication, [1, 1]),
        Problem(Operation.subtraction, [9, 4, 5]),
      ]) {
        for (var i = 0; i < 50; i++) {
          checkChoices(p, generateChoices(p, random));
        }
      }
    });

    test('na multiplicação as erradas parecem a tabuada vizinha', () {
      const p = Problem(Operation.multiplication, [7, 8]);
      const plausible = {48, 63, 49, 64, 51, 52, 53, 54, 55, 57, 58, 59, 60, 61};
      final random = Random(2);
      for (var i = 0; i < 50; i++) {
        final wrong = generateChoices(p, random).where((c) => c != 56);
        expect(wrong.every(plausible.contains), isTrue, reason: '$wrong');
      }
    });

    test('a resposta certa muda de lugar', () {
      const p = Problem(Operation.addition, [40, 2]);
      final random = Random(4);
      final positions = {
        for (var i = 0; i < 100; i++) generateChoices(p, random).indexOf(42),
      };
      expect(positions, {0, 1, 2, 3});
    });
  });
}
