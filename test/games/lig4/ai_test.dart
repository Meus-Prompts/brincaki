// test/games/lig4/ai_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/lig4/logic/ai.dart';

List<List<int>> board(List<String> rows) => [
      for (final r in rows) [for (final ch in r.split('')) ch == '.' ? 0 : int.parse(ch)],
    ];

void main() {
  // 1 tem três na linha de baixo e é a vez de 1.
  final winNow = board([
    '.......', '.......', '.......', '.......', '22.....', '111....',
  ]);
  // 2 tem três na linha de baixo e é a vez de 1.
  final mustBlock = board([
    '.......', '.......', '.......', '.......', '11.....', '222...1',
  ]);
  // Jogar na coluna 3 (vazia) deixa 2 completar a linha 4 logo em cima.
  final poisoned = board([
    '.......', '.......', '.......', '.......', '222....', '121..11',
  ]);
  // Vez de 1: jogar na coluna 1 ou 4 cria três abertos na linha de baixo
  // (ameaça dupla) e a vitória é forçada.
  final doubleThreat = board([
    '.......', '.......', '.......', '.......', '..22...', '..11...',
  ]);
  // Vez de 2: se não jogar na coluna 1 ou 4 agora, 1 cria a ameaça dupla.
  final trap = board([
    '.......', '.......', '.......', '.......', '...2...', '..11...',
  ]);

  test('médio sempre aproveita a vitória imediata', () {
    for (var seed = 0; seed < 20; seed++) {
      expect(chooseColumn(winNow, 1, AiLevel.medium, Random(seed)), 3);
    }
  });

  test('médio sempre bloqueia a vitória do adversário', () {
    for (var seed = 0; seed < 20; seed++) {
      expect(chooseColumn(mustBlock, 1, AiLevel.medium, Random(seed)), 3);
    }
  });

  test('médio não joga onde entrega a vitória', () {
    for (var seed = 0; seed < 30; seed++) {
      expect(chooseColumn(poisoned, 1, AiLevel.medium, Random(seed)), isNot(3));
    }
  });

  test('difícil acha a vitória com ameaça dupla', () {
    for (var seed = 0; seed < 5; seed++) {
      expect(chooseColumn(doubleThreat, 1, AiLevel.hard, Random(seed)),
          anyOf(1, 4));
    }
  });

  test('difícil evita a armadilha em que o médio cai', () {
    for (var seed = 0; seed < 5; seed++) {
      expect(chooseColumn(trap, 2, AiLevel.hard, Random(seed)), anyOf(1, 4));
    }
    final mediumChoices = {
      for (var seed = 0; seed < 30; seed++)
        chooseColumn(trap, 2, AiLevel.medium, Random(seed)),
    };
    expect(mediumChoices.difference({1, 4}), isNotEmpty);
  });

  test('nenhum nível escolhe coluna cheia', () {
    final fullCenter = board([
      '...1...', '...2...', '...1...', '...2...', '...1...', '...2...',
    ]);
    for (final level in AiLevel.values) {
      for (var seed = 0; seed < 30; seed++) {
        final col = chooseColumn(fullCenter, 1, level, Random(seed));
        expect(col, isNot(3));
        expect(col, inInclusiveRange(0, 6));
      }
    }
  });

  test('fácil às vezes não bloqueia', () {
    final choices = {
      for (var seed = 0; seed < 40; seed++)
        chooseColumn(mustBlock, 1, AiLevel.easy, Random(seed)),
    };
    expect(choices.length, greaterThan(1));
  });

  test('difícil decide em menos de 2 segundos no meio da partida', () {
    final midGame = board([
      '.......', '.......', '...2...', '..121..', '..212..', '.12121.',
    ]);
    final watch = Stopwatch()..start();
    chooseColumn(midGame, 1, AiLevel.hard, Random(1));
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
