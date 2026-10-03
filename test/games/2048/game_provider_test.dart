// test/games/2048/game_provider_test.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/2048/data/high_score_store.dart';
import 'package:brincaki/games/2048/logic/board_logic.dart';
import 'package:brincaki/games/2048/models/game_state.dart';
import 'package:brincaki/games/2048/providers/game_provider.dart';

class MemoryHighScoreStore implements HighScoreStore {
  MemoryHighScoreStore([this.value = 0]);
  int value;
  Completer<int>? pendingLoad;

  @override
  Future<int> load() => pendingLoad?.future ?? Future.value(value);

  @override
  Future<void> save(int v) async => value = v;
}

int countTiles(List<List<int>> board) =>
    board.expand((row) => row).where((v) => v != 0).length;

void main() {
  group('Game2048Provider', () {
    late MemoryHighScoreStore store;
    late Game2048Provider provider;

    setUp(() {
      store = MemoryHighScoreStore();
      provider = Game2048Provider(store: store, random: Random(42));
    });

    test('começa com 2 peças, 0 pontos e fase playing', () {
      expect(countTiles(provider.board), 2);
      expect(provider.score, 0);
      expect(provider.phase, Game2048Phase.playing);
    });

    test('jogada que não muda nada não cria peça nova', () {
      provider.debugSetBoard([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(countTiles(provider.board), 1);
      expect(provider.moveCount, 0);
    });

    test('jogada válida soma pontos e cria uma peça 2 ou 4', () {
      provider.debugSetBoard([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(provider.score, 4);
      expect(provider.board[0][0], 4);
      expect(countTiles(provider.board), 2);
      final (r, c) = provider.newTile!;
      expect(provider.board[r][c], anyOf(2, 4));
      expect(provider.mergedTiles, {(0, 0)});
      expect(provider.moveCount, 1);
    });

    test('formar 2048 vence uma vez só; continuePlaying volta a jogar', () {
      provider.debugSetBoard([
        [1024, 1024, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(provider.phase, Game2048Phase.won);

      final before = provider.board;
      provider.move(Direction.right); // ignorado enquanto o overlay aparece
      expect(provider.board, before);

      provider.continuePlaying();
      expect(provider.phase, Game2048Phase.playing);

      provider.debugSetBoard([
        [1024, 1024, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(provider.phase, Game2048Phase.playing);
    });

    test('tabuleiro travado depois da jogada dá derrota', () {
      provider.debugSetBoard([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [32, 4, 2, 4],
        [8, 16, 8, 0],
      ]);
      provider.move(Direction.right);
      expect(provider.phase, Game2048Phase.lost);
    });

    test('vitória com tabuleiro travado: Continuar leva ao fim de jogo', () {
      provider.debugSetBoard([
        [1024, 1024, 8, 16],
        [8, 16, 32, 64],
        [16, 32, 64, 128],
        [32, 64, 128, 256],
      ]);
      provider.move(Direction.left);
      expect(provider.phase, Game2048Phase.won);
      provider.continuePlaying();
      expect(provider.phase, Game2048Phase.lost);
    });

    test('carrega o recorde salvo e atualiza quando os pontos passam dele', () async {
      store = MemoryHighScoreStore(100);
      provider = Game2048Provider(store: store, random: Random(1));
      await Future<void>.delayed(Duration.zero);
      expect(provider.best, 100);

      provider.debugSetBoard([
        [64, 64, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(provider.score, 128);
      expect(provider.best, 128);
      expect(store.value, 128);
    });

    test('recorde que chega atrasado não sobrescreve um valor maior', () async {
      store = MemoryHighScoreStore()..pendingLoad = Completer<int>();
      provider = Game2048Provider(store: store, random: Random(1));
      provider.debugSetBoard([
        [4, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(provider.best, 8);

      store.pendingLoad!.complete(2);
      await Future<void>.delayed(Duration.zero);
      expect(provider.best, 8);
    });

    test('newGame zera pontos e mantém o recorde', () {
      provider.debugSetBoard([
        [4, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      provider.newGame();
      expect(provider.score, 0);
      expect(provider.best, 8);
      expect(countTiles(provider.board), 2);
      expect(provider.phase, Game2048Phase.playing);
    });
  });
}
