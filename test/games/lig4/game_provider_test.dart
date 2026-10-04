// test/games/lig4/game_provider_test.dart

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
