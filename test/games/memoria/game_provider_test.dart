// test/games/memoria/game_provider_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/memoria/data/levels.dart';
import 'package:brincaki/games/memoria/models/game_state.dart';
import 'package:brincaki/games/memoria/providers/game_provider.dart';
import 'package:brincaki/widgets/player_setup.dart';

const _solo = PlayerSetupResult(mode: PlayMode.solo, player1: 'Ana', player2: '');
const _duo =
    PlayerSetupResult(mode: PlayMode.twoPlayers, player1: 'Ana', player2: 'Beto');

/// Ids das duas cartas de cada emoji ainda não encontrado.
List<(int, int)> pairsOf(MemoryProvider p) {
  final byEmoji = <String, List<int>>{};
  for (final c in p.cards) {
    if (!c.matched) byEmoji.putIfAbsent(c.emoji, () => []).add(c.id);
  }
  return [for (final ids in byEmoji.values) (ids[0], ids[1])];
}

/// Duas cartas de emojis diferentes, ainda não encontradas.
(int, int) mismatch(MemoryProvider p) {
  final pairs = pairsOf(p);
  return (pairs[0].$1, pairs[1].$1);
}

void findAll(MemoryProvider p) {
  for (final (a, b) in pairsOf(p)) {
    p.flip(a);
    p.flip(b);
  }
}

