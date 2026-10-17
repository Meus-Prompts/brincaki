// test/games/tictactoe/game_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/tictactoe/logic/ai.dart';
import 'package:brincaki/games/tictactoe/logic/board.dart';
import 'package:brincaki/games/tictactoe/models/game_state.dart';
import 'package:brincaki/games/tictactoe/providers/game_provider.dart';
import 'package:brincaki/games/tictactoe/screens/game_screen.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/player_setup.dart';
import 'package:brincaki/widgets/result_panel.dart';

const _think = Duration(milliseconds: 300);
const _menu = 'menu de mentira';

/// Computador previsível: primeira casa livre.
Future<(int, int)> firstFree(List<List<int>> board, int me, AiLevel level) async =>
    freeCells(board).first;

/// Abre o jogo como o menu faz (GameShell + provider) a partir de uma tela
/// de "menu" e devolve o provider criado.
Future<TicTacToeProvider Function()> pumpGame(
  WidgetTester tester, {
  Size size = const Size(360, 740),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  TicTacToeProvider? provider;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameShell(
                    theme: kVelhaPalette.theme,
                    wrapProvider: (child) => ChangeNotifierProvider(
                      create: (_) =>
                          provider = TicTacToeProvider(thinkTime: _think, aiRunner: firstFree),
                      child: child,
                    ),
                    home: (_) => const TicTacToeScreen(),
                  ),
                ),
              ),
              child: const Text(_menu),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text(_menu));
  await tester.pumpAndSettle();
  return () => provider!;
}

Future<void> startTwoPlayers(WidgetTester tester, {String? name1, String? name2}) async {
  await tester.tap(find.text('Dois jogadores'));
  await tester.pumpAndSettle();
  if (name1 != null) await tester.enterText(find.byKey(const Key('name1')), name1);
  if (name2 != null) await tester.enterText(find.byKey(const Key('name2')), name2);
  await tester.ensureVisible(find.text('Jogar!'));
  await tester.tap(find.text('Jogar!'));
  await tester.pumpAndSettle();
}

Future<void> startSolo(WidgetTester tester, String level) async {
  await tester.ensureVisible(find.text(level));
  await tester.tap(find.text(level));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Jogar!'));
  await tester.tap(find.text('Jogar!'));
  await tester.pumpAndSettle();
}

Future<void> tapCell(WidgetTester tester, int row, int col) async {
  await tester.tap(find.byKey(Key('cell-$row-$col')));
  await tester.pump();
}

/// Toca nas casas e espera o computador responder (se for o caso).
Future<void> playCells(WidgetTester tester, List<(int, int)> cells) async {
  for (final (r, c) in cells) {
    await tapCell(tester, r, c);
    await tester.pump(_think);
    await tester.pumpAndSettle();
  }
}

Color cellColor(WidgetTester tester, int row, int col) {
  final box = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byKey(Key('cell-$row-$col')),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (box.decoration! as BoxDecoration).color!;
}

const _winColor = Color(0xFFBBF7D0);

