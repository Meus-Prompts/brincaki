// test/games/damas/ai_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/damas/logic/ai.dart';
import 'package:brincaki/games/damas/logic/board.dart';
import 'package:brincaki/games/damas/models/game_state.dart';

/// Índice da casa na linha [r] e coluna [c].
int sq(int r, int c) => r * 8 + c;

/// Monta uma posição só com as peças dadas (índice → valor).
DamasPosition pos(Map<int, int> pieces, DamasSide turn) {
  final cells = List.filled(64, 0);
  pieces.forEach((i, v) => cells[i] = v);
  return DamasPosition(cells, turn);
}

/// Posições tiradas de partidas aleatórias, todas com lance para jogar.
List<DamasPosition> randomPositions(int count, Random random) {
  final out = <DamasPosition>[];
  while (out.length < count) {
    var p = DamasPosition.initial();
    final plies = random.nextInt(60);
    for (var i = 0; i < plies; i++) {
      final moves = legalMoves(p);
      if (moves.isEmpty) break;
      p = applyMove(p, moves[random.nextInt(moves.length)]);
    }
    if (legalMoves(p).isNotEmpty) out.add(p);
  }
  return out;
}

void main() {
  // Brancas podem comer (5,2) ou (5,6). Comer (5,2) é de graça; comer (5,6)
  // deixa a pedra em (4,5), que a preta de (3,6) come de volta.
  final freePiece = pos({
    sq(6, 1): 1,
    sq(6, 7): 1,
    sq(5, 2): -1,
    sq(5, 6): -1,
    sq(3, 6): -1,
    sq(2, 7): -1,
  }, DamasSide.white);

  // Andar (5,2) → (4,3) entrega a pedra para a preta de (3,4).
  final hanging = pos({
    sq(5, 2): 1,
    sq(7, 0): 1,
    sq(3, 4): -1,
    sq(0, 7): -1,
  }, DamasSide.white);

  test('todos os níveis só devolvem lances legais', () {
    final positions = randomPositions(100, Random(7));
    for (final p in positions) {
      final legal = legalMoves(p);
      for (var seed = 0; seed < 2; seed++) {
        expect(legal, contains(chooseMove(p, AiLevel.easy, Random(seed))));
        expect(legal, contains(chooseMove(p, AiLevel.medium, Random(seed))));
      }
      expect(
        legal,
        contains(
          chooseMove(
            p,
            AiLevel.hard,
            Random(0),
            budget: const Duration(milliseconds: 20),
          ),
        ),
      );
    }
  });

  test('médio e difícil pegam a peça de graça', () {
    final free = DamasMove([sq(6, 1), sq(4, 3)], [sq(5, 2)]);
    expect(legalMoves(freePiece), hasLength(2));
    for (var seed = 0; seed < 10; seed++) {
      expect(chooseMove(freePiece, AiLevel.medium, Random(seed)), free);
    }
    for (var seed = 0; seed < 3; seed++) {
      expect(chooseMove(freePiece, AiLevel.hard, Random(seed)), free);
    }
  });

  test('difícil não entrega peça de graça', () {
    for (var seed = 0; seed < 3; seed++) {
      final m = chooseMove(hanging, AiLevel.hard, Random(seed));
      expect(m, isNot(DamasMove([sq(5, 2), sq(4, 3)], const [])));
      final next = applyMove(hanging, m);
      expect(legalMoves(next).any((r) => r.isCapture), isFalse);
    }
  });

  test('fácil come a peça que vale mais metade das vezes', () {
    // A dama branca pode comer a dama preta ou a pedra preta.
    final p = pos({sq(4, 3): 2, sq(3, 2): -2, sq(5, 4): -1}, DamasSide.white);
    var queen = 0;
    for (var seed = 0; seed < 200; seed++) {
      final m = chooseMove(p, AiLevel.easy, Random(seed));
      expect(legalMoves(p), contains(m));
      if (m.captured.first == sq(3, 2)) queen++;
    }
    // Metade escolhe a dama; a outra metade sorteia entre todos os lances.
    expect(queen, greaterThan(100));
    expect(queen, lessThan(200));
  });

  test('difícil responde dentro do orçamento', () {
    final watch = Stopwatch()..start();
    final m = chooseMove(DamasPosition.initial(), AiLevel.hard, Random(1));
    watch.stop();
    expect(legalMoves(DamasPosition.initial()), contains(m));
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('difícil com o tempo curto ainda devolve um lance', () {
    final p = randomPositions(1, Random(3)).single;
    final m = chooseMove(p, AiLevel.hard, Random(0), budget: Duration.zero);
    expect(legalMoves(p), contains(m));
  });

  test('devolve lance legal com o adversário quase sem lances', () {
    // A única pedra preta está bloqueada pelas brancas.
    final p = pos({
      sq(0, 1): -1,
      sq(1, 0): 1,
      sq(1, 2): 1,
      sq(2, 3): 1,
      sq(7, 6): 1,
    }, DamasSide.white);
    for (final level in AiLevel.values) {
      expect(legalMoves(p), contains(chooseMove(p, level, Random(0))));
    }
  });

  test('chooseMoveInIsolate devolve o índice do lance', () {
    for (final level in [AiLevel.easy, AiLevel.medium]) {
      for (var seed = 0; seed < 5; seed++) {
        final i = chooseMoveInIsolate((
          freePiece.cells,
          freePiece.turn.index,
          level.index,
          seed,
        ));
        expect(
          legalMoves(freePiece)[i],
          chooseMove(freePiece, level, Random(seed)),
        );
      }
    }
    final black = applyMove(
      DamasPosition.initial(),
      legalMoves(DamasPosition.initial()).first,
    );
    final i = chooseMoveInIsolate((
      black.cells,
      black.turn.index,
      AiLevel.hard.index,
      0,
    ));
    expect(i, inInclusiveRange(0, legalMoves(black).length - 1));
    final hard = chooseMoveInIsolate((
      freePiece.cells,
      freePiece.turn.index,
      AiLevel.hard.index,
      0,
    ));
    expect(legalMoves(freePiece)[hard].path, [sq(6, 1), sq(4, 3)]);
  });
}
