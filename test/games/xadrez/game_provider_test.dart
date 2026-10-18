// test/games/xadrez/game_provider_test.dart

import 'dart:async';
import 'dart:math';

import 'package:brincaki/games/xadrez/logic/ai.dart';
import 'package:brincaki/games/xadrez/logic/position.dart';
import 'package:brincaki/games/xadrez/models/game_state.dart';
import 'package:brincaki/games/xadrez/providers/game_provider.dart';
import 'package:brincaki/widgets/player_setup.dart';
import 'package:flutter_test/flutter_test.dart';

const _duo = PlayerSetupResult(
  mode: PlayMode.twoPlayers,
  player1: 'Ana',
  player2: 'Beto',
);
const _vsBrancas = PlayerSetupResult(
  mode: PlayMode.solo,
  player1: 'Ana',
  player2: 'Computador',
  levelIndex: 0,
  sideIndex: 0,
);
const _vsPretas = PlayerSetupResult(
  mode: PlayMode.solo,
  player1: 'Ana',
  player2: 'Computador',
  levelIndex: 0,
  sideIndex: 1,
);

Future<ChessMove> firstMove(ChessPosition p, AiLevel l) async =>
    p.legalMoves().first;

ChessPosition fen(String s) => ChessPosition.fromFen(s);

XadrezProvider make({XadrezAiRunner? runner, Duration t = Duration.zero}) =>
    XadrezProvider(thinkTime: t, aiRunner: runner ?? firstMove);

