// test/games/damas/game_screen_test.dart

import 'package:brincaki/games/damas/logic/ai.dart';
import 'package:brincaki/games/damas/logic/board.dart';
import 'package:brincaki/games/damas/models/game_state.dart';
import 'package:brincaki/games/damas/providers/game_provider.dart';
import 'package:brincaki/games/damas/screens/game_screen.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/player_setup.dart';
import 'package:brincaki/widgets/result_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _duo = PlayerSetupResult(
  mode: PlayMode.twoPlayers,
  player1: 'Ana',
  player2: 'Beto',
);
const _vsBrancas = PlayerSetupResult(
  mode: PlayMode.solo,
  player1: 'Ana',
  player2: 'Computador',
  levelIndex: 0,
  sideIndex: 0,
);

const _sizes = [Size(360, 740), Size(320, 568)];

Future<DamasMove> firstMove(DamasPosition p, AiLevel l) async =>
    legalMoves(p).first;

DamasPosition pos(Map<int, int> pieces, [DamasSide turn = DamasSide.white]) {
  final cells = List<int>.filled(64, 0);
  pieces.forEach((i, v) => cells[i] = v);
  return DamasPosition(cells, turn);
}

Future<DamasProvider> pumpScreen(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = DamasProvider(thinkTime: Duration.zero, aiRunner: firstMove);
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameShell(
                  theme: kDamasPalette.theme,
                  wrapProvider: (child) => ChangeNotifierProvider.value(
                      value: provider, child: child),
                  home: (_) => const DamasScreen(),
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

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pump();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> tapSq(WidgetTester tester, int i) async {
  await tester.tap(find.byKey(Key('sq-$i')));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in _sizes) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('setup usa a paleta e pede a cor ($tag)', (tester) async {
      await pumpScreen(tester, size);
      expect(find.text('Damas'), findsWidgets);
      expect(find.text('Brancas'), findsOneWidget);
      expect(find.text('Pretas'), findsOneWidget);
      expect(find.text('Contra o computador'), findsOneWidget);
    });

    testWidgets('dois jogadores: lance pelos toques e vez passa ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      await tapText(tester, 'Dois jogadores');
      await tapText(tester, 'Jogar!');
      expect(find.text('Vez de ⚪ Jogador 1'), findsOneWidget);
      await tapSq(tester, 42);
      expect(find.byKey(const Key('target-33')), findsOneWidget);
      expect(find.byKey(const Key('target-35')), findsOneWidget);
      await tapSq(tester, 33);
      expect(p.game.position.cells[33], 1);
      expect(p.game.position.cells[42], 0);
      expect(find.text('Vez de ⚫ Jogador 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('captura obrigatória mostra o aviso ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, pos({42: 1, 60: 1, 33: -1, 5: -1}));
      await tester.pumpAndSettle();
      expect(find.text('Vez de ⚪ Ana • Captura obrigatória!'), findsOneWidget);
      expect(find.byKey(const Key('must-capture')), findsOneWidget);
      await tapSq(tester, 42);
      await tapSq(tester, 24);
      expect(find.textContaining('Captura obrigatória'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fim de jogo mostra o painel e o tabuleiro ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, pos({42: 1, 33: -1}));
      await tester.pumpAndSettle();
      await tapSq(tester, 42);
      await tapSq(tester, 24);
      expect(find.byType(ResultPanel), findsOneWidget);
      expect(find.text('Ana venceu!'), findsOneWidget);
      expect(find.text('Sem peças para jogar'), findsOneWidget);
      expect(find.byKey(const Key('sq-24')), findsOneWidget);
      expect(find.textContaining('Vez de'), findsNothing);
      final panel = tester.widget<ResultPanel>(find.byType(ResultPanel));
      expect(panel.actions.map((a) => a.label),
          ['Jogar de novo', 'Trocar jogadores']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Jogar de novo e Trocar jogadores ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, pos({42: 1, 33: -1}));
      await tester.pumpAndSettle();
      await tapSq(tester, 42);
      await tapSq(tester, 24);
      await tester.tap(find.text('Jogar de novo'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultPanel), findsNothing);
      expect(p.game.position.cells.where((v) => v != 0).length, 24);
      expect(p.wins1, 1);
      p.startFrom(_duo, pos({42: 1, 33: -1}));
      await tester.pumpAndSettle();
      await tapSq(tester, 42);
      await tapSq(tester, 24);
      await tester.tap(find.text('Trocar jogadores'));
      await tester.pumpAndSettle();
      expect(find.text('Jogar!'), findsOneWidget);
      expect(p.phase, DamasPhase.setup);
    });

    testWidgets('voltar durante a partida pede confirmação ($tag)',
        (tester) async {
      await pumpScreen(tester, size);
      await tapText(tester, 'Dois jogadores');
      await tapText(tester, 'Jogar!');
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text('Sair do jogo?'), findsOneWidget);
    });

    testWidgets(
        'com as pretas o computador começa e o tabuleiro vira ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      await tapText(tester, 'Pretas');
      await tapText(tester, 'Jogar!');
      expect(find.text('Damas • Fácil'), findsOneWidget);
      expect(p.flipped, isTrue);
      // O computador (brancas) já jogou o primeiro lance.
      expect(p.lastMove, isNotNull);
      expect(find.text('Vez de ⚫ Jogador 1'), findsOneWidget);
      // Casa 63 (canto de baixo-direita das brancas) fica em cima à esquerda.
      final top = tester.getTopLeft(find.byKey(const Key('sq-63')));
      final bottom = tester.getTopLeft(find.byKey(const Key('sq-0')));
      expect(top.dy, lessThan(bottom.dy));
      expect(top.dx, lessThan(bottom.dx));
      // Os toques ainda endereçam as casas reais: peça preta da linha 2.
      await tapSq(tester, 17);
      expect(p.selected, 17);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem overflow com placar, vez e resultado ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_vsBrancas, pos({42: 1, 33: -1}, DamasSide.black));
      await tester.pumpAndSettle();
      expect(find.text('O computador venceu!'), findsOneWidget);
      expect(find.byType(ResultPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
