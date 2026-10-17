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
  int saves = 0;
  Completer<int>? pendingLoad;
  bool failLoad = false;

  @override
  Future<int> load() {
    if (failLoad) return Future.error(StateError('sem disco'));
    return pendingLoad?.future ?? Future.value(value);
  }

  @override
  Future<void> save(int v) async {
    saves++;
    value = v;
  }
}

/// Sempre escolhe a primeira casa vazia; [roll] decide se nasce 2 ou 4.
class FixedRandom implements Random {
  FixedRandom(this.roll);
  final double roll;

  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => roll;
  @override
  bool nextBool() => false;
}

int countTiles(List<List<int>> board) =>
    board.expand((row) => row).where((v) => v != 0).length;

List<List<int>> withFirstRow(List<int> row) => [
      row,
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ];

const lockedAfterRight = [
  [2, 4, 2, 4],
  [4, 2, 4, 2],
  [32, 4, 2, 4],
  [8, 16, 8, 0],
];

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
      expect(provider.best, 0);
      expect(provider.moveCount, 0);
      expect(provider.mergedTiles, isEmpty);
      expect(provider.phase, Game2048Phase.playing);
      final (r, c) = provider.newTile!;
      expect(provider.board[r][c], anyOf(2, 4));
      expect(provider.board.length, Game2048Provider.size);
    });

    test('peça nova é 2 em 90% dos casos e 4 no resto', () {
      final twos = Game2048Provider(store: store, random: FixedRandom(0.5));
      expect(twos.board[0][0], 2);
      expect(twos.board[0][1], 2);

      final fours = Game2048Provider(store: store, random: FixedRandom(0.95));
      expect(fours.board[0][0], 4);
      expect(fours.board[0][1], 4);
      expect(fours.newTile, (0, 1));
    });

    test('a peça nova nasce numa casa vazia', () {
      final p = Game2048Provider(store: store, random: FixedRandom(0.1));
      p.debugSetBoard(withFirstRow([0, 0, 0, 2]));
      p.move(Direction.left);
      // A primeira casa vazia depois de mover é (0, 1).
      expect(p.board[0], [2, 2, 0, 0]);
      expect(p.newTile, (0, 1));
    });

    test('jogada que não muda nada não cria peça nem avisa ninguém', () {
      provider.debugSetBoard(withFirstRow([2, 0, 0, 0]));
      var notified = 0;
      provider.addListener(() => notified++);
      provider.move(Direction.left);
      provider.move(Direction.up);
      expect(countTiles(provider.board), 1);
      expect(provider.moveCount, 0);
      expect(notified, 0);
    });

    test('jogada válida soma pontos, cria uma peça e avisa', () {
      provider.debugSetBoard(withFirstRow([2, 2, 0, 0]));
      var notified = 0;
      provider.addListener(() => notified++);
      provider.move(Direction.left);
      expect(provider.score, 4);
      expect(provider.board[0][0], 4);
      expect(countTiles(provider.board), 2);
      final (r, c) = provider.newTile!;
      expect(provider.board[r][c], anyOf(2, 4));
      expect(provider.mergedTiles, {(0, 0)});
      expect(provider.moveCount, 1);
      expect(notified, 1);
    });

    test('pontos acumulam entre jogadas', () {
      provider.debugSetBoard(withFirstRow([2, 2, 4, 4]));
      provider.move(Direction.left); // 4 + 8
      expect(provider.score, 12);
      provider.debugSetBoard(withFirstRow([16, 16, 0, 0]));
      provider.move(Direction.right); // 32
      expect(provider.score, 44);
    });

    for (final (direction, cell) in [
      (Direction.up, (0, 1)),
      (Direction.down, (3, 1)),
      (Direction.left, (1, 0)),
      (Direction.right, (1, 3)),
    ]) {
      test('move para ${direction.name}', () {
        provider.debugSetBoard([
          [0, 0, 0, 0],
          [0, 8, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]);
        provider.move(direction);
        final (r, c) = cell;
        expect(provider.board[r][c], 8);
        expect(provider.board[1][1], isNot(8));
      });
    }

    test('debugSetBoard copia o tabuleiro recebido', () {
      final board = withFirstRow([2, 2, 0, 0]);
      provider.debugSetBoard(board);
      provider.move(Direction.left);
      expect(board[0], [2, 2, 0, 0]);
    });

    group('vitória', () {
      test('formar 2048 vence', () {
        provider.debugSetBoard(withFirstRow([1024, 1024, 0, 0]));
        provider.move(Direction.left);
        expect(provider.phase, Game2048Phase.won);
        expect(provider.score, 2048);
      });

      test('jogadas são ignoradas enquanto o aviso aparece', () {
        provider.debugSetBoard(withFirstRow([1024, 1024, 0, 0]));
        provider.move(Direction.left);
        final before = provider.board;
        final moves = provider.moveCount;
        provider.move(Direction.right);
        expect(provider.board, before);
        expect(provider.moveCount, moves);
      });

      test('continuePlaying volta a jogar e não vence de novo', () {
        provider.debugSetBoard(withFirstRow([1024, 1024, 0, 0]));
        provider.move(Direction.left);
        provider.continuePlaying();
        expect(provider.phase, Game2048Phase.playing);

        // Outro 2048 no tabuleiro não mostra o aviso de novo.
        provider.debugSetBoard(withFirstRow([1024, 1024, 0, 0]));
        provider.move(Direction.left);
        expect(provider.phase, Game2048Phase.playing);

        // Nem chegar ao 4096.
        provider.debugSetBoard(withFirstRow([2048, 2048, 0, 0]));
        provider.move(Direction.left);
        expect(provider.phase, Game2048Phase.playing);
        expect(provider.board[0][0], 4096);
      });

      test('continuePlaying fora da vitória não faz nada', () {
        var notified = 0;
        provider.addListener(() => notified++);
        provider.continuePlaying();
        expect(provider.phase, Game2048Phase.playing);

        provider.debugSetBoard(lockedAfterRight);
        provider.move(Direction.right);
        expect(provider.phase, Game2048Phase.lost);
        notified = 0;
        provider.continuePlaying();
        expect(provider.phase, Game2048Phase.lost);
        expect(notified, 0);
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

      test('newGame depois de continuar permite vencer de novo', () {
        provider.debugSetBoard(withFirstRow([1024, 1024, 0, 0]));
        provider.move(Direction.left);
        provider.continuePlaying();
        provider.newGame();
        provider.debugSetBoard(withFirstRow([1024, 1024, 0, 0]));
        provider.move(Direction.left);
        expect(provider.phase, Game2048Phase.won);
      });
    });

    group('derrota', () {
      test('tabuleiro travado depois da jogada dá derrota', () {
        provider.debugSetBoard(lockedAfterRight);
        provider.move(Direction.right);
        expect(provider.phase, Game2048Phase.lost);
      });

      test('jogadas são ignoradas depois da derrota', () {
        provider.debugSetBoard(lockedAfterRight);
        provider.move(Direction.right);
        final before = provider.board;
        provider.move(Direction.left);
        expect(provider.board, before);
      });

      test('tabuleiro cheio com junção possível não é derrota', () {
        provider.debugSetBoard([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [8, 8, 4, 0],
        ]);
        provider.move(Direction.right);
        expect(provider.phase, Game2048Phase.playing);
      });
    });

    group('newGame', () {
      test('zera pontos, jogadas e fase e mantém o recorde', () {
        provider.debugSetBoard(withFirstRow([4, 4, 0, 0]));
        provider.move(Direction.left);
        var notified = 0;
        provider.addListener(() => notified++);
        provider.newGame();
        expect(provider.score, 0);
        expect(provider.best, 8);
        expect(provider.moveCount, 0);
        expect(provider.mergedTiles, isEmpty);
        expect(countTiles(provider.board), 2);
        expect(provider.phase, Game2048Phase.playing);
        expect(notified, 1);
      });

      test('funciona depois da derrota', () {
        provider.debugSetBoard(lockedAfterRight);
        provider.move(Direction.right);
        provider.newGame();
        expect(provider.phase, Game2048Phase.playing);
        expect(countTiles(provider.board), 2);
      });
    });

    group('recorde', () {
      test('carrega o recorde salvo', () async {
        store = MemoryHighScoreStore(100);
        var notified = 0;
        provider = Game2048Provider(store: store, random: Random(1))
          ..addListener(() => notified++);
        await Future<void>.delayed(Duration.zero);
        expect(provider.best, 100);
        expect(notified, 1);
      });

      test('recorde salvo 0 não avisa ninguém', () async {
        var notified = 0;
        provider = Game2048Provider(store: store, random: Random(1))
          ..addListener(() => notified++);
        await Future<void>.delayed(Duration.zero);
        expect(notified, 0);
      });

      test('sobe quando os pontos passam dele e é salvo', () async {
        store = MemoryHighScoreStore(100);
        provider = Game2048Provider(store: store, random: Random(1));
        await Future<void>.delayed(Duration.zero);

        provider.debugSetBoard(withFirstRow([64, 64, 0, 0]));
        provider.move(Direction.left);
        expect(provider.score, 128);
        expect(provider.best, 128);
        expect(store.value, 128);
      });

      test('só sobe: pontos abaixo do recorde não salvam nada', () async {
        store = MemoryHighScoreStore(500);
        provider = Game2048Provider(store: store, random: Random(1));
        await Future<void>.delayed(Duration.zero);

        provider.debugSetBoard(withFirstRow([4, 4, 0, 0]));
        provider.move(Direction.left);
        expect(provider.best, 500);
        expect(store.saves, 0);

        provider.newGame();
        expect(provider.best, 500);
        expect(store.value, 500);
      });

      test('persiste entre partidas e entre providers', () async {
        provider.debugSetBoard(withFirstRow([32, 32, 0, 0]));
        provider.move(Direction.left);
        provider.newGame();
        expect(provider.best, 64);

        final next = Game2048Provider(store: store, random: Random(2));
        await Future<void>.delayed(Duration.zero);
        expect(next.best, 64);
      });

      test('recorde que chega atrasado não sobrescreve um valor maior', () async {
        store = MemoryHighScoreStore()..pendingLoad = Completer<int>();
        provider = Game2048Provider(store: store, random: Random(1));
        provider.debugSetBoard(withFirstRow([4, 4, 0, 0]));
        provider.move(Direction.left);
        expect(provider.best, 8);

        store.pendingLoad!.complete(2);
        await Future<void>.delayed(Duration.zero);
        expect(provider.best, 8);
      });

      test('falha ao ler o recorde mantém 0 sem erro', () async {
        store = MemoryHighScoreStore(100)..failLoad = true;
        provider = Game2048Provider(store: store, random: Random(1));
        await Future<void>.delayed(Duration.zero);
        expect(provider.best, 0);
      });

      test('descartar o provider durante a leitura não avisa depois', () async {
        store = MemoryHighScoreStore()..pendingLoad = Completer<int>();
        provider = Game2048Provider(store: store, random: Random(1));
        provider.dispose();

        // Se avisasse depois do dispose, o ChangeNotifier lançaria erro.
        store.pendingLoad!.complete(999);
        await Future<void>.delayed(Duration.zero);
        expect(provider.best, 0);
      });
    });
  });
}