void tapMove(XadrezProvider p, String from, String to) {
  p.tapSquare(squareOf(from));
  p.tapSquare(squareOf(to));
}

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final e2 = squareOf('e2');
  final e4 = squareOf('e4');

  test('começa na fase setup', () {
    expect(make().phase, XadrezPhase.setup);
  });

  test('start com brancas: vez do jogador 1', () {
    final p = make()..start(_duo);
    expect(p.phase, XadrezPhase.playing);
    expect(p.currentPlayer, 1);
    expect(p.player1Side, ChessSide.white);
    expect(p.flipped, isFalse);
    expect(p.isComputerTurn, isFalse);
    expect(p.checkSquare, isNull);
  });

  test('seleciona peça e acende destinos', () {
    final p = make()..start(_duo);
    p.tapSquare(e2);
    expect(p.selected, e2);
    expect(p.targets, {squareOf('e3'), e4});
    p.tapSquare(e2);
    expect(p.selected, isNull);
    expect(p.targets, isEmpty);
    p.tapSquare(e2);
    p.tapSquare(squareOf('e5')); // casa vazia fora dos destinos
    expect(p.selected, isNull);
    expect(p.targets, isEmpty);
  });

  test('tocar noutra peça com lances troca a seleção', () {
    final p = make()..start(_duo);
    p.tapSquare(e2);
    p.tapSquare(squareOf('g1'));
    expect(p.selected, squareOf('g1'));
    expect(p.targets, {squareOf('f3'), squareOf('h3')});
    p.tapSquare(squareOf('e7')); // peça adversária
    expect(p.selected, isNull);
    p.tapSquare(-1);
    p.tapSquare(64);
    expect(p.selected, isNull);
  });

  test('troca a vez depois do lance', () {
    final p = make()..start(_duo);
    tapMove(p, 'e2', 'e4');
    expect(p.currentPlayer, 2);
    expect(p.game.position.turn, ChessSide.black);
    expect(p.lastMove!.to, e4);
    expect(p.selected, isNull);
    expect(p.targets, isEmpty);
  });

  testWidgets('computador joga depois do thinkTime', (tester) async {
    final p = make(t: const Duration(milliseconds: 500))..start(_vsPretas);
    expect(p.aiThinking, isTrue);
    await tester.pump(const Duration(milliseconds: 499));
    expect(p.aiThinking, isTrue);
    await tester.pump(const Duration(milliseconds: 2));
    expect(p.aiThinking, isFalse);
    expect(p.game.position.turn, ChessSide.black);
    expect(p.lastMove, isNotNull);
  });

  test('computador responde ao lance do humano', () async {
    final p = make()..start(_vsBrancas);
    tapMove(p, 'e2', 'e4');
    expect(p.aiThinking, isTrue);
    await settle();
    expect(p.aiThinking, isFalse);
    expect(p.game.position.turn, ChessSide.white);
    expect(p.lastMove!.from ~/ 8 <= 1, isTrue);
    expect(p.selected, isNull);
  });

  test('com pretas o computador começa e o tabuleiro vira', () async {
    final p = make()..start(_vsPretas);
    expect(p.flipped, isTrue);
    expect(p.isComputerTurn, isTrue);
    expect(p.currentPlayer, 2);
    await settle();
    expect(p.game.position.turn, ChessSide.black);
    expect(p.currentPlayer, 1);
    // As casas continuam sendo as reais: a peça preta de e7 é a do humano.
    p.tapSquare(squareOf('e7'));
    expect(p.selected, squareOf('e7'));
    expect(p.targets, {squareOf('e6'), squareOf('e5')});
    expect(make().flipped, isFalse);
    expect((make()..start(_vsBrancas)).flipped, isFalse);
  });

  test('ignora toques na vez do computador', () async {
    final answer = Completer<ChessMove>();
    final p = make(runner: (_, _) => answer.future)..start(_vsPretas);
    await settle();
    expect(p.aiThinking, isTrue);
    final before = p.game.position.cells;
    // e2 é peça branca (do computador) com lances legais.
    expect(p.game.legalMoves.any((m) => m.from == e2), isTrue);
    p.tapSquare(e2);
    p.tapSquare(e4);
    expect(p.selected, isNull);
    expect(p.targets, isEmpty);
    expect(p.game.position.cells, before);
    expect(p.game.position.turn, ChessSide.white);
    final move = p.game.legalMoves.firstWhere(
      (m) => m.from == e2 && m.to == e4,
    );
    answer.complete(move);
    await settle();
    expect(p.game.position.turn, ChessSide.black);
    expect(p.lastMove, move);
    expect(p.game.position.cells, ChessPosition.initial().play(move).cells);
  });

  test('ignora toques depois do fim', () {
    // Duas torres que vão e voltam: a terceira repetição empata a partida.
    final p = make()..startFrom(_duo, fen('r3k3/8/8/8/8/8/8/R3K3 w - - 0 1'));
    for (var i = 0; i < 2; i++) {
      for (final (from, to) in [
        ('a1', 'b1'),
        ('a8', 'b8'),
        ('b1', 'a1'),
        ('b8', 'a8'),
      ]) {
        tapMove(p, from, to);
      }
    }
    expect(p.phase, XadrezPhase.finished);
    expect(p.game.end, XadrezEnd.repetition);
    expect(p.winnerPlayer, isNull);
    // Pelas regras ainda haveria lances, mas a partida acabou.
    expect(p.game.legalMoves, isEmpty);
    final legal = p.game.position.legalMoves();
    expect(legal, isNotEmpty);
    final cells = p.game.position.cells;
    final turn = p.game.position.turn;
    final move = p.lastMove;
    p.tapSquare(legal.first.from);
    expect(p.selected, isNull);
    expect(p.targets, isEmpty);
    p.tapSquare(legal.first.to);
    expect(p.selected, isNull);
    expect(p.game.position.cells, cells);
    expect(p.game.position.turn, turn);
    expect(p.lastMove, move);
    expect([p.wins1, p.wins2, p.draws], [0, 0, 1]);
  });

  test('roque pelos toques do rei', () {
    final p = make()
      ..startFrom(_duo, fen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'));
    p.tapSquare(squareOf('e1'));
    expect(p.targets, containsAll([squareOf('g1'), squareOf('c1')]));
    p.tapSquare(squareOf('g1'));
    expect(p.game.position.cells[squareOf('g1')], kKing);
    expect(p.game.position.cells[squareOf('f1')], kRook);
    expect(p.game.position.cells[squareOf('h1')], 0);
    expect(p.lastMove!.isCastle, isTrue);
    expect(p.currentPlayer, 2);
  });

  test('promoção espera a escolha', () {
    final p = make()..startFrom(_duo, fen('8/P6k/8/8/8/8/8/K7 w - - 0 1'));
    p.tapSquare(squareOf('a7'));
    p.tapSquare(squareOf('a8'));
    expect(p.pendingPromotion, (squareOf('a7'), squareOf('a8')));
    expect(p.game.position.cells[squareOf('a7')], kPawn);
    expect(p.currentPlayer, 1);
    // Toques ficam ignorados enquanto espera a escolha.
    p.tapSquare(squareOf('a1'));
    p.tapSquare(squareOf('a7'));
    expect(p.selected, isNull);
    expect(p.pendingPromotion, isNotNull);
    p.promote(kKnight);
    expect(p.pendingPromotion, isNull);
    expect(p.game.position.cells[squareOf('a8')], kKnight);
    expect(p.game.position.cells[squareOf('a7')], 0);
    expect(p.lastMove!.promotion, kKnight);
    expect(p.currentPlayer, 2);
  });

  test('promover sem promoção pendente não faz nada', () {
    final p = make()..start(_duo);
    p.promote(kQueen);
    expect(p.lastMove, isNull);
    expect(p.currentPlayer, 1);
    final q = make()..startFrom(_duo, fen('8/P6k/8/8/8/8/8/K7 w - - 0 1'));
    tapMove(q, 'a7', 'a8');
    q.promote(kKing); // peça inválida: continua esperando
    expect(q.pendingPromotion, isNotNull);
    expect(q.lastMove, isNull);
  });

  test('cancelar promoção não mexe no tabuleiro', () {
    final p = make()..startFrom(_duo, fen('8/P6k/8/8/8/8/8/K7 w - - 0 1'));
    final cells = p.game.position.cells;
    tapMove(p, 'a7', 'a8');
    expect(p.pendingPromotion, isNotNull);
    p.cancelPromotion();
    expect(p.pendingPromotion, isNull);
    expect(p.selected, isNull);
    expect(p.targets, isEmpty);
    expect(p.game.position.cells, cells);
    expect(p.game.position.turn, ChessSide.white);
    expect(p.lastMove, isNull);
    expect(p.currentPlayer, 1);
    p.cancelPromotion(); // sem pendência: nada acontece
    // O jogador pode tentar de novo.
    tapMove(p, 'a7', 'a8');
    p.promote(kQueen);
    expect(p.game.position.cells[squareOf('a8')], kQueen);
  });

  test('checkSquare marca o rei em xeque', () {
    final p = make()..startFrom(_duo, fen('4k3/8/8/8/8/8/8/4K2r w - - 0 1'));
    expect(p.game.position.inCheck, isTrue);
    expect(p.checkSquare, squareOf('e1'));
    p.tapSquare(squareOf('e1'));
    p.tapSquare(squareOf('d2'));
    expect(p.checkSquare, isNull);
  });

  test('mate soma no placar e checkSquare marca o rei mated', () {
    final p = make()..start(_duo);
    for (final (from, to) in [
      ('f2', 'f3'),
      ('e7', 'e5'),
      ('g2', 'g4'),
      ('d8', 'h4'),
    ]) {
      tapMove(p, from, to);
    }
    expect(p.phase, XadrezPhase.finished);
    expect(p.game.end, XadrezEnd.checkmate);
    expect(p.winnerPlayer, 2);
    expect([p.wins1, p.wins2, p.draws], [0, 1, 0]);
    expect(p.checkSquare, squareOf('e1'));
    p.tapSquare(e2);
    expect(p.selected, isNull);
  });

  test('vitória do jogador 1 com as pretas soma em wins1', () {
    // Jogador 1 é das pretas; as brancas já estão em mate.
    final q = make()
      ..startFrom(
        const PlayerSetupResult(
          mode: PlayMode.solo,
          player1: 'Ana',
          player2: 'C',
          levelIndex: 0,
          sideIndex: 1,
        ),
        fen('rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3'),
      );
    expect(q.phase, XadrezPhase.finished);
    expect(q.winnerPlayer, 1);
    expect(q.wins1, 1);
    expect([q.wins2, q.draws], [0, 0]);
  });

  test('descarta lance atrasado do computador', () async {
    final answer = Completer<ChessMove>();
    final p = make(runner: (_, _) => answer.future)..start(_vsPretas);
    await settle();
    expect(p.aiThinking, isTrue);
    p.exitToSetup();
    answer.complete(ChessPosition.initial().legalMoves().first);
    await settle();
    expect(p.phase, XadrezPhase.setup);
    expect(p.aiThinking, isFalse);
    expect(p.lastMove, isNull);
  });

  test('descarta lance atrasado com thinkTime ao sair do jogo', () async {
    final p = XadrezProvider(
      thinkTime: const Duration(milliseconds: 50),
      aiRunner: firstMove,
    )..start(_vsPretas);
    expect(p.aiThinking, isTrue);
    p.exitToSetup();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(p.phase, XadrezPhase.setup);
    expect(p.aiThinking, isFalse);
    expect(p.lastMove, isNull);
    expect(p.game.position.turn, ChessSide.white);
    p.dispose();
  });

  test(
    'começar de novo durante o "Pensando..." descarta o lance velho',
    () async {
      final calls = <ChessPosition>[];
      final p = XadrezProvider(
        thinkTime: const Duration(milliseconds: 50),
        aiRunner: (pos, l) {
          calls.add(pos);
          return firstMove(pos, l);
        },
      )..start(_vsPretas);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      p.start(_duo); // duas pessoas: ninguém deve jogar sozinho
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(calls, isEmpty);
      expect(p.lastMove, isNull);
      expect(p.aiThinking, isFalse);
      expect(p.currentPlayer, 1);
      // E contra o computador de novo: só o lance da partida nova vale.
      p.start(_vsPretas);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      p.start(_vsPretas);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(calls.length, 1);
      expect(p.game.position.turn, ChessSide.black);
      expect(p.game.position.fullmove, 1);
      p.dispose();
    },
  );

  test('runner padrão recebe o histórico de repetições da partida', () async {
    // Torres que vão e voltam: as chaves recentes crescem sem captura.
    final p = XadrezProvider(random: Random(1), thinkTime: Duration.zero)
      ..startFrom(
        const PlayerSetupResult(
          mode: PlayMode.solo,
          player1: 'Ana',
          player2: 'C',
          levelIndex: 0,
          sideIndex: 0,
        ),
        fen('r3k3/8/8/8/8/8/8/R3K3 w - - 0 1'),
      );
    expect(p.lastAiHistory, isNull);
    tapMove(p, 'a1', 'b1');
    final expected = List<String>.of(p.game.recentKeys);
    expect(expected.length, 2);
    await settle();
    expect(p.lastAiHistory, expected);
    expect(p.lastMove, isNotNull);
    p.dispose();
  });

  test('runner que falha joga um lance legal', () async {
    final p = make(runner: (_, _) async => throw StateError('falhou'))
      ..start(_vsPretas);
    await settle();
    expect(p.aiThinking, isFalse);
    expect(p.lastMove, isNotNull);
    expect(p.game.position.turn, ChessSide.black);
  });

  test('runner que devolve lance ilegal joga um lance legal', () async {
    final p = make(
      runner: (_, _) async => ChessMove(squareOf('e2'), squareOf('e5')),
    )..start(_vsPretas);
    await settle();
    expect(p.lastMove, isNotNull);
    expect(p.lastMove!.to, isNot(squareOf('e5')));
    expect(p.game.position.turn, ChessSide.black);
  });

  test('não notifica depois do dispose', () async {
    final answer = Completer<ChessMove>();
    final p = make(runner: (_, _) => answer.future)..start(_vsPretas);
    var calls = 0;
    p.addListener(() => calls++);
    await settle();
    p.dispose();
    answer.complete(ChessPosition.initial().legalMoves().first);
    await settle();
    expect(calls, 0);
  });

  test('playAgain mantém as cores e o placar', () async {
    final p = make()
      ..startFrom(_vsPretas, fen('4k3/8/8/8/8/8/8/4K3 w - - 0 1'));
    expect(p.phase, XadrezPhase.finished);
    expect(p.draws, 1);
    p.playAgain();
    expect(p.player1Side, ChessSide.black);
    expect(p.name1, 'Ana');
    expect(p.draws, 1);
    expect(p.phase, XadrezPhase.playing);
    expect(p.isComputerTurn, isTrue);
    await settle();
    expect(p.game.position.turn, ChessSide.black);
  });

  test('playAgain só vale depois do fim', () {
    final p = make()..start(_duo);
    tapMove(p, 'e2', 'e4');
    p.playAgain();
    expect(p.currentPlayer, 2);
    expect(p.lastMove, isNotNull);
  });

  test('startFrom começa de uma posição própria', () {
    final p = make()..startFrom(_duo, fen('4k3/8/8/8/8/8/4P3/4K3 b - - 0 1'));
    expect(p.phase, XadrezPhase.playing);
    expect(p.currentPlayer, 2);
    expect(p.game.position.cells[e2], kPawn);
  });

  test('exitToSetup zera o placar', () {
    final p = make()..startFrom(_duo, fen('4k3/8/8/8/8/8/8/4K3 w - - 0 1'));
    expect(p.draws, 1);
    p.exitToSetup();
    expect(p.phase, XadrezPhase.setup);
    expect([p.wins1, p.wins2, p.draws], [0, 0, 0]);
    expect(p.checkSquare, isNull);
  });

  test('runner padrão joga nos três níveis', () async {
    for (final level in [0, 1, 2]) {
      final p = XadrezProvider(random: Random(1), thinkTime: Duration.zero)
        ..start(
          PlayerSetupResult(
            mode: PlayMode.solo,
            player1: 'Ana',
            player2: 'C',
            levelIndex: level,
            sideIndex: 1,
          ),
        );
      var i = 0;
      while (p.lastMove == null && i++ < 400) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(p.lastMove, isNotNull, reason: 'nível $level');
      expect(p.game.position.turn, ChessSide.black);
      p.dispose();
    }
  });
}
