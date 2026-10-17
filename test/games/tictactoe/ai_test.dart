// test/games/tictactoe/ai_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/tictactoe/logic/ai.dart';
import 'package:brincaki/games/tictactoe/logic/board.dart';

/// Monta um tabuleiro a partir de 3 strings: '.' vazio, 'x' = 1, 'o' = 2.
List<List<int>> parse(List<String> rows) => [
  for (final row in rows) [for (final ch in row.split('')) ch == 'x' ? 1 : (ch == 'o' ? 2 : 0)],
];

/// Todas as posições que aparecem num jogo de verdade (❌ começa) e ainda
/// não acabaram, com quem joga agora.
List<(List<List<int>>, int)> reachablePositions() {
  final seen = <String>{};
  final result = <(List<List<int>>, int)>[];
  void visit(List<List<int>> board, int player) {
    if (!seen.add('$board')) return;
    if (winningLine(board) != null || isFull(board)) return;
    result.add((board, player));
    for (final (r, c) in freeCells(board)) {
      visit(place(board, r, c, player), 3 - player);
    }
  }

  visit(emptyBoard(), 1);
  return result;
}

const _center = (1, 1);
const _corners = [(0, 0), (0, 2), (2, 0), (2, 2)];

void main() {
  final positions = reachablePositions();

  test('existem 4520 posições em andamento num jogo da velha', () {
    // 5478 posições válidas menos as 958 terminais.
    expect(positions, hasLength(4520));
  });

  group('qualquer nível', () {
    test('tabuleiro cheio lança StateError', () {
      final full = parse(['xox', 'xoo', 'oxx']);
      for (final level in AiLevel.values) {
        expect(() => chooseMove(full, 2, level, Random(1)), throwsStateError);
      }
    });

    test('partida já vencida lança StateError', () {
      final won = parse(['xxx', 'oo.', '...']);
      for (final level in AiLevel.values) {
        expect(() => chooseMove(won, 2, level, Random(1)), throwsStateError);
      }
    });

    test('sempre escolhe uma casa livre em todas as posições', () {
      for (final level in AiLevel.values) {
        for (final (board, player) in positions) {
          final move = chooseMove(board, player, level, Random(7));
          expect(freeCells(board), contains(move), reason: '$level em $board');
        }
      }
    });

    test('com uma casa livre só, joga nela', () {
      final board = parse(['xox', 'xoo', 'ox.']);
      for (final level in AiLevel.values) {
        expect(chooseMove(board, 1, level, Random(3)), (2, 2));
      }
    });

    test('não altera o tabuleiro recebido', () {
      final board = parse(['x..', '.o.', '...']);
      final copy = board.map((r) => List<int>.from(r)).toList();
      for (final level in AiLevel.values) {
        chooseMove(board, 1, level, Random(5));
      }
      expect(board, copy);
    });
  });

  group('winningMoves', () {
    test('acha todas as casas que dão vitória', () {
      final board = parse(['xx.', 'x..', 'oo.']);
      expect(winningMoves(board, 1), unorderedEquals([(0, 2)]));
      expect(winningMoves(board, 2), [(2, 2)]);
    });

    test('vazio quando ninguém ameaça', () {
      expect(winningMoves(emptyBoard(), 1), isEmpty);
    });

    test('vários jeitos de vencer', () {
      final board = parse(['x.x', '...', 'x..']);
      expect(winningMoves(board, 1), unorderedEquals([(0, 1), (1, 0), (1, 1)]));
    });
  });

  group('fácil', () {
    test('com Random semeado, a escolha se repete', () {
      final board = parse(['x..', '.o.', '...']);
      final a = chooseMove(board, 1, AiLevel.easy, Random(42));
      final b = chooseMove(board, 1, AiLevel.easy, Random(42));
      expect(a, b);
    });

    test('no tabuleiro vazio pode jogar em qualquer uma das 9 casas', () {
      final moves = {
        for (var seed = 0; seed < 200; seed++)
          chooseMove(emptyBoard(), 1, AiLevel.easy, Random(seed)),
      };
      expect(moves, hasLength(9));
    });

    test('pega a vitória imediata só parte das vezes', () {
      final board = parse(['oo.', 'xx.', 'x..']);
      var took = 0;
      for (var seed = 0; seed < 400; seed++) {
        if (chooseMove(board, 2, AiLevel.easy, Random(seed)) == (0, 2)) took++;
      }
      // Metade pega na hora; a outra metade sorteia e às vezes acerta também.
      expect(took, greaterThan(400 * 0.45));
      expect(took, lessThan(400 * 0.8));
    });

    test('às vezes não bloqueia a vitória do adversário', () {
      final board = parse(['xx.', '.o.', '...']);
      final blocked = [
        for (var seed = 0; seed < 100; seed++)
          chooseMove(board, 2, AiLevel.easy, Random(seed)) == (0, 2),
      ];
      expect(blocked, contains(false));
    });
  });

  group('médio', () {
    test('sempre vence quando pode e bloqueia quando precisa (todas as posições)', () {
      for (final (board, me) in positions) {
        final wins = winningMoves(board, me);
        final blocks = winningMoves(board, 3 - me);
        for (var seed = 0; seed < 3; seed++) {
          final move = chooseMove(board, me, AiLevel.medium, Random(seed));
          if (wins.isNotEmpty) {
            expect(wins, contains(move), reason: 'devia vencer em $board');
          } else if (blocks.isNotEmpty) {
            expect(blocks, contains(move), reason: 'devia bloquear em $board');
          }
        }
      }
    });

    test('sem ameaças: centro, depois cantos, depois lados (todas as posições)', () {
      for (final (board, me) in positions) {
        if (winningMoves(board, me).isNotEmpty) continue;
        if (winningMoves(board, 3 - me).isNotEmpty) continue;
        final free = freeCells(board);
        final move = chooseMove(board, me, AiLevel.medium, Random(11));
        if (free.contains(_center)) {
          expect(move, _center);
        } else if (free.any(_corners.contains)) {
          expect(_corners, contains(move));
        } else {
          expect(_corners, isNot(contains(move)));
        }
      }
    });

    test('vencer vem antes de bloquear', () {
      final board = parse(['oo.', 'xx.', 'x..']);
      expect(chooseMove(board, 2, AiLevel.medium, Random(0)), (0, 2));
    });

    test('sorteia entre os cantos livres', () {
      final board = parse(['...', '.x.', '...']);
      final moves = {
        for (var seed = 0; seed < 100; seed++) chooseMove(board, 2, AiLevel.medium, Random(seed)),
      };
      expect(moves, unorderedEquals(_corners));
    });

    test('sorteia entre os lados quando só sobram eles', () {
      // Ninguém ameaça e só os lados (0,1) e (2,1) estão livres.
      final board = parse(['o.x', 'xxo', 'o.x']);
      expect(winningMoves(board, 1), isEmpty);
      expect(winningMoves(board, 2), isEmpty);
      final moves = {
        for (var seed = 0; seed < 50; seed++) chooseMove(board, 2, AiLevel.medium, Random(seed)),
      };
      expect(moves, unorderedEquals([(0, 1), (2, 1)]));
    });
  });

  group('difícil', () {
    /// Joga contra todas as respostas possíveis do adversário. Devolve
    /// quantas partidas terminaram, e falha se o computador perder alguma.
    int playAll(List<List<int>> board, int ai, int toMove, int seed) {
      if (winningLine(board) != null) {
        expect(hasLine(board, 3 - ai), isFalse, reason: 'perdeu em $board');
        return 1;
      }
      if (isFull(board)) return 1;
      if (toMove == ai) {
        final (r, c) = chooseMove(board, ai, AiLevel.hard, Random(seed));
        return playAll(place(board, r, c, ai), ai, 3 - ai, seed);
      }
      var games = 0;
      for (final (r, c) in freeCells(board)) {
        games += playAll(place(board, r, c, toMove), ai, ai, seed);
      }
      return games;
    }

    for (var seed = 0; seed < 4; seed++) {
      test('nunca perde começando (semente $seed)', () {
        expect(playAll(emptyBoard(), 1, 1, seed), greaterThan(0));
      });

      test('nunca perde com o adversário começando (semente $seed)', () {
        expect(playAll(emptyBoard(), 2, 1, seed), greaterThan(8));
      });
    }

    test('nunca perde a partir de qualquer posição em que ainda dá para empatar', () {
      // Para cada posição em que é a vez do computador, se o resultado
      // perfeito não é derrota, ele não perde contra nenhuma resposta.
      var checked = 0;
      for (final (board, me) in positions) {
        if (freeCells(board).length > 6) continue; // as do começo já foram
        if (_perfectValue(board, me) < 0) continue;
        playAll(board, me, me, 0);
        checked++;
      }
      expect(checked, greaterThan(1000));
    });

    test('vence na hora quando pode', () {
      for (final (board, me) in positions) {
        final wins = winningMoves(board, me);
        if (wins.isEmpty) continue;
        expect(wins, contains(chooseMove(board, me, AiLevel.hard, Random(0))));
      }
    });

    test('bloqueia a vitória do adversário', () {
      final board = parse(['xx.', '.o.', '...']);
      expect(chooseMove(board, 2, AiLevel.hard, Random(0)), (0, 2));
    });

    test('responde ao canto com o centro (única defesa)', () {
      for (final corner in _corners) {
        final board = place(emptyBoard(), corner.$1, corner.$2, 1);
        for (var seed = 0; seed < 10; seed++) {
          expect(chooseMove(board, 2, AiLevel.hard, Random(seed)), _center);
        }
      }
    });

    test('aproveita o erro do adversário e cria um garfo', () {
      // ❌ no canto, ⭕ no lado errado: ❌ tem vitória forçada.
      final board = parse(['x..', '.o.', '...']);
      expect(_perfectValue(board, 1), 0);
      final bad = parse(['xo.', '...', '...']);
      expect(_perfectValue(bad, 1), greaterThan(0));
      var b = bad;
      // Contra o médio o difícil deve sempre vencer a partir daqui.
      var player = 1;
      while (winningLine(b) == null && !isFull(b)) {
        final level = player == 1 ? AiLevel.hard : AiLevel.medium;
        final (r, c) = chooseMove(b, player, level, Random(3));
        b = place(b, r, c, player);
        player = 3 - player;
      }
      expect(hasLine(b, 1), isTrue);
    });

    test('sorteia entre jogadas igualmente boas no tabuleiro vazio', () {
      final moves = {
        for (var seed = 0; seed < 100; seed++)
          chooseMove(emptyBoard(), 1, AiLevel.hard, Random(seed)),
      };
      // Todas as 9 casas empatam com jogo perfeito.
      expect(moves, hasLength(9));
    });

    test('difícil contra difícil sempre empata', () {
      for (var seed = 0; seed < 20; seed++) {
        final random = Random(seed);
        var b = emptyBoard();
        var player = 1;
        while (winningLine(b) == null && !isFull(b)) {
          final (r, c) = chooseMove(b, player, AiLevel.hard, random);
          b = place(b, r, c, player);
          player = 3 - player;
        }
        expect(winningLine(b), isNull, reason: 'semente $seed');
      }
    });
  });
}

/// Valor da posição com jogo perfeito para quem joga agora (>0 vence,
/// 0 empata, <0 perde). Implementação independente da IA, só para os testes.
int _perfectValue(List<List<int>> board, int player) {
  if (hasLine(board, 3 - player)) return -1;
  if (isFull(board)) return 0;
  var best = -2;
  for (final (r, c) in freeCells(board)) {
    final v = -_perfectValue(place(board, r, c, player), 3 - player);
    if (v > best) best = v;
  }
  return best;
}
