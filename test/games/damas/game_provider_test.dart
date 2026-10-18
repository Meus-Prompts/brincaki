// test/games/damas/game_provider_test.dart

import 'dart:async';
import 'dart:math';

import 'package:brincaki/games/damas/logic/ai.dart';
import 'package:brincaki/games/damas/logic/board.dart';
import 'package:brincaki/games/damas/models/game_state.dart';
import 'package:brincaki/games/damas/providers/game_provider.dart';
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

Future<DamasMove> firstMove(DamasPosition p, AiLevel l) async =>
    legalMoves(p).first;

DamasPosition pos(Map<int, int> pieces, [DamasSide turn = DamasSide.white]) {
  final cells = List<int>.filled(64, 0);
  pieces.forEach((i, v) => cells[i] = v);
  return DamasPosition(cells, turn);
}

DamasProvider make({DamasAiRunner? runner, Duration t = Duration.zero}) =>
    DamasProvider(thinkTime: t, aiRunner: runner ?? firstMove);

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('começa na fase setup', () {
    expect(make().phase, DamasPhase.setup);
  });

  test('start com brancas: vez do jogador 1', () {
    final p = make()..start(_duo);
    expect(p.phase, DamasPhase.playing);
    expect(p.currentPlayer, 1);
    expect(p.player1Side, DamasSide.white);
    expect(p.flipped, isFalse);
    expect(p.isComputerTurn, isFalse);
  });

  test('seleciona peça e acende destinos', () {
    final p = make()..start(_duo);
    p.tapSquare(42); // linha 5, coluna 2
    expect(p.selected, 42);
    expect(p.targets, {33, 35});
    p.tapSquare(42);
    expect(p.selected, isNull);
    p.tapSquare(42);
    p.tapSquare(0);
    expect(p.selected, isNull);
    expect(p.targets, isEmpty);
  });

  test('peça que não pode capturar não é selecionada quando há captura', () {
    final p = make()..startFrom(_duo, pos({42: 1, 60: 1, 33: -1}));
    p.tapSquare(60);
    expect(p.selected, isNull);
    p.tapSquare(42);
    expect(p.selected, 42);
  });

  test('mustCapture lista as peças obrigadas', () {
    final p = make()..startFrom(_duo, pos({42: 1, 60: 1, 33: -1}));
    expect(p.mustCapture, {42});
    expect((make()..start(_duo)).mustCapture, isEmpty);
  });

  test('salto por toque só acende pousos da maioria', () {
    // Dama em 56 (7,0): pode comer 49? Monta duas capturas em sequência.
    final p = make()..startFrom(_duo, pos({49: 1, 42: -1, 26: -1}));
    p.tapSquare(49);
    expect(p.targets, {35});
    p.tapSquare(35);
    expect(p.partialPath, [49, 35]);
    expect(p.capturedSoFar, {42});
    expect(p.currentPlayer, 1);
    p.tapSquare(0); // só alvos valem depois que o salto começou
    expect(p.partialPath, [49, 35]);
    expect(p.targets, {17});
    p.tapSquare(17);
    expect(p.currentPlayer, 2);
    expect(p.game.position.cells[26], 0);
    expect(p.game.position.cells[42], 0);
    expect(p.lastMove!.captured, [42, 26]);
    expect(p.partialPath, isEmpty);
  });

  test('troca a vez depois do lance completo', () {
    final p = make()..start(_duo);
    p.tapSquare(42);
    p.tapSquare(35);
    expect(p.currentPlayer, 2);
    expect(p.game.position.turn, DamasSide.black);
    expect(p.lastMove!.to, 35);
    expect(p.selected, isNull);
  });

  testWidgets('computador joga depois do thinkTime', (tester) async {
    final p = make(t: const Duration(milliseconds: 500))..start(_vsPretas);
    // pretas é o humano; as brancas (computador) abrem.
    expect(p.aiThinking, isTrue);
    await tester.pump(const Duration(milliseconds: 499));
    expect(p.aiThinking, isTrue);
    await tester.pump(const Duration(milliseconds: 2));
    expect(p.aiThinking, isFalse);
    expect(p.game.position.turn, DamasSide.black);
    expect(p.lastMove, isNotNull);
  });

  test('computador responde ao lance do humano', () async {
    final p = make()..start(_vsBrancas);
    p.tapSquare(42);
    p.tapSquare(35);
    expect(p.aiThinking, isTrue);
    await settle();
    expect(p.aiThinking, isFalse);
    expect(p.game.position.turn, DamasSide.white);
    expect(p.lastMove!.from ~/ 8 <= 3, isTrue);
    expect(p.selected, isNull);
  });

  test('com pretas o computador começa', () async {
    final p = make()..start(_vsPretas);
    expect(p.flipped, isTrue);
    expect(p.isComputerTurn, isTrue);
    expect(p.currentPlayer, 2);
    await settle();
    expect(p.game.position.turn, DamasSide.black);
    expect(p.currentPlayer, 1);
  });

  test('ignora toques na vez do computador', () async {
    final p = make(t: const Duration(milliseconds: 50))..start(_vsPretas);
    p.tapSquare(17);
    expect(p.selected, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(p.game.position.turn, DamasSide.black);
  });

  test('ignora toques depois do fim', () {
    final p = make()..startFrom(_duo, pos({42: 1, 33: -1}));
    p.tapSquare(42);
    p.tapSquare(24);
    expect(p.phase, DamasPhase.finished);
    final cells = p.game.position.cells;
    p.tapSquare(24);
    p.tapSquare(18);
    expect(p.game.position.cells, cells);
    expect(p.selected, isNull);
  });

  test('descarta lance atrasado do computador', () async {
    final answer = Completer<DamasMove>();
    final p = make(runner: (_, _) => answer.future)..start(_vsPretas);
    await settle();
    expect(p.aiThinking, isTrue);
    p.exitToSetup();
    answer.complete(legalMoves(DamasPosition.initial()).first);
    await settle();
    expect(p.phase, DamasPhase.setup);
    expect(p.aiThinking, isFalse);
    expect(p.lastMove, isNull);
  });

  test('runner que falha joga um lance legal', () async {
    final p = make(runner: (_, _) async => throw StateError('falhou'))
      ..start(_vsPretas);
    await settle();
    expect(p.aiThinking, isFalse);
    expect(p.lastMove, isNotNull);
    expect(p.game.position.turn, DamasSide.black);
  });

  test('runner que devolve lance ilegal joga um lance legal', () async {
    final p = make(runner: (_, _) async => const DamasMove([0, 1], []))
      ..start(_vsPretas);
    await settle();
    expect(p.lastMove, isNotNull);
    expect(p.lastMove!.from, isNot(0));
  });

  test('não notifica depois do dispose', () async {
    final answer = Completer<DamasMove>();
    final p = make(runner: (_, _) => answer.future)..start(_vsPretas);
    var calls = 0;
    p.addListener(() => calls++);
    await settle();
    p.dispose();
    answer.complete(legalMoves(DamasPosition.initial()).first);
    await settle();
    expect(calls, 0);
  });

  test('vitória soma no placar e playAgain mantém as cores', () async {
    final p = make()..startFrom(_vsPretas, pos({42: 1, 33: -1}));
    // pretas = humano; brancas (computador) joga primeiro e captura.
    await settle();
    expect(p.phase, DamasPhase.finished);
    expect(p.winnerPlayer, 2);
    expect(p.wins2, 1);
    expect(p.wins1, 0);
    p.playAgain();
    expect(p.player1Side, DamasSide.black);
    expect(p.name1, 'Ana');
    expect(p.wins2, 1);
    expect(p.phase, DamasPhase.playing);
    expect(p.isComputerTurn, isTrue);
    await settle();
    expect(p.game.position.turn, DamasSide.black);
  });

  test('vitória do jogador 1 com as brancas soma em wins1', () {
    final p = make()..startFrom(_duo, pos({42: 1, 33: -1}));
    p.tapSquare(42);
    p.tapSquare(24);
    expect(p.winnerPlayer, 1);
    expect(p.wins1, 1);
  });

  test('playAgain só vale depois do fim', () {
    final p = make()..start(_duo);
    p.tapSquare(42);
    p.tapSquare(35);
    p.playAgain();
    expect(p.currentPlayer, 2);
    expect(p.lastMove, isNotNull);
  });

  test('sem peças do lado da vez termina a partida', () {
    final p = make()..startFrom(_duo, pos({}, DamasSide.white));
    // sem peças brancas: derrota das brancas.
    expect(p.phase, DamasPhase.finished);
    expect(p.winnerPlayer, 2);
    final q = make()..start(_duo);
    expect(q.winnerPlayer, isNull);
    expect(q.draws, 0);
  });

  test('startFrom começa de uma posição própria', () {
    final p = make()..startFrom(_duo, pos({42: 1, 9: -1}, DamasSide.black));
    expect(p.phase, DamasPhase.playing);
    expect(p.currentPlayer, 2);
    expect(p.game.position.cells[42], 1);
  });

  test('exitToSetup zera o placar', () {
    final p = make()..startFrom(_duo, pos({42: 1, 33: -1}));
    p.tapSquare(42);
    p.tapSquare(24);
    expect(p.wins1, 1);
    p.exitToSetup();
    expect(p.phase, DamasPhase.setup);
    expect([p.wins1, p.wins2, p.draws], [0, 0, 0]);
  });

  test('runner padrão joga nos três níveis', () async {
    for (final level in [0, 1, 2]) {
      final p = DamasProvider(random: Random(1), thinkTime: Duration.zero)
        ..start(
          PlayerSetupResult(
            mode: PlayMode.solo,
            player1: 'Ana',
            player2: 'C',
            levelIndex: level,
            sideIndex: 1,
          ),
        );
      for (var i = 0; i < 400 && p.aiThinking || p.lastMove == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(p.lastMove, isNotNull, reason: 'nível $level');
      expect(p.game.position.turn, DamasSide.black);
      p.dispose();
    }
  });
}
