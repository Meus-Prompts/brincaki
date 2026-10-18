// test/games/xadrez/ai_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/xadrez/logic/ai.dart';
import 'package:brincaki/games/xadrez/logic/game.dart';
import 'package:brincaki/games/xadrez/logic/position.dart';
import 'package:brincaki/games/xadrez/models/game_state.dart';

const kKiwipete =
    'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1';

/// Posições tiradas de partidas aleatórias, todas com lance para jogar.
List<ChessPosition> randomPositions(int count, Random random) {
  final out = <ChessPosition>[];
  while (out.length < count) {
    var p = ChessPosition.initial();
    final plies = random.nextInt(80);
    for (var i = 0; i < plies; i++) {
      final moves = p.legalMoves();
      if (moves.isEmpty) break;
      p = p.play(moves[random.nextInt(moves.length)]);
    }
    if (p.legalMoves().isNotEmpty) out.add(p);
  }
  return out;
}

bool isMate(ChessPosition p) => p.legalMoves().isEmpty && p.inCheck;

/// Joga a partida com o difícil de brancas e o fácil de pretas até o fim ou
/// até [maxMoves] lances das brancas.
ChessGame playOut(String fen, int seed, int maxMoves) {
  var game = ChessGame.start(ChessPosition.fromFen(fen));
  final random = Random(seed);
  for (var ply = 0; ply < maxMoves * 2 && game.end == null; ply++) {
    final p = game.position;
    final level = p.turn == ChessSide.white ? AiLevel.hard : AiLevel.easy;
    game = game.play(
      chooseMove(p, level, random, budget: const Duration(milliseconds: 300)),
    );
  }
  return game;
}