void main() {
  group('tela de início', () {
    testWidgets('mostra o título, os modos e os níveis', (tester) async {
      await pumpGame(tester);
      // Na AppBar e no cabeçalho do setup.
      expect(find.text('Jogo da Velha'), findsNWidgets(2));
      expect(find.text('❌⭕'), findsOneWidget);
      expect(find.text('Contra o computador'), findsOneWidget);
      expect(find.text('Dois jogadores'), findsOneWidget);
      for (final level in ['Fácil', 'Médio', 'Difícil']) {
        expect(find.text(level), findsOneWidget);
      }
      expect(find.text('Jogar!'), findsOneWidget);
      expect(find.byType(ResultPanel), findsNothing);
    });

    testWidgets('em dois jogadores pede os dois nomes e esconde os níveis', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.text('Dois jogadores'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('name2')), findsOneWidget);
      expect(find.text('Médio'), findsNothing);
    });
  });

  group('dois jogadores', () {
    testWidgets('fluxo completo: vez, vitória, jogar de novo, empate e trocar jogadores', (
      tester,
    ) async {
      final provider = await pumpGame(tester);
      await startTwoPlayers(tester, name1: 'Ana', name2: 'Beto');
      final p = provider();
      expect(p.phase, GamePhase.playing);
      expect(p.mode, PlayMode.twoPlayers);
      // Sem nível no título em dois jogadores.
      expect(find.text('Jogo da Velha'), findsOneWidget);
      expect(find.text('Vez de ❌ Ana'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Beto'), findsOneWidget);
      expect(find.text('Empates'), findsOneWidget);

      await tapCell(tester, 0, 0);
      expect(p.board[0][0], 1);
      expect(find.text('Vez de ⭕ Beto'), findsOneWidget);

      // Casa ocupada: nada muda.
      await tapCell(tester, 0, 0);
      expect(p.board[0][0], 1);
      expect(find.text('Vez de ⭕ Beto'), findsOneWidget);

      await playCells(tester, const [(1, 0), (0, 1), (1, 1), (0, 2)]);
      expect(p.winner, 1);
      expect(find.text('🏆'), findsOneWidget);
      expect(find.text('Ana venceu!'), findsOneWidget);
      expect(find.textContaining('Vez de'), findsNothing);
      for (final (r, c) in const [(0, 0), (0, 1), (0, 2)]) {
        expect(cellColor(tester, r, c), _winColor);
      }
      expect(cellColor(tester, 1, 0), Colors.white);
      expect(p.wins1, 1);

      // Depois do fim, tocar no tabuleiro não faz nada.
      await tapCell(tester, 2, 2);
      expect(p.board[2][2], 0);

      await tester.tap(find.text('Jogar de novo'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultPanel), findsNothing);
      expect(find.text('Vez de ⭕ Beto'), findsOneWidget, reason: 'quem começa alterna');
      expect(p.board, emptyBoard());
      expect(p.wins1, 1);

      // Termina em x o x / x o o / o x o, começando pelo ⭕.
      await playCells(tester, const [
        (0, 1),
        (0, 0),
        (1, 1),
        (0, 2),
        (1, 2),
        (1, 0),
        (2, 0),
        (2, 1),
        (2, 2),
      ]);
      expect(p.phase, GamePhase.finished);
      expect(p.winner, isNull, reason: 'deveria ser empate em ${p.board}');
      expect(find.text('🤝'), findsWidgets);
      expect(find.text('Empate!'), findsOneWidget);
      expect(p.draws, 1);

      await tester.tap(find.text('Trocar jogadores'));
      await tester.pumpAndSettle();
      expect(p.phase, GamePhase.setup);
      expect(find.text('Jogar!'), findsOneWidget);
      expect(p.wins1 + p.wins2 + p.draws, 0);
    });

    testWidgets('sem nomes, usa Jogador 1 e Jogador 2', (tester) async {
      final provider = await pumpGame(tester);
      await startTwoPlayers(tester);
      expect(find.text('Vez de ❌ Jogador 1'), findsOneWidget);
      await playCells(tester, const [(0, 0), (0, 1), (1, 0), (1, 1), (2, 2), (2, 1)]);
      expect(provider().winner, 2);
      expect(find.text('Jogador 2 venceu!'), findsOneWidget);
    });
  });

  group('contra o computador', () {
    for (final (index, level) in const ['Fácil', 'Médio', 'Difícil'].indexed) {
      testWidgets('o título mostra o nível $level', (tester) async {
        final provider = await pumpGame(tester);
        await startSolo(tester, level);
        expect(find.text('Jogo da Velha • $level'), findsOneWidget);
        expect(provider().aiLevel, AiLevel.values[index]);
      });
    }

    testWidgets('fluxo completo: pensando, derrota, computador começa, vitória e trocar', (
      tester,
    ) async {
      final provider = await pumpGame(tester);
      await startSolo(tester, 'Médio');
      final p = provider();
      expect(p.mode, PlayMode.solo);
      expect(find.text('Vez de ❌ Jogador 1'), findsOneWidget);
      expect(find.text('Computador'), findsOneWidget);

      await tapCell(tester, 2, 0);
      expect(find.text('🤖 Pensando...'), findsOneWidget);
      // Toque durante "Pensando..." é ignorado.
      await tapCell(tester, 2, 2);
      expect(p.board[2][2], 0);
      await tester.pump(_think);
      await tester.pumpAndSettle();
      expect(p.board[0][0], TicTacToeProvider.computer);
      expect(find.text('Vez de ❌ Jogador 1'), findsOneWidget);

      // O computador (primeira livre) completa a linha de cima.
      await playCells(tester, const [(1, 1), (2, 2)]);
      expect(p.winner, TicTacToeProvider.computer);
      expect(find.text('🤖'), findsOneWidget);
      expect(find.text('O computador venceu!'), findsOneWidget);
      expect(find.text('Jogo da Velha • Médio'), findsOneWidget);

      // Jogar de novo: agora o computador começa sozinho.
      await tester.tap(find.text('Jogar de novo'));
      await tester.pump();
      expect(find.text('🤖 Pensando...'), findsOneWidget);
      await tester.pump(_think);
      await tester.pumpAndSettle();
      expect(p.board[0][0], TicTacToeProvider.computer);
      expect(find.text('Vez de ❌ Jogador 1'), findsOneWidget);

      // Humano bloqueia a linha de cima e fecha a diagonal.
      await playCells(tester, const [(1, 1), (0, 2), (2, 0)]);
      expect(p.winner, 1);
      expect(find.text('Jogador 1 venceu!'), findsOneWidget);
      expect(p.wins1, 1);
      expect(p.wins2, 1);

      await tester.tap(find.text('Trocar jogadores'));
      await tester.pumpAndSettle();
      expect(p.phase, GamePhase.setup);
      expect(find.text('Jogo da Velha'), findsNWidgets(2), reason: 'sem nível no setup');
    });
  });

  group('voltar', () {
    testWidgets('a seta no setup volta ao menu', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text(_menu), findsOneWidget);
      expect(find.byType(TicTacToeScreen), findsNothing);
    });

    testWidgets('a seta no meio da partida volta ao menu', (tester) async {
      await pumpGame(tester);
      await startTwoPlayers(tester);
      await tapCell(tester, 1, 1);
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text(_menu), findsOneWidget);
    });

    testWidgets('sair enquanto o computador pensa não dá erro', (tester) async {
      await pumpGame(tester);
      await startSolo(tester, 'Difícil');
      await tapCell(tester, 1, 1);
      expect(find.text('🤖 Pensando...'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      await tester.pump(_think * 2);
      expect(find.text(_menu), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('o resultado também tem a seta de voltar', (tester) async {
      await pumpGame(tester);
      await startTwoPlayers(tester);
      await playCells(tester, const [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)]);
      expect(find.byType(ResultPanel), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text(_menu), findsOneWidget);
    });
  });

  group('telas pequenas', () {
    for (final size in const [Size(360, 740), Size(320, 568)]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$label: setup, partida e resultado sem overflow', (tester) async {
        await pumpGame(tester, size: size);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Dois jogadores'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Contra o computador'));
        await tester.pumpAndSettle();
        await startSolo(tester, 'Difícil');
        expect(tester.takeException(), isNull);

        // As 9 casas cabem na tela e são quadradas o bastante para tocar.
        for (var r = 0; r < 3; r++) {
          for (var c = 0; c < 3; c++) {
            final rect = tester.getRect(find.byKey(Key('cell-$r-$c')));
            expect(rect.width, greaterThan(40));
            expect(rect.height, greaterThan(40));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
            expect(rect.right, lessThanOrEqualTo(size.width));
          }
        }

        await playCells(tester, const [(2, 0), (1, 1), (2, 2)]);
        expect(find.byType(ResultPanel), findsOneWidget);
        expect(tester.takeException(), isNull);
        final panel = tester.getRect(find.byType(ResultPanel));
        expect(panel.bottom, lessThanOrEqualTo(size.height));
        final board = tester.getRect(find.byKey(const Key('cell-2-2')));
        expect(
          board.bottom,
          lessThanOrEqualTo(panel.top),
          reason: 'o painel não cobre o tabuleiro',
        );
        await tester.tap(find.text('Trocar jogadores'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