void main() {
  late MemoryProvider p;

  setUp(() => p = MemoryProvider(random: Random(5)));

  test('começa na configuração', () {
    expect(p.phase, MemoryPhase.setup);
    expect(p.cards, isEmpty);
  });

  test('cada nível solo tem rows×cols cartas com cada emoji 2 vezes', () {
    p.start(_solo);
    for (var level = 1; level <= kSoloLevels.length; level++) {
      final grid = kSoloLevels[level - 1];
      expect(p.level, level);
      expect(p.cards.length, grid.rows * grid.cols);
      final counts = <String, int>{};
      for (final c in p.cards) {
        counts[c.emoji] = (counts[c.emoji] ?? 0) + 1;
      }
      expect(counts.length, grid.pairs);
      expect(counts.values.every((n) => n == 2), isTrue);
      expect([for (var i = 0; i < p.cards.length; i++) p.cards[i].id],
          List.generate(p.cards.length, (i) => i));
      findAll(p);
      p.nextLevel();
    }
    expect(p.level, 5); // no último nível, joga o mesmo de novo
  });

  test('par encontrado fica virado e conta para o jogador da vez', () {
    p.start(_duo);
    final (a, b) = pairsOf(p).first;
    p.flip(a);
    p.flip(b);
    expect(p.cards[a].matched && p.cards[b].matched, isTrue);
    expect(p.pairs1, 1);
    expect(p.currentPlayer, 1); // acertou, joga de novo
    expect(p.moves, 1);
  });

  test('erro deixa as cartas à mostra, bloqueia toques e passa a vez', () {
    p.start(_duo);
    final (a, b) = mismatch(p);
    p.flip(a);
    p.flip(b);
    expect(p.waitingToHide, isTrue);

    final other = p.cards.firstWhere((c) => !c.faceUp).id;
    p.flip(other); // ignorado enquanto as erradas estão à mostra
    expect(p.cards[other].faceUp, isFalse);

    p.hideMismatched();
    expect(p.waitingToHide, isFalse);
    expect(p.cards[a].faceUp || p.cards[b].faceUp, isFalse);
    expect(p.currentPlayer, 2);
  });

  test('no solo, errar não troca de jogador', () {
    p.start(_solo);
    final (a, b) = mismatch(p);
    p.flip(a);
    p.flip(b);
    p.hideMismatched();
    expect(p.currentPlayer, 1);
    expect(p.moves, 1);
  });

  test('virar carta já virada ou encontrada não faz nada', () {
    p.start(_solo);
    final (a, b) = pairsOf(p).first;
    p.flip(a);
    p.flip(a);
    expect(p.moves, 0);
    p.flip(b);
    p.flip(a);
    expect(p.moves, 1);
    expect(p.waitingToHide, isFalse);
  });

  test('terminar em dois jogadores atualiza vitórias e empates', () {
    p.start(_duo);
    findAll(p); // o jogador 1 acha todos os pares
    expect(p.phase, MemoryPhase.finished);
    expect(p.winner, 1);
    expect(p.wins1, 1);

    p.playAgain();
    expect(p.phase, MemoryPhase.playing);
    expect(p.currentPlayer, 2); // quem começa alterna
    // Empate: cada um acha metade dos pares (o tamanho Médio tem 10).
    final pairs = pairsOf(p);
    for (var i = 0; i < pairs.length; i++) {
      if (i == pairs.length ~/ 2) {
        final (x, y) = mismatch(p);
        p.flip(x);
        p.flip(y);
        p.hideMismatched(); // passa a vez para o jogador 1
      }
      final (a, b) = pairs[i];
      p.flip(a);
      p.flip(b);
    }
    expect(p.pairs1, p.pairs2);
    expect(p.winner, isNull);
    expect(p.draws, 1);
    expect(p.wins1, 1);
  });

  test('setDuoSize troca a grade só antes da primeira jogada', () {
    p.start(_duo);
    expect(p.duoSize, 'Média');
    p.setDuoSize('Grande');
    expect(p.cards.length, kDuoSizes['Grande']!.rows * kDuoSizes['Grande']!.cols);
    final (a, b) = mismatch(p);
    p.flip(a);
    p.flip(b);
    p.hideMismatched();
    p.setDuoSize('Pequena');
    expect(p.duoSize, 'Grande');
  });

  test('setDuoSize não troca a grade com uma carta já virada', () {
    p.start(_duo);
    p.flip(0);
    p.setDuoSize('Grande');
    expect(p.duoSize, 'Média');
    expect(p.cards[0].faceUp, isTrue);
  });

  test('exitToSetup zera o placar', () {
    p.start(_duo);
    findAll(p);
    p.exitToSetup();
    expect(p.phase, MemoryPhase.setup);
    expect(p.wins1 + p.wins2 + p.draws, 0);
  });

  test('nextLevel e playAgain só funcionam no modo e na fase certos', () {
    p.start(_solo);
    p.nextLevel();
    expect(p.level, 1);
    findAll(p);
    p.playAgain();
    expect(p.phase, MemoryPhase.finished);
  });

  group('nível inicial', () {
    for (var index = 0; index < 5; index++) {
      test('levelIndex $index começa no nível ${index + 1}', () {
        p.start(PlayerSetupResult(
            mode: PlayMode.solo, player1: 'Ana', player2: '', levelIndex: index));
        final grid = kSoloLevels[index];
        expect(p.level, index + 1);
        expect(p.grid, same(grid));
        expect(p.cards, hasLength(grid.rows * grid.cols));
        expect(p.isLastLevel, index == 4);
      });
    }

    test('sem levelIndex ou fora da lista começa no nível 1', () {
      for (final index in [null, -1, 5, 99]) {
        p.start(PlayerSetupResult(
            mode: PlayMode.solo, player1: 'Ana', player2: '', levelIndex: index));
        expect(p.level, 1, reason: 'levelIndex $index');
      }
    });

    test('nível escolhido avança normalmente', () {
      p.start(const PlayerSetupResult(
          mode: PlayMode.solo, player1: 'Ana', player2: '', levelIndex: 2));
      findAll(p);
      p.nextLevel();
      expect(p.level, 4);
      expect(p.phase, MemoryPhase.playing);
      expect(p.moves, 0);
    });
  });

  test('último nível: jogar de novo dá uma grade nova do mesmo nível', () {
    p.start(const PlayerSetupResult(
        mode: PlayMode.solo, player1: 'Ana', player2: '', levelIndex: 4));
    expect(p.isLastLevel, isTrue);
    findAll(p);
    expect(p.phase, MemoryPhase.finished);
    final deal = p.dealId;
    p.nextLevel();
    expect(p.level, 5);
    expect(p.phase, MemoryPhase.playing);
    expect(p.dealId, deal + 1);
    expect(p.cards.every((c) => !c.faceUp && !c.matched), isTrue);
    expect(p.moves, 0);
  });

  test('em dois jogadores a grade é a do tamanho, não a do nível', () {
    p.start(_duo);
    expect(p.grid, same(kDuoSizes['Média']));
    expect(p.cards, hasLength(20));
    expect(p.mode, PlayMode.twoPlayers);
    expect((p.name1, p.name2), ('Ana', 'Beto'));
  });

  test('cards não pode ser alterada de fora', () {
    p.start(_solo);
    expect(() => p.cards.add(const MemoryCard(id: 99, emoji: '🐶')),
        throwsUnsupportedError);
  });

  test('virar carta antes de começar ou com id inválido não faz nada', () {
    p.flip(0);
    expect(p.cards, isEmpty);
    p.start(_solo);
    var notified = 0;
    p.addListener(() => notified++);
    p.flip(-1);
    p.flip(p.cards.length);
    expect(notified, 0);
    expect(p.untouched, isTrue);
  });

  test('virar a mesma carta duas vezes não conta jogada nem fecha par', () {
    p.start(_duo);
    final id = pairsOf(p).first.$1;
    p.flip(id);
    expect(p.untouched, isFalse);
    p.flip(id);
    expect(p.cards[id].faceUp, isTrue);
    expect(p.cards[id].matched, isFalse);
    expect(p.moves, 0);
    expect(p.waitingToHide, isFalse);
    expect(p.currentPlayer, 1);
  });

  test('terceira carta durante waitingToHide é ignorada, mesmo sendo o par', () {
    p.start(_solo);
    final pairs = pairsOf(p);
    p.flip(pairs[0].$1);
    p.flip(pairs[1].$1);
    expect(p.waitingToHide, isTrue);
    p.flip(pairs[0].$2); // seria o par da primeira
    expect(p.cards[pairs[0].$2].faceUp, isFalse);
    expect(p.cards.where((c) => c.faceUp), hasLength(2));
    expect(p.moves, 1);
  });

  test('hideMismatched sem cartas erradas não faz nada', () {
    p.start(_duo);
    var notified = 0;
    p.addListener(() => notified++);
    p.hideMismatched();
    expect(notified, 0);
    expect(p.currentPlayer, 1);
  });

  test('par certo mantém a vez; par errado passa, e volta no próximo erro', () {
    p.start(_duo);
    var pairs = pairsOf(p);
    p.flip(pairs[0].$1);
    p.flip(pairs[0].$2);
    expect(p.currentPlayer, 1);
    expect(p.pairs1, 1);

    var (x, y) = mismatch(p);
    p.flip(x);
    p.flip(y);
    p.hideMismatched();
    expect(p.currentPlayer, 2);

    pairs = pairsOf(p);
    p.flip(pairs[0].$1);
    p.flip(pairs[0].$2);
    expect(p.currentPlayer, 2, reason: 'acertou, joga de novo');
    expect(p.pairs2, 1);
    expect(p.pairs1, 1);

    (x, y) = mismatch(p);
    p.flip(x);
    p.flip(y);
    p.hideMismatched();
    expect(p.currentPlayer, 1);
    expect(p.moves, 4);
  });

  test('vitória do jogador 2', () {
    p.start(_duo);
    final (x, y) = mismatch(p);
    p.flip(x);
    p.flip(y);
    p.hideMismatched();
    expect(p.winner, isNull, reason: 'ainda jogando');
    findAll(p);
    expect(p.phase, MemoryPhase.finished);
    expect(p.pairs2, 10);
    expect(p.winner, 2);
    expect(p.wins2, 1);
    expect(p.wins1, 0);
    expect(p.draws, 0);
  });

  test('no solo não há vencedor nem placar de vitórias', () {
    p.start(_solo);
    findAll(p);
    expect(p.phase, MemoryPhase.finished);
    expect(p.winner, isNull);
    expect(p.wins1 + p.wins2 + p.draws, 0);
    expect(p.pairs1, 6);
    expect(p.moves, 6);
  });

  test('depois do fim, virar cartas não faz nada', () {
    p.start(_solo);
    findAll(p);
    final moves = p.moves;
    p.flip(0);
    expect(p.moves, moves);
  });

  test('jogar de novo mantém o tamanho e zera os pares da partida', () {
    p.start(_duo);
    p.setDuoSize('Pequena');
    findAll(p);
    p.playAgain();
    expect(p.duoSize, 'Pequena');
    expect(p.cards, hasLength(12));
    expect((p.pairs1, p.pairs2, p.moves), (0, 0, 0));
    expect(p.untouched, isTrue);
    expect(p.wins1, 1);
  });

  test('playAgain durante a partida não faz nada', () {
    p.start(_duo);
    final deal = p.dealId;
    p.playAgain();
    expect(p.dealId, deal);
  });

  test('start de novo volta ao tamanho Média e ao jogador 1', () {
    p.start(_duo);
    p.setDuoSize('Grande');
    findAll(p);
    p.playAgain();
    expect(p.currentPlayer, 2);
    p.exitToSetup();
    p.start(_duo);
    expect(p.duoSize, 'Média');
    expect(p.currentPlayer, 1);
  });

  group('setDuoSize', () {
    test('troca e dá cartas novas antes da primeira jogada', () {
      p.start(_duo);
      final deal = p.dealId;
      for (final size in kDuoSizes.keys) {
        p.setDuoSize(size);
        final grid = kDuoSizes[size]!;
        expect(p.duoSize, size);
        expect(p.grid, same(grid));
        expect(p.cards, hasLength(grid.rows * grid.cols));
      }
      expect(p.dealId, deal + 3);
    });

    test('ignora tamanho que não existe', () {
      p.start(_duo);
      p.setDuoSize('Gigante');
      expect(p.duoSize, 'Média');
    });

    test('não funciona no solo, na configuração nem depois do fim', () {
      p.setDuoSize('Grande');
      expect(p.duoSize, 'Média');
      p.start(_solo);
      p.setDuoSize('Grande');
      expect(p.duoSize, 'Média');
      expect(p.cards, hasLength(12));
      p.start(_duo);
      findAll(p);
      p.setDuoSize('Grande');
      expect(p.duoSize, 'Média');
      expect(p.phase, MemoryPhase.finished);
    });
  });

  test('exitToSetup com cartas à mostra limpa tudo', () {
    p.start(_duo);
    final (x, y) = mismatch(p);
    p.flip(x);
    p.flip(y);
    p.exitToSetup();
    expect(p.waitingToHide, isFalse);
    expect(p.cards, isEmpty);
    p.hideMismatched(); // nada para esconder
    expect(p.phase, MemoryPhase.setup);
    p.nextLevel();
    expect(p.phase, MemoryPhase.setup);
  });

  test('dispose com cartas para esconder não dá erro', () {
    final q = MemoryProvider(random: Random(1))..start(_solo);
    final pairs = pairsOf(q);
    q.flip(pairs[0].$1);
    q.flip(pairs[1].$1);
    expect(q.waitingToHide, isTrue);
    q.dispose();
  });

  test('sem Random injetado também embaralha', () {
    final q = MemoryProvider()..start(_solo);
    expect(q.cards, hasLength(12));
    q.dispose();
  });

  test('a mesma semente dá a mesma grade', () {
    final a = MemoryProvider(random: Random(9))..start(_solo);
    final b = MemoryProvider(random: Random(9))..start(_solo);
    expect([for (final c in a.cards) c.emoji], [for (final c in b.cards) c.emoji]);
  });
}
