// test/games/xadrez/game_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/xadrez/logic/game.dart';
import 'package:brincaki/games/xadrez/logic/position.dart';
import 'package:brincaki/games/xadrez/models/game_state.dart';

ChessGame mv(ChessGame g, String uci) => g.play(
  g.legalMoves.firstWhere((m) => m.uci == uci, orElse: () => ChessMove(0, 0)),
);

ChessGame line(ChessGame g, String moves) =>
    moves.split(' ').fold(g, (acc, u) => mv(acc, u));

void main() {
  test('partida começa sem fim e com 20 lances', () {
    final g = ChessGame.start();
    expect(g.end, isNull);
    expect(g.winner, isNull);
    expect(g.lastMove, isNull);
    expect(g.legalMoves.length, 20);
  });

  test('mate do louco', () {
    final g = line(ChessGame.start(), 'f2f3 e7e5 g2g4 d8h4');
    expect(g.end, XadrezEnd.checkmate);
    expect(g.winner, ChessSide.black);
    expect(g.legalMoves, isEmpty);
    expect(g.lastMove!.uci, 'd8h4');
  });

  test('afogamento empata', () {
    final g = mv(
      ChessGame.start(ChessPosition.fromFen('7k/8/5K2/6Q1/8/8/8/8 w - - 0 1')),
      'g5g6',
    );
    expect(g.end, XadrezEnd.stalemate);
    expect(g.winner, isNull);
    expect(g.legalMoves, isEmpty);
  });

  test('posição inicial já afogada termina ao começar', () {
    final g = ChessGame.start(
      ChessPosition.fromFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'),
    );
    expect(g.end, XadrezEnd.stalemate);
  });

  test('rei contra rei empata', () {
    final g = mv(
      ChessGame.start(ChessPosition.fromFen('4k3/8/8/8/8/8/8/3qK3 w - - 0 1')),
      'e1d1',
    );
    expect(g.end, XadrezEnd.insufficientMaterial);
    expect(g.winner, isNull);
    expect(g.legalMoves, isEmpty);
  });

  test('50 lances empata', () {
    final g = mv(
      ChessGame.start(
        ChessPosition.fromFen('4k3/8/8/8/8/8/8/R3K3 w - - 99 60'),
      ),
      'a1a2',
    );
    expect(g.end, XadrezEnd.fiftyMoves);
    expect(g.winner, isNull);
  });

  test('repetição 3 vezes empata', () {
    var g = ChessGame.start();
    const out = 'g1f3 g8f6 f3g1 f6g8';
    g = line(g, out);
    expect(g.end, isNull);
    g = line(g, 'g1f3 g8f6 f3g1');
    expect(g.end, isNull);
    g = mv(g, 'f6g8');
    expect(g.end, XadrezEnd.repetition);
    expect(g.winner, isNull);
  });

  test('play recusa lance ilegal', () {
    final g = ChessGame.start();
    expect(
      () => g.play(ChessMove(squareOf('e2'), squareOf('e5'))),
      throwsStateError,
    );
  });

  test('play recusa peão na última fileira sem promoção', () {
    final g = ChessGame.start(
      ChessPosition.fromFen('8/P6k/8/8/8/8/8/K7 w - - 0 1'),
    );
    expect(
      () => g.play(ChessMove(squareOf('a7'), squareOf('a8'))),
      throwsStateError,
    );
    final p = g.play(
      ChessMove(squareOf('a7'), squareOf('a8'), promotion: kQueen),
    );
    expect(p.position.cells[squareOf('a8')], kQueen);
  });

  test('play recusa lance depois do fim', () {
    final g = line(ChessGame.start(), 'f2f3 e7e5 g2g4 d8h4');
    expect(
      () => g.play(ChessMove(squareOf('a2'), squareOf('a3'))),
      throwsStateError,
    );
  });
}
