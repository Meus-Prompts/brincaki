// test/games/tictactoe/game_provider_test.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/tictactoe/logic/ai.dart';
import 'package:brincaki/games/tictactoe/logic/board.dart';
import 'package:brincaki/games/tictactoe/models/game_state.dart';
import 'package:brincaki/games/tictactoe/providers/game_provider.dart';
import 'package:brincaki/widgets/player_setup.dart';

const _duo = PlayerSetupResult(mode: PlayMode.twoPlayers, player1: 'Ana', player2: 'Beto');

PlayerSetupResult vsAi([int? level = 1]) => PlayerSetupResult(
  mode: PlayMode.solo,
  player1: 'Ana',
  player2: 'Computador',
  levelIndex: level,
);

/// Computador previsível: primeira casa livre.
Future<(int, int)> firstFree(List<List<int>> board, int me, AiLevel level) async =>
    freeCells(board).first;

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

TicTacToeProvider newProvider({AiRunner? aiRunner, Duration thinkTime = Duration.zero}) =>
    TicTacToeProvider(thinkTime: thinkTime, aiRunner: aiRunner ?? firstFree, random: Random(1));

int pieces(TicTacToeProvider p) => p.board.expand((r) => r).where((v) => v != 0).length;

/// Jogadas de dois jogadores em que o ❌ vence na linha de cima.
const _xWinsTopRow = [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)];

/// Jogadas que enchem o tabuleiro sem ninguém alinhar:
/// x o x / x o o / o x x
const _drawMoves = [(0, 0), (0, 1), (0, 2), (1, 1), (1, 0), (1, 2), (2, 1), (2, 0), (2, 2)];

void playAll(TicTacToeProvider p, List<(int, int)> moves) {
  for (final (r, c) in moves) {
    p.play(r, c);
  }
}