void main() {
  // Torre de a1 para a8 é mate no corredor.
  final backRank = ChessPosition.fromFen('6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1');

  // O peão preto de e5 ataca a dama de d4; comer e5 entrega a dama para o
  // peão de d6.
  final queenAttacked = ChessPosition.fromFen(
    'k7/8/3p4/4p3/3Q4/8/8/K7 w - - 0 1',
  );

  // Peão branco em e7 pronto para promover; se esperar, o rei de f6 come.
  final promotion = ChessPosition.fromFen('8/4P3/5k2/8/8/8/8/K7 w - - 0 1');

  test('todos os níveis só devolvem lances legais', () {
    final positions = randomPositions(40, Random(11));
    for (final p in positions) {
      final legal = p.legalMoves();
      for (var seed = 0; seed < 2; seed++) {
        for (final level in [AiLevel.easy, AiLevel.medium]) {
          final m = chooseMove(p, level, Random(seed));
          expect(legal, contains(m));
          expect(m.promotion, anyOf(0, kQueen));
        }
      }
      final m = chooseMove(
        p,
        AiLevel.hard,
        Random(0),
        budget: const Duration(milliseconds: 20),
      );
      expect(legal, contains(m));
      expect(m.promotion, anyOf(0, kQueen));
    }
  });

  test('médio e difícil acham mate em 1', () {
    for (var seed = 0; seed < 3; seed++) {
      for (final level in [AiLevel.medium, AiLevel.hard]) {
        final m = chooseMove(backRank, level, Random(seed));
        expect(isMate(backRank.play(m)), isTrue, reason: '$level $m');
      }
    }
  });

  test('fácil dá mate em 1 quando pode', () {
    for (var seed = 0; seed < 10; seed++) {
      final m = chooseMove(backRank, AiLevel.easy, Random(seed));
      expect(isMate(backRank.play(m)), isTrue);
    }
  });

  test('fácil come uma peça mais ou menos metade das vezes', () {
    // A torre de d1 só pode comer o peão de d5, que tapa a dama de d8.
    final p = ChessPosition.fromFen('3qk3/8/8/3p4/8/8/8/K2R4 w - - 0 1');
    var captures = 0;
    for (var seed = 0; seed < 40; seed++) {
      final m = chooseMove(p, AiLevel.easy, Random(seed));
      if (m.captured != 0) captures++;
    }
    expect(captures, greaterThan(10));
    expect(captures, lessThan(40));
  });

  test('difícil não deixa a dama ser comida de graça', () {
    for (var seed = 0; seed < 3; seed++) {
      final m = chooseMove(queenAttacked, AiLevel.hard, Random(seed));
      final next = queenAttacked.play(m);
      expect(
        next.legalMoves().where((r) => r.captured == kQueen),
        isEmpty,
        reason: '$m',
      );
    }
  });

  test('médio não come o peão protegido com a dama', () {
    for (var seed = 0; seed < 3; seed++) {
      final m = chooseMove(queenAttacked, AiLevel.medium, Random(seed));
      final next = queenAttacked.play(m);
      expect(next.legalMoves().where((r) => r.captured == kQueen), isEmpty);
    }
  });

  test('difícil responde dentro do orçamento', () {
    for (final p in [
      ChessPosition.initial(),
      ChessPosition.fromFen(kKiwipete),
    ]) {
      final watch = Stopwatch()..start();
      final m = chooseMove(p, AiLevel.hard, Random(1));
      watch.stop();
      expect(p.legalMoves(), contains(m));
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    }
  });

  test('difícil prefere o mate mais rápido', () {
    // Th8 é mate já; há vários mates em 2, mas o difícil escolhe o de 1.
    final p = ChessPosition.fromFen('k7/8/1K6/8/8/8/8/7R w - - 0 1');
    for (var seed = 0; seed < 3; seed++) {
      final m = chooseMove(p, AiLevel.hard, Random(seed));
      expect(m.uci, 'h1h8');
    }
  });

  test('difícil com orçamento mínimo ainda responde rápido', () {
    final p = ChessPosition.fromFen(kKiwipete);
    final watch = Stopwatch()..start();
    final m = chooseMove(
      p,
      AiLevel.hard,
      Random(0),
      budget: const Duration(microseconds: 1),
    );
    watch.stop();
    expect(p.legalMoves(), contains(m));
    expect(watch.elapsed, lessThan(const Duration(milliseconds: 300)));
  });

  test('difícil dá mate com dama e rei contra rei', () {
    for (var seed = 0; seed < 2; seed++) {
      final game = playOut('k7/8/2Q5/8/3K4/8/8/8 w - - 0 1', seed, 20);
      expect(game.end, XadrezEnd.checkmate, reason: 'semente $seed');
      expect(game.winner, ChessSide.white);
    }
  });

  test('difícil promove e depois dá mate sem repetir', () {
    for (var seed = 0; seed < 3; seed++) {
      final game = playOut('k7/4P3/8/8/8/8/8/K7 w - - 0 1', seed, 30);
      expect(game.end, XadrezEnd.checkmate, reason: 'semente $seed');
      expect(game.winner, ChessSide.white);
    }
  });

  test('promove para dama', () {
    for (final level in [AiLevel.medium, AiLevel.hard]) {
      final m = chooseMove(promotion, level, Random(0));
      expect(m.from, squareOf('e7'), reason: '$level $m');
      expect(m.promotion, kQueen);
    }
    for (var seed = 0; seed < 20; seed++) {
      final m = chooseMove(promotion, AiLevel.easy, Random(seed));
      expect(m.promotion, anyOf(0, kQueen));
    }
  });

  test('a FEN refeita dá a mesma ordem de lances', () {
    for (final p in randomPositions(30, Random(3))) {
      expect(ChessPosition.fromFen(p.toFen()).legalMoves(), p.legalMoves());
    }
  });

  test('chooseMoveInIsolate devolve o índice do lance', () {
    final positions = [
      ChessPosition.fromFen(kKiwipete),
      backRank,
      ...randomPositions(5, Random(5)),
    ];
    for (final p in positions) {
      final fen = p.toFen();
      for (final level in [AiLevel.easy, AiLevel.medium]) {
        final index = chooseMoveInIsolate((fen, level.index, 4));
        expect(p.legalMoves()[index], chooseMove(p, level, Random(4)));
      }
    }
    final index = chooseMoveInIsolate((
      backRank.toFen(),
      AiLevel.hard.index,
      4,
    ));
    expect(isMate(backRank.play(backRank.legalMoves()[index])), isTrue);
  });
}
