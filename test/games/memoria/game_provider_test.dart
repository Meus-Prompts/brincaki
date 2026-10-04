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
    expect(p.level, 1); // depois do nível 5 volta ao 1
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
}