void main() {
  group('estado inicial', () {
    test('começa no setup com tudo zerado', () {
      final p = TicTacToeProvider();
      expect(p.phase, GamePhase.setup);
      expect(p.mode, PlayMode.twoPlayers);
      expect(p.name1, '');
      expect(p.name2, '');
      expect(p.aiLevel, AiLevel.medium);
      expect(p.board, emptyBoard());
      expect(p.currentPlayer, 1);
      expect(p.startingPlayer, 1);
      expect(p.winner, isNull);
      expect(p.winningCells, isNull);
      expect(p.wins1 + p.wins2 + p.draws, 0);
      expect(p.aiThinking, isFalse);
      expect(p.isComputerTurn, isFalse);
      p.dispose();
    });

    test('jogar, jogar de novo e sair antes de começar não fazem nada', () {
      final p = newProvider();
      var notified = 0;
      p.addListener(() => notified++);
      p.play(0, 0);
      p.playAgain();
      p.exitToSetup();
      expect(p.phase, GamePhase.setup);
      expect(p.board, emptyBoard());
      expect(notified, 0);
    });
  });

  group('start', () {
    test('dois jogadores: guarda os nomes e começa com o ❌', () {
      final p = newProvider();
      var notified = 0;
      p.addListener(() => notified++);
      p.start(_duo);
      expect(p.phase, GamePhase.playing);
      expect(p.mode, PlayMode.twoPlayers);
      expect(p.name1, 'Ana');
      expect(p.name2, 'Beto');
      expect(p.currentPlayer, 1);
      expect(p.isComputerTurn, isFalse);
      expect(notified, 1);
    });

    test('contra o computador: nível escolhido', () {
      for (final level in AiLevel.values) {
        final p = newProvider()..start(vsAi(level.index));
        expect(p.mode, PlayMode.solo);
        expect(p.aiLevel, level);
        expect(p.name2, 'Computador');
      }
    });

    test('sem nível, usa o médio', () {
      final p = newProvider()..start(vsAi(null));
      expect(p.aiLevel, AiLevel.medium);
    });

    test('no meio da partida é ignorado', () {
      final p = newProvider()..start(_duo);
      p.play(1, 1);
      p.start(vsAi());
      expect(p.mode, PlayMode.twoPlayers);
      expect(p.board[1][1], 1);
    });
  });

  group('play em dois jogadores', () {
    test('alterna ❌ e ⭕', () {
      final p = newProvider()..start(_duo);
      p.play(0, 0);
      expect(p.board[0][0], 1);
      expect(p.currentPlayer, 2);
      p.play(1, 1);
      expect(p.board[1][1], 2);
      expect(p.currentPlayer, 1);
    });

    test('não muda o tabuleiro antigo (gera uma cópia)', () {
      final p = newProvider()..start(_duo);
      final before = p.board;
      p.play(0, 0);
      expect(before[0][0], 0);
      expect(identical(before, p.board), isFalse);
    });

    test('casa ocupada é ignorada', () {
      final p = newProvider()..start(_duo);
      p.play(0, 0);
      var notified = 0;
      p.addListener(() => notified++);
      p.play(0, 0);
      expect(p.board[0][0], 1);
      expect(p.currentPlayer, 2);
      expect(notified, 0);
    });

    test('casa fora do tabuleiro é ignorada', () {
      final p = newProvider()..start(_duo);
      for (final (r, c) in const [(-1, 0), (0, -1), (3, 0), (0, 3)]) {
        p.play(r, c);
      }
      expect(p.board, emptyBoard());
      expect(p.currentPlayer, 1);
    });

    test('vitória do ❌: linha vencedora, placar e fim', () {
      final p = newProvider()..start(_duo);
      playAll(p, _xWinsTopRow);
      expect(p.phase, GamePhase.finished);
      expect(p.winner, 1);
      expect(p.winningCells, [(0, 0), (0, 1), (0, 2)]);
      expect(p.wins1, 1);
      expect(p.wins2, 0);
      expect(p.draws, 0);
      p.play(2, 2); // depois do fim, nada muda
      expect(p.board[2][2], 0);
    });

    test('vitória do ⭕ na diagonal', () {
      final p = newProvider()..start(_duo);
      playAll(p, const [(0, 1), (0, 0), (0, 2), (1, 1), (1, 0), (2, 2)]);
      expect(p.winner, 2);
      expect(p.winningCells, [(0, 0), (1, 1), (2, 2)]);
      expect(p.wins2, 1);
    });

    test('vitória na última casa conta como vitória, não empate', () {
      final p = newProvider()..start(_duo);
      // x o x / o x o / o x x: ❌ fecha a diagonal na 9ª jogada.
      playAll(p, const [(0, 0), (0, 1), (0, 2), (1, 0), (2, 1), (1, 2), (1, 1), (2, 0), (2, 2)]);
      expect(isFull(p.board), isTrue);
      expect(p.winner, 1);
      expect(p.winningCells, [(0, 0), (1, 1), (2, 2)]);
      expect(p.draws, 0);
    });

    test('empate com o tabuleiro cheio', () {
      final p = newProvider()..start(_duo);
      playAll(p, _drawMoves);
      expect(isFull(p.board), isTrue);
      expect(p.phase, GamePhase.finished);
      expect(p.winner, isNull);
      expect(p.winningCells, isNull);
      expect(p.draws, 1);
      expect(p.wins1 + p.wins2, 0);
    });
  });

  group('playAgain', () {
    test('alterna quem começa e mantém o placar', () {
      final p = newProvider()..start(_duo);
      playAll(p, _xWinsTopRow);
      p.playAgain();
      expect(p.phase, GamePhase.playing);
      expect(p.board, emptyBoard());
      expect(p.winner, isNull);
      expect(p.winningCells, isNull);
      expect(p.startingPlayer, 2);
      expect(p.currentPlayer, 2);
      expect(p.wins1, 1);
      p.play(0, 0);
      expect(p.board[0][0], 2, reason: 'o ⭕ começa a segunda partida');
      playAll(p, const [(1, 0), (0, 1), (1, 1), (0, 2)]);
      expect(p.winner, 2);
      p.playAgain();
      expect(p.startingPlayer, 1);
      expect(p.currentPlayer, 1);
      expect(p.wins1, 1);
      expect(p.wins2, 1);
    });

    test('no meio da partida é ignorado', () {
      final p = newProvider()..start(_duo);
      p.play(0, 0);
      p.playAgain();
      expect(p.board[0][0], 1);
      expect(p.startingPlayer, 1);
    });
  });

  group('exitToSetup', () {
    test('volta ao setup e zera o placar', () {
      final p = newProvider()..start(_duo);
      playAll(p, _xWinsTopRow);
      p.playAgain();
      playAll(p, _drawMoves);
      expect(p.wins1 + p.draws, 2);
      p.exitToSetup();
      expect(p.phase, GamePhase.setup);
      expect(p.wins1 + p.wins2 + p.draws, 0);
      expect(p.aiThinking, isFalse);
    });

    test('dá para sair no meio da partida e começar de novo', () {
      final p = newProvider()..start(_duo);
      p.play(1, 1);
      p.exitToSetup();
      p.start(_duo);
      expect(p.board, emptyBoard());
      expect(p.currentPlayer, 1);
    });
  });

  group('contra o computador', () {
    test('ele responde, e toques na vez dele são ignorados', () async {
      final p = newProvider()..start(vsAi());
      p.play(1, 1);
      expect(p.isComputerTurn, isTrue);
      expect(p.aiThinking, isTrue);
      p.play(2, 2); // vez do computador: ignorado
      expect(p.board[2][2], 0);
      await settle();
      expect(p.board[0][0], TicTacToeProvider.computer);
      expect(p.currentPlayer, 1);
      expect(p.aiThinking, isFalse);
      expect(p.isComputerTurn, isFalse);
    });

    test('jogada durante "Pensando..." é ignorada até ele terminar', () async {
      final p = newProvider(thinkTime: const Duration(milliseconds: 30))..start(vsAi());
      p.play(1, 1);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(p.aiThinking, isTrue);
      p.play(2, 2);
      expect(p.board[2][2], 0);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(p.aiThinking, isFalse);
      expect(pieces(p), 2);
      p.play(2, 2);
      expect(p.board[2][2], 1);
    });

    test('o runner recebe uma cópia do tabuleiro, o jogador 2 e o nível', () async {
      List<List<int>>? seen;
      int? seenMe;
      AiLevel? seenLevel;
      final p = newProvider(
        aiRunner: (board, me, level) async {
          seen = board;
          seenMe = me;
          seenLevel = level;
          board[2][2] = 1; // mexer na cópia não pode afetar o jogo
          return (0, 0);
        },
      )..start(vsAi(2));
      p.play(1, 1);
      await settle();
      expect(seenMe, 2);
      expect(seenLevel, AiLevel.hard);
      expect(seen![1][1], 1);
      expect(p.board[2][2], 0);
      expect(p.board[0][0], 2);
    });

    test('o computador vence e soma para o jogador 2', () async {
      // O computador joga sempre na primeira livre e enche a linha de cima.
      final p = newProvider()..start(vsAi());
      for (final (r, c) in const [(2, 0), (1, 1), (2, 2)]) {
        p.play(r, c);
        await settle();
      }
      expect(p.winner, TicTacToeProvider.computer);
      expect(p.winningCells, [(0, 0), (0, 1), (0, 2)]);
      expect(p.wins2, 1);
      expect(p.phase, GamePhase.finished);
      expect(p.isComputerTurn, isFalse);
    });

    test('humano vence e o computador não joga depois do fim', () async {
      final p = newProvider()..start(vsAi());
      // Computador sempre na primeira livre: (0,0), (0,1)...
      for (final (r, c) in const [(2, 0), (2, 1), (2, 2)]) {
        p.play(r, c);
        await settle();
      }
      expect(p.winner, 1);
      expect(p.wins1, 1);
      expect(pieces(p), 5);
      expect(p.aiThinking, isFalse);
    });

    test('jogar de novo alterna; quando é a vez dele, o computador começa sozinho', () async {
      final p = newProvider()..start(vsAi());
      for (final (r, c) in const [(2, 0), (2, 1), (2, 2)]) {
        p.play(r, c);
        await settle();
      }
      expect(p.winner, 1);
      p.playAgain();
      expect(p.startingPlayer, 2);
      expect(p.isComputerTurn, isTrue);
      expect(p.aiThinking, isTrue);
      p.play(1, 1); // vez dele: ignorado
      await settle();
      expect(p.board[0][0], TicTacToeProvider.computer);
      expect(p.board[1][1], 0);
      expect(p.currentPlayer, 1);
      expect(p.aiThinking, isFalse);
    });

    test('dois jogadores nunca chamam o computador', () async {
      var calls = 0;
      final p = newProvider(
        aiRunner: (board, me, level) async {
          calls++;
          return freeCells(board).first;
        },
      )..start(_duo);
      playAll(p, _xWinsTopRow);
      p.playAgain();
      await settle();
      expect(calls, 0);
      expect(p.currentPlayer, 2);
      expect(p.board, emptyBoard());
    });

    test('exitToSetup durante "Pensando..." descarta a jogada atrasada', () async {
      final p = newProvider(thinkTime: const Duration(milliseconds: 50))..start(vsAi());
      p.play(1, 1);
      expect(p.aiThinking, isTrue);
      p.exitToSetup();
      expect(p.aiThinking, isFalse);
      expect(p.phase, GamePhase.setup);
      p.start(vsAi()); // partida nova antes da resposta atrasada chegar
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(p.board, emptyBoard(), reason: 'a jogada da partida antiga não pode cair na nova');
      expect(p.currentPlayer, 1);
      expect(p.aiThinking, isFalse);
    });

    test('resposta do runner que chega depois de sair é descartada', () async {
      final answer = Completer<(int, int)>();
      final p = newProvider(aiRunner: (board, me, level) => answer.future)..start(vsAi());
      p.play(1, 1);
      await settle();
      expect(p.aiThinking, isTrue);
      p.exitToSetup();
      p.start(vsAi());
      answer.complete((0, 0));
      await settle();
      expect(p.board, emptyBoard());
      expect(p.aiThinking, isFalse);
    });

    test('dispose durante "Pensando..." não notifica nem dá erro', () async {
      final p = newProvider(thinkTime: const Duration(milliseconds: 20))..start(vsAi());
      p.play(1, 1);
      p.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      // Se notificasse depois do dispose, o ChangeNotifier lançaria um erro.
    });

    test('dispose enquanto o runner calcula não notifica nem dá erro', () async {
      final answer = Completer<(int, int)>();
      final p = newProvider(aiRunner: (board, me, level) => answer.future)..start(vsAi());
      p.play(1, 1);
      await settle();
      p.dispose();
      answer.complete((0, 0));
      await settle();
    });

    test('se o runner lançar exceção, joga numa casa livre e o jogo segue', () async {
      final p = newProvider(aiRunner: (board, me, level) async => throw StateError('falhou'))
        ..start(vsAi());
      p.play(1, 1);
      await settle();
      expect(p.aiThinking, isFalse);
      expect(p.currentPlayer, 1, reason: 'a vez voltou para o humano');
      expect(pieces(p), 2);
      expect(p.board.expand((r) => r).where((v) => v == 2), hasLength(1));
    });

    test('se o runner devolver casa ocupada ou fora, joga numa casa livre', () async {
      for (final bad in const [(1, 1), (5, 5), (-1, 0)]) {
        final p = newProvider(aiRunner: (board, me, level) async => bad)..start(vsAi());
        p.play(1, 1);
        await settle();
        expect(p.board[1][1], 1, reason: '$bad');
        expect(pieces(p), 2, reason: '$bad');
        expect(p.currentPlayer, 1);
      }
    });

    test('runner padrão: o difícil nunca perde do humano jogando a primeira livre', () async {
      for (final level in AiLevel.values) {
        final p = TicTacToeProvider(thinkTime: Duration.zero, random: Random(3))
          ..start(vsAi(level.index));
        while (p.phase == GamePhase.playing) {
          final (r, c) = freeCells(p.board).first;
          p.play(r, c);
          await settle();
        }
        expect(p.phase, GamePhase.finished);
        if (level == AiLevel.hard) expect(p.winner, isNot(1));
      }
    });

    test('notifica ao começar e ao terminar de pensar', () async {
      final p = newProvider()..start(vsAi());
      final thinking = <bool>[];
      p.addListener(() => thinking.add(p.aiThinking));
      p.play(1, 1);
      await settle();
      // jogada do humano, começa a pensar, jogada do computador
      expect(thinking, [false, true, false]);
    });
  });
}
