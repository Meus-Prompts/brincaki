// test/games/lig4/game_provider_test.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/lig4/logic/ai.dart';
import 'package:brincaki/games/lig4/logic/board.dart';
import 'package:brincaki/games/lig4/models/game_state.dart';
import 'package:brincaki/games/lig4/providers/game_provider.dart';
import 'package:brincaki/widgets/player_setup.dart';

const _duo = PlayerSetupResult(mode: PlayMode.twoPlayers, player1: 'Ana', player2: 'Beto');
const _vsAi = PlayerSetupResult(
    mode: PlayMode.solo, player1: 'Ana', player2: 'Computador', levelIndex: 1);

/// Computador previsível: primeira coluna livre.
Future<int> firstFree(List<List<int>> board, int me, AiLevel level) async =>
    validColumns(board).first;

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('dois jogadores alternam e a vitória atualiza o placar', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    expect(p.phase, Lig4Phase.playing);
    for (final col in [0, 1, 0, 1, 0, 1]) {
      p.play(col);
    }
    expect(p.currentPlayer, 1);
    p.play(0); // quatro em pé na coluna 0
    expect(p.phase, Lig4Phase.finished);
    expect(p.winner, 1);
    expect(p.winningCells, hasLength(4));
    expect(p.wins1, 1);
    p.play(2); // depois do fim, nada muda
    expect(p.board[5][2], 0);
  });

  test('coluna cheia é ignorada', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    for (var i = 0; i < kRows; i++) {
      p.play(3);
    }
    final player = p.currentPlayer;
    p.play(3);
    expect(p.currentPlayer, player);
  });

  test('empate com o tabuleiro cheio', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    // Ordem conferida: enche as 42 casas sem ninguém alinhar 4.
    const order = [0, 1, 0, 1, 0, 1, 2, 3, 2, 3, 2, 3, 1, 0, 1, 0, 1, 0,
                   3, 2, 3, 2, 3, 2, 4, 5, 4, 5, 4, 5, 6, 4, 5, 6, 6, 4,
                   5, 6, 6, 4, 5, 6];
    for (final col in order) {
      p.play(col);
    }
    expect(isFull(p.board), isTrue);
    expect(p.phase, Lig4Phase.finished);
    expect(p.winner, isNull);
    expect(p.draws, 1);
  });

  test('contra o computador: ele responde e toques na vez dele são ignorados',
      () async {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_vsAi);
    expect(p.aiLevel, AiLevel.medium);
    p.play(3);
    expect(p.isComputerTurn, isTrue);
    p.play(4); // vez do computador: ignorado
    expect(p.board[5][4], 0);
    await settle();
    expect(p.board[5][0], Lig4Provider.computer);
    expect(p.currentPlayer, 1);
    expect(p.aiThinking, isFalse);
  });

  test('jogada do computador que chega depois de sair é descartada', () async {
    final p = Lig4Provider(thinkTime: const Duration(milliseconds: 50), aiRunner: firstFree)
      ..start(_vsAi);
    p.play(3);
    p.exitToSetup();
    p.start(_vsAi); // partida nova antes da resposta atrasada chegar
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(p.board.expand((r) => r).every((v) => v == 0), isTrue,
        reason: 'a jogada da partida antiga não pode cair na nova');
    expect(p.currentPlayer, 1);
    expect(p.aiThinking, isFalse);
  });

  test('jogar de novo alterna quem começa; o computador começa sozinho',
      () async {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_vsAi);
    // Humano vence rápido na coluna 6 (o computador joga sempre na 0).
    for (var i = 0; i < 4; i++) {
      p.play(6);
      await settle();
    }
    expect(p.winner, 1);
    p.playAgain();
    await settle();
    expect(p.board[5][0], Lig4Provider.computer);
    expect(p.currentPlayer, 1);
  });

  test('se o computador der erro, ele joga numa coluna válida e o jogo segue',
      () async {
    final p = Lig4Provider(
      thinkTime: Duration.zero,
      aiRunner: (board, me, level) async => throw StateError('falhou'),
    )..start(_vsAi);
    p.play(3);
    await settle();
    expect(p.aiThinking, isFalse);
    expect(p.currentPlayer, 1, reason: 'a vez voltou para o humano');
    final pieces = p.board.expand((r) => r).where((v) => v != 0).length;
    expect(pieces, 2);
  });

  test('começa na tela de início e ignora jogadas antes de começar', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree);
    expect(p.phase, Lig4Phase.setup);
    expect(p.isComputerTurn, isFalse);
    p.play(3);
    expect(p.board[5][3], 0);
    p.playAgain(); // fora de fase: nada acontece
    expect(p.phase, Lig4Phase.setup);
  });

  test('start guarda nomes, modo e nível de cada índice', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree);
    for (final (index, level) in [
      (0, AiLevel.easy),
      (1, AiLevel.medium),
      (2, AiLevel.hard),
      (null, AiLevel.medium),
    ]) {
      p.start(PlayerSetupResult(
        mode: PlayMode.solo,
        player1: 'Ana',
        player2: 'Computador',
        levelIndex: index,
      ));
      expect(p.aiLevel, level);
      expect(p.mode, PlayMode.solo);
      expect(p.name1, 'Ana');
      expect(p.name2, 'Computador');
      expect(p.currentPlayer, 1, reason: 'o humano começa a primeira');
    }
  });

  test('jogada registra a última peça e conta as jogadas', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    expect(p.lastMove, isNull);
    expect(p.moveCount, 0);
    p.play(2);
    expect(p.lastMove, (5, 2));
    p.play(2);
    expect(p.lastMove, (4, 2));
    expect(p.moveCount, 2);
    expect(p.board[4][2], 2);
  });

  test('vitória do jogador 2 conta no placar dele', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    for (final col in [0, 1, 0, 1, 0, 1, 6, 1]) {
      p.play(col);
    }
    expect(p.winner, 2);
    expect(p.wins2, 1);
    expect(p.wins1, 0);
    expect(p.winningCells, [(2, 1), (3, 1), (4, 1), (5, 1)]);
  });

  test('em dois jogadores nunca é a vez do computador', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    p.play(0);
    expect(p.currentPlayer, 2);
    expect(p.isComputerTurn, isFalse);
    expect(p.aiThinking, isFalse);
  });

  test('jogar de novo alterna quem começa a cada partida', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    void quickWin() {
      // Quem começa empilha na coluna 0; o outro na 1.
      for (final col in [0, 1, 0, 1, 0, 1, 0]) {
        p.play(col);
      }
    }

    quickWin();
    p.playAgain();
    expect(p.phase, Lig4Phase.playing);
    expect(p.currentPlayer, 2);
    expect(p.board.expand((r) => r).every((v) => v == 0), isTrue);
    expect(p.winner, isNull);
    expect(p.winningCells, isNull);
    expect(p.lastMove, isNull);
    expect(p.moveCount, 0);
    quickWin();
    expect(p.winner, 2);
    expect(p.wins1, 1);
    expect(p.wins2, 1, reason: 'o placar continua entre as partidas');
    p.playAgain();
    expect(p.currentPlayer, 1);
  });

  test('start depois de trocar jogadores volta o humano a começar', () async {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    for (final col in [0, 1, 0, 1, 0, 1, 0]) {
      p.play(col);
    }
    p.playAgain(); // agora o 2 começaria
    p.exitToSetup();
    p.start(_duo);
    expect(p.currentPlayer, 1);
  });

  test('o computador pode vencer e conta no placar dele', () async {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_vsAi);
    // O computador empilha na coluna 0; o humano se espalha sem alinhar.
    for (final col in [6, 5, 6, 5]) {
      p.play(col);
      await settle();
    }
    expect(p.phase, Lig4Phase.finished);
    expect(p.winner, Lig4Provider.computer);
    expect(p.wins2, 1);
    expect(p.isComputerTurn, isFalse);
  });

  test('pensando: avisa a tela e só joga depois do tempo de pensar', () async {
    final p = Lig4Provider(thinkTime: const Duration(milliseconds: 50), aiRunner: firstFree)
      ..start(_vsAi);
    var notified = 0;
    p.addListener(() => notified++);
    p.play(3);
    expect(p.aiThinking, isTrue);
    expect(notified, 2, reason: 'a jogada e o início do "pensando"');
    p.play(4); // pensando: ignorado
    expect(p.board[5][4], 0);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(p.board[5][0], 0);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(p.board[5][0], Lig4Provider.computer);
    expect(p.aiThinking, isFalse);
  });

  test('trocar jogadores enquanto o computador pensa cancela a jogada', () async {
    final p = Lig4Provider(thinkTime: const Duration(milliseconds: 20), aiRunner: firstFree)
      ..start(_vsAi);
    p.play(3);
    p.exitToSetup();
    expect(p.aiThinking, isFalse);
    expect(p.phase, Lig4Phase.setup);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(p.board[5][0], 0);
    expect(p.phase, Lig4Phase.setup);
  });

  test('resposta do computador que chega depois de trocar é descartada', () async {
    final answer = Completer<int>();
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: (b, me, l) => answer.future)
      ..start(_vsAi);
    p.play(3);
    await settle();
    p.exitToSetup();
    p.start(_duo);
    answer.complete(0);
    await settle();
    expect(p.board[5][0], 0);
    expect(p.currentPlayer, 1);
  });

  test('descartar o provider durante o tempo de pensar não dá erro', () async {
    var asked = false;
    final p = Lig4Provider(
      thinkTime: const Duration(milliseconds: 20),
      aiRunner: (b, me, l) async {
        asked = true;
        return 0;
      },
    )..start(_vsAi);
    p.play(3);
    p.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(asked, isFalse, reason: 'nem chega a perguntar ao computador');
  });

  test('descartar o provider com a resposta pendente não dá erro', () async {
    final answer = Completer<int>();
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: (b, me, l) => answer.future)
      ..start(_vsAi);
    p.play(3);
    await settle();
    p.dispose();
    answer.complete(0);
    await settle(); // notifyListeners depois do dispose lançaria erro
  });

  test('o computador recebe uma cópia do tabuleiro, o nível e quem ele é', () async {
    List<List<int>>? seen;
    int? seenMe;
    AiLevel? seenLevel;
    final p = Lig4Provider(
      thinkTime: Duration.zero,
      aiRunner: (b, me, level) async {
        seen = b;
        seenMe = me;
        seenLevel = level;
        b[0][0] = 9; // mexer na cópia não afeta o jogo
        return 1;
      },
    )..start(const PlayerSetupResult(
        mode: PlayMode.solo, player1: 'Ana', player2: 'Computador', levelIndex: 0));
    p.play(3);
    await settle();
    expect(seen![5][3], 1);
    expect(seenMe, Lig4Provider.computer);
    expect(seenLevel, AiLevel.easy);
    expect(p.board[0][0], 0);
    expect(p.board[5][1], Lig4Provider.computer);
  });

  test('com erro no computador, a coluna sorteada é sempre livre', () async {
    for (var seed = 0; seed < 10; seed++) {
      final p = Lig4Provider(
        random: Random(seed),
        thinkTime: Duration.zero,
        aiRunner: (b, me, l) async => throw StateError('falhou'),
      )..start(_vsAi);
      for (var i = 0; i < 3; i++) {
        p.play(3);
        await settle();
      }
      // A coluna 3 pode ter enchido; as peças nunca passam de 6 por coluna.
      final pieces = p.board.expand((r) => r).where((v) => v != 0).length;
      expect(pieces, 6, reason: 'semente $seed');
      expect(p.aiThinking, isFalse);
    }
  });

  test('computador de verdade nos níveis fácil e médio responde', () async {
    for (final index in [0, 1]) {
      final p = Lig4Provider(random: Random(index), thinkTime: Duration.zero)
        ..start(PlayerSetupResult(
            mode: PlayMode.solo, player1: 'Ana', player2: 'Computador', levelIndex: index));
      p.play(3);
      await settle();
      expect(p.currentPlayer, 1);
      expect(p.board.expand((r) => r).where((v) => v == Lig4Provider.computer), hasLength(1));
    }
  });

  test('computador difícil de verdade responde (em outro isolate)', () async {
    final p = Lig4Provider(random: Random(3), thinkTime: Duration.zero)
      ..start(const PlayerSetupResult(
          mode: PlayMode.solo, player1: 'Ana', player2: 'Computador', levelIndex: 2));
    p.play(3);
    for (var i = 0; i < 200 && p.aiThinking; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(p.aiThinking, isFalse);
    expect(p.currentPlayer, 1);
    expect(p.board.expand((r) => r).where((v) => v == Lig4Provider.computer), hasLength(1));
  });

  test('trocar jogadores zera o placar', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    for (final col in [0, 1, 0, 1, 0, 1, 0]) {
      p.play(col);
    }
    p.exitToSetup();
    expect(p.phase, Lig4Phase.setup);
    expect(p.wins1 + p.wins2 + p.draws, 0);
  });
}
