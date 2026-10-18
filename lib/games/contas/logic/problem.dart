// lib/games/contas/logic/problem.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/game_state.dart';

String operationSymbol(Operation op) => switch (op) {
      Operation.addition => '+',
      Operation.subtraction => '−',
      Operation.multiplication => '×',
      Operation.division => '÷',
    };

/// Uma conta: os números na ordem em que aparecem na tela.
@immutable
class Problem {
  const Problem(this.operation, this.operands);

  final Operation operation;
  final List<int> operands;

  int get answer => switch (operation) {
        Operation.addition => operands.reduce((a, b) => a + b),
        Operation.subtraction => operands.reduce((a, b) => a - b),
        Operation.multiplication => operands.reduce((a, b) => a * b),
        Operation.division => operands.reduce((a, b) => a ~/ b),
      };

  /// '7 × 8', '850 − 320 − 75'.
  String get text => operands.join(' ${operationSymbol(operation)} ');

  @override
  bool operator ==(Object other) =>
      other is Problem &&
      other.operation == operation &&
      listEquals(other.operands, operands);

  @override
  int get hashCode => Object.hash(operation, Object.hashAll(operands));
}

/// Sorteia uma conta do [level] (1 a 3) diferente de [avoid]. Depois de 20
/// tentativas aceita a repetida, para nunca travar.
Problem generateProblem(
  Operation op,
  int level,
  Random random, {
  Problem? avoid,
}) {
  var problem = _generate(op, level, random);
  for (var i = 0; i < 20 && problem == avoid; i++) {
    problem = _generate(op, level, random);
  }
  return problem;
}

/// Inteiro sorteado entre [min] e [max], inclusive.
int _between(Random random, int min, int max) =>
    min + random.nextInt(max - min + 1);

Problem _generate(Operation op, int level, Random random) {
  switch (op) {
    case Operation.addition:
      if (level == 3) {
        return Problem(op, _splitInThree(_between(random, 3, 1000), random));
      }
      final total =
          level == 1 ? _between(random, 2, 100) : _between(random, 101, 1000);
      final a = _between(random, 1, total - 1);
      return Problem(op, [a, total - a]);
    case Operation.subtraction:
      if (level == 3) {
        final a = _between(random, 101, 1000);
        // Reparte a + 1 em b, c e resultado + 1, para o resultado poder ser 0.
        final [b, c, _] = _splitInThree(a + 1, random);
        return Problem(op, [a, b, c]);
      }
      final a =
          level == 1 ? _between(random, 2, 100) : _between(random, 101, 1000);
      return Problem(op, [a, _between(random, 1, a)]);
    case Operation.multiplication:
      final (from, to) = _tableRange(level);
      final table = _between(random, from, to);
      final n = _between(random, 1, 10);
      return Problem(op, random.nextBool() ? [table, n] : [n, table]);
    case Operation.division:
      final (from, to) = _tableRange(level);
      final divisor = _between(random, from, to);
      final quotient = _between(random, 1, 10);
      return Problem(op, [divisor * quotient, divisor]);
  }
}

(int, int) _tableRange(int level) => switch (level) {
      1 => (1, 5),
      2 => (6, 10),
      _ => (1, 10),
    };

/// Reparte [total] (≥ 3) em três partes ≥ 1.
List<int> _splitInThree(int total, Random random) {
  final first = _between(random, 1, total - 2);
  final second = _between(random, 1, total - first - 1);
  return [first, second, total - first - second];
}

/// 4 opções embaralhadas: a resposta certa e 3 erradas que parecem certas.
List<int> generateChoices(Problem problem, Random random) {
  final answer = problem.answer;
  final ops = problem.operands;
  final candidates = switch (problem.operation) {
    Operation.multiplication => [
        (ops[0] - 1) * ops[1],
        (ops[0] + 1) * ops[1],
        ops[0] * (ops[1] - 1),
        ops[0] * (ops[1] + 1),
        answer - 1,
        answer + 1,
      ],
    Operation.division => [answer - 1, answer + 1, answer - 2, answer + 2],
    Operation.addition || Operation.subtraction => [
        answer - 1,
        answer + 1,
        answer - 10,
        answer + 10,
        if (answer > 100) ...[answer - 100, answer + 100],
      ],
  };
  final wrong = candidates.where((c) => c >= 0 && c != answer).toSet().toList()
    ..shuffle(random);
  final picked = wrong.take(3).toList();
  // Faltou candidato (respostas pequenas): completa com números próximos.
  for (var d = 1; picked.length < 3; d++) {
    for (final c in [answer - d, answer + d]) {
      if (picked.length < 3 && c >= 0 && !picked.contains(c)) picked.add(c);
    }
  }
  return [answer, ...picked]..shuffle(random);
}
