// test/games/lig4/game_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/lig4/logic/ai.dart';
import 'package:brincaki/games/lig4/logic/board.dart';
import 'package:brincaki/games/lig4/providers/game_provider.dart';
import 'package:brincaki/games/lig4/screens/game_screen.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_scaffold.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/result_panel.dart';

/// Computador previsível: primeira coluna livre.
Future<int> firstFree(List<List<int>> board, int me, AiLevel level) async =>
    validColumns(board).first;

/// Abre o Lig 4 a partir de um "menu" de mentira, como no app.
Future<Lig4Provider> pumpScreen(
  WidgetTester tester, {
  Size size = const Size(360, 740),
  Duration thinkTime = Duration.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = Lig4Provider(thinkTime: thinkTime, aiRunner: firstFree);
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameShell(
                  theme: kLig4Palette.theme,
                  wrapProvider: (child) =>
                      ChangeNotifierProvider.value(value: provider, child: child),
                  home: (_) => const Lig4Screen(),
                ),
              ),
            ),
            child: const Text('menu'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('menu'));
  await tester.pumpAndSettle();
  return provider;
}

Future<void> startDuo(WidgetTester tester, {String? name1, String? name2}) async {
  await tester.tap(find.text('Dois jogadores'));
  await tester.pump();
  if (name1 != null) await tester.enterText(find.byKey(const Key('name1')), name1);
  if (name2 != null) await tester.enterText(find.byKey(const Key('name2')), name2);
  await tester.tap(find.text('Jogar!'));
  await tester.pumpAndSettle();
}

Future<void> startSolo(WidgetTester tester, {String level = 'Médio'}) async {
  await tester.tap(find.text(level));
  await tester.pump();
  await tester.tap(find.text('Jogar!'));
  await tester.pumpAndSettle();
}

Future<void> playColumns(WidgetTester tester, List<int> cols) async {
  for (final col in cols) {
    await tester.tap(find.byKey(Key('col-$col')));
    await tester.pumpAndSettle();
  }
}

/// Ordem conferida: enche as 42 casas sem ninguém alinhar 4.
const _drawOrder = [0, 1, 0, 1, 0, 1, 2, 3, 2, 3, 2, 3, 1, 0, 1, 0, 1, 0,
                    3, 2, 3, 2, 3, 2, 4, 5, 4, 5, 4, 5, 6, 4, 5, 6, 6, 4,
                    5, 6, 6, 4, 5, 6];

void main() {
  testWidgets('tela de início usa o GameScaffold com a paleta do Lig 4', (tester) async {
    await pumpScreen(tester);
    final scaffold = tester.widget<GameScaffold>(find.byType(GameScaffold));
    expect(scaffold.palette, kLig4Palette);
    expect(scaffold.result, isNull);
    expect(find.text('Lig 4'), findsWidgets);
    expect(find.text('Contra o computador'), findsOneWidget);
    expect(find.text('Fácil'), findsOneWidget);
    expect(find.text('Médio'), findsOneWidget);
    expect(find.text('Difícil'), findsOneWidget);
    expect(find.text('Jogar!'), findsOneWidget);
  });

  testWidgets('dois jogadores: tocar na coluna solta a peça e passa a vez', (tester) async {
    final p = await pumpScreen(tester);
    await startDuo(tester);
    expect(find.text('Lig 4'), findsOneWidget, reason: 'sem nível no título');
    expect(find.text('Vez de 🔴 Jogador 1'), findsOneWidget);
    await playColumns(tester, [3]);
    expect(p.board[5][3], 1);
    expect(find.text('Vez de 🟡 Jogador 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('buracos e peças aparecem com tamanho de verdade', (tester) async {
    await pumpScreen(tester);
    await startDuo(tester);
    await playColumns(tester, [0]);

    final cells = find.descendant(
      of: find.byKey(const Key('col-0')),
      matching: find.byType(DecoratedBox),
    );
    expect(cells, findsNWidgets(6));
    for (final element in cells.evaluate()) {
      final size = (element.renderObject! as RenderBox).size;
      expect(size.width, greaterThan(20), reason: 'célula sem largura');
      expect(size.height, greaterThan(20), reason: 'célula sem altura');
    }
  });

  testWidgets('dois jogadores: fluxo completo com os nomes, placar e os dois botões',
      (tester) async {
    final p = await pumpScreen(tester);
    await startDuo(tester, name1: 'Ana', name2: 'Beto');
    expect(find.text('Vez de 🔴 Ana'), findsOneWidget);

    await playColumns(tester, [0, 1, 0, 1, 0, 1, 0]);
    expect(p.winner, 1);
    expect(find.byType(ResultPanel), findsOneWidget);
    expect(find.text('🏆'), findsOneWidget);
    expect(find.text('Ana venceu!'), findsOneWidget);
    expect(find.textContaining('Vez de'), findsNothing);
    final panel = tester.widget<ResultPanel>(find.byType(ResultPanel));
    expect(panel.palette, kLig4Palette);
    expect(panel.actions.map((a) => (a.label, a.primary)),
        [('Jogar de novo', true), ('Trocar jogadores', false)]);

    // Jogar de novo: tabuleiro limpo, quem começa agora é o Beto.
    await tester.tap(find.text('Jogar de novo'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultPanel), findsNothing);
    expect(p.board.expand((r) => r).every((v) => v == 0), isTrue);
    expect(find.text('Vez de 🟡 Beto'), findsOneWidget);

    await playColumns(tester, [0, 1, 0, 1, 0, 1, 0]);
    expect(find.text('Beto venceu!'), findsOneWidget);
    expect(p.wins1, 1);
    expect(p.wins2, 1);

    // Trocar jogadores: volta à tela de início.
    await tester.tap(find.text('Trocar jogadores'));
    await tester.pumpAndSettle();
    expect(find.text('Jogar!'), findsOneWidget);
    expect(find.byType(ResultPanel), findsNothing);
    expect(p.wins1 + p.wins2 + p.draws, 0);
  });

  testWidgets('empate mostra 🤝 Empate!', (tester) async {
    final p = await pumpScreen(tester);
    await startDuo(tester);
    for (final col in _drawOrder) {
      await tester.tap(find.byKey(Key('col-$col')));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pumpAndSettle();
    expect(p.draws, 1);
    expect(find.text('🤝'), findsWidgets); // placar e painel
    expect(find.text('Empate!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final level in ['Fácil', 'Médio', 'Difícil']) {
    testWidgets('contra o computador: o título mostra o nível $level', (tester) async {
      await pumpScreen(tester);
      await startSolo(tester, level: level);
      expect(find.text('Lig 4 • $level'), findsOneWidget);
      expect(find.text('Computador'), findsOneWidget, reason: 'nome no placar');
    });
  }

  testWidgets('contra o computador: "Pensando..." enquanto ele decide', (tester) async {
    final p = await pumpScreen(tester, thinkTime: const Duration(milliseconds: 500));
    await startSolo(tester);
    expect(find.text('Vez de 🔴 Jogador 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('col-3')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('🤖 Pensando...'), findsOneWidget);
    await tester.tap(find.byKey(const Key('col-4'))); // ignorado
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(p.board[5][4], 0);
    expect(p.board[5][0], Lig4Provider.computer);
    expect(find.text('Vez de 🔴 Jogador 1'), findsOneWidget);
  });

  testWidgets('contra o computador: humano vence e Jogar de novo faz o computador começar',
      (tester) async {
    final p = await pumpScreen(tester);
    await startSolo(tester);
    await playColumns(tester, [6, 6, 6, 6]); // o computador joga na coluna 0
    expect(find.text('Jogador 1 venceu!'), findsOneWidget);
    expect(find.text('Lig 4 • Médio'), findsOneWidget);

    await tester.tap(find.text('Jogar de novo'));
    await tester.pumpAndSettle();
    expect(p.board[5][0], Lig4Provider.computer, reason: 'o computador abriu');
    expect(find.text('Vez de 🔴 Jogador 1'), findsOneWidget);
  });

  testWidgets('contra o computador: derrota mostra 🤖 O computador venceu!', (tester) async {
    final p = await pumpScreen(tester);
    await startSolo(tester);
    await playColumns(tester, [6, 5, 6, 5]);
    expect(p.winner, Lig4Provider.computer);
    expect(find.text('🤖'), findsOneWidget);
    expect(find.text('O computador venceu!'), findsOneWidget);

    await tester.tap(find.text('Trocar jogadores'));
    await tester.pumpAndSettle();
    expect(find.text('Lig 4'), findsWidgets);
    expect(find.text('Lig 4 • Médio'), findsNothing);
    expect(find.text('Jogar!'), findsOneWidget);
  });

  testWidgets('seta de voltar fecha o jogo e volta ao menu', (tester) async {
    await pumpScreen(tester);
    await startDuo(tester);
    await playColumns(tester, [3]);
    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsOneWidget);
    expect(find.byType(Lig4Screen), findsNothing);
  });

  for (final size in [const Size(360, 740), const Size(320, 568)]) {
    testWidgets('sem overflow em ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await pumpScreen(tester, size: size);
      expect(tester.takeException(), isNull, reason: 'tela de início solo');
      await tester.tap(find.text('Dois jogadores'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'tela de início em dupla');
      await tester.tap(find.text('Jogar!'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'partida');
      await playColumns(tester, [0, 1, 0, 1, 0, 1, 0]);
      expect(find.byType(ResultPanel), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'resultado');
      await tester.tap(find.text('Trocar jogadores'));
      await tester.pumpAndSettle();
      await startSolo(tester, level: 'Difícil');
      expect(find.text('Lig 4 • Difícil'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'partida solo');
    });
  }
}
