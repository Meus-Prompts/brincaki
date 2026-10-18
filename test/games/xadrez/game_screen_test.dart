// test/games/xadrez/game_screen_test.dart

import 'package:brincaki/games/xadrez/logic/ai.dart';
import 'package:brincaki/games/xadrez/logic/position.dart';
import 'package:brincaki/games/xadrez/models/game_state.dart';
import 'package:brincaki/games/xadrez/providers/game_provider.dart';
import 'package:brincaki/games/xadrez/screens/game_screen.dart';
import 'package:brincaki/games/xadrez/widgets/chess_piece.dart';
import 'package:brincaki/games/xadrez/widgets/promotion_picker.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/player_setup.dart';
import 'package:brincaki/widgets/result_panel.dart';
import 'package:brincaki/widgets/score_board.dart';
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

const _vsPretas = PlayerSetupResult(
  mode: PlayMode.solo,
  player1: 'Ana',
  player2: 'Computador',
  levelIndex: 0,
  sideIndex: 1,
);

const _sizes = [Size(360, 740), Size(320, 568)];

Future<ChessMove> firstMove(ChessPosition p, AiLevel l) async =>
    p.legalMoves().first;

ChessPosition fen(String f) => ChessPosition.fromFen(f);

Future<XadrezProvider> pumpScreen(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = XadrezProvider(
    thinkTime: Duration.zero,
    aiRunner: firstMove,
  );
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameShell(
                  theme: kXadrezPalette.theme,
                  wrapProvider: (child) => ChangeNotifierProvider.value(
                      value: provider, child: child),
                  home: (_) => const XadrezScreen(),
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
      expect(find.text('Xadrez'), findsWidgets);
      expect(find.text('Brancas'), findsOneWidget);
      expect(find.text('Pretas'), findsOneWidget);
      expect(find.text('Contra o computador'), findsOneWidget);
    });

    testWidgets('dois jogadores: mate do louco pelos toques ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      await tapText(tester, 'Dois jogadores');
      await tapText(tester, 'Jogar!');
      expect(find.text('Vez de ⚪ Jogador 1'), findsOneWidget);
      for (final (from, to) in [(53, 45), (12, 28), (54, 38), (3, 39)]) {
        await tapSq(tester, from);
        await tapSq(tester, to);
      }
      expect(find.byType(ResultPanel), findsOneWidget);
      expect(find.text('Xeque-mate!'), findsOneWidget);
      expect(find.text('Jogador 2 venceu!'), findsOneWidget);
      expect(find.textContaining('Vez de'), findsNothing);
      expect(p.phase, XadrezPhase.finished);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dois jogadores: Jogador 1 com as pretas ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      await tapText(tester, 'Dois jogadores');
      await tapText(tester, 'Pretas');
      await tapText(tester, 'Jogar!');
      // As brancas começam: é a vez do Jogador 2.
      expect(find.text('Vez de ⚪ Jogador 2'), findsOneWidget);
      final board = tester.widget<ScoreBoard>(find.byType(ScoreBoard));
      expect((board.symbol1, board.symbol2), ('⚫', '⚪'));
      // Tabuleiro fixo com as brancas embaixo.
      expect(p.flipped, isFalse);
      final top = tester.getTopLeft(find.byKey(const Key('sq-0')));
      final bottom = tester.getTopLeft(find.byKey(const Key('sq-63')));
      expect(top.dy, lessThan(bottom.dy));
      // Mate do louco: as pretas (Jogador 1) vencem.
      for (final (from, to) in [(53, 45), (12, 28), (54, 38), (3, 39)]) {
        await tapSq(tester, from);
        await tapSq(tester, to);
      }
      expect(find.text('Jogador 1 venceu!'), findsOneWidget);
      expect(p.wins1, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('xeque mostra o aviso ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, fen('4k3/8/8/8/8/8/8/r3K3 w - - 0 1'));
      await tester.pumpAndSettle();
      expect(find.text('Vez de ⚪ Ana • Xeque!'), findsOneWidget);
      await tapSq(tester, 60);
      await tapSq(tester, 52);
      expect(find.textContaining('Xeque!'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('alvos: ponto na casa vazia e anel na captura ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, fen('4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1'));
      await tester.pumpAndSettle();
      await tapSq(tester, 36);
      expect(find.byKey(const Key('target-28')), findsOneWidget);
      expect(find.byKey(const Key('capture-27')), findsOneWidget);
      expect(find.byKey(const Key('target-27')), findsNothing);
    });

    testWidgets('promoção pelo seletor ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, fen('8/P6k/8/8/8/8/8/K7 w - - 0 1'));
      await tester.pumpAndSettle();
      await tapSq(tester, 8);
      await tapSq(tester, 0);
      expect(find.text('Promover para:'), findsOneWidget);
      for (final t in [5, 4, 3, 2]) {
        expect(find.byKey(Key('promo-$t')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('promo-5')));
      await tester.pumpAndSettle();
      expect(find.text('Promover para:'), findsNothing);
      expect(p.game.position.cells[0], 5);
      expect(find.text('Vez de ⚫ Beto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancelar promoção ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, fen('8/P6k/8/8/8/8/8/K7 w - - 0 1'));
      await tester.pumpAndSettle();
      await tapSq(tester, 8);
      await tapSq(tester, 0);
      await tapText(tester, 'Cancelar');
      expect(find.text('Promover para:'), findsNothing);
      expect(p.game.position.cells[8], 1);
      expect(find.text('Vez de ⚪ Ana'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tocar fora do cartão da promoção cancela ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, fen('8/P6k/8/8/8/8/8/K7 w - - 0 1'));
      await tester.pumpAndSettle();
      await tapSq(tester, 8);
      await tapSq(tester, 0);
      // Tocar no próprio cartão não fecha a escolha.
      await tester.tap(find.text('Promover para:'));
      await tester.pumpAndSettle();
      expect(find.text('Promover para:'), findsOneWidget);
      expect(p.pendingPromotion, isNotNull);
      // Tocar no fundo escuro cancela o lance.
      final corner = tester.getTopLeft(find.byType(PromotionPicker));
      await tester.tapAt(corner + const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('Promover para:'), findsNothing);
      expect(p.pendingPromotion, isNull);
      expect(p.game.position.cells[8], 1);
      expect(p.game.position.cells[0], 0);
      expect(find.text('Vez de ⚪ Ana'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('resultados e motivos ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_vsBrancas, fen(
          'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3'));
      await tester.pumpAndSettle();
      expect(find.text('O computador venceu!'), findsOneWidget);
      expect(find.text('Xeque-mate!'), findsOneWidget);
      p.startFrom(_duo, fen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'));
      await tester.pumpAndSettle();
      expect(find.text('Empate!'), findsOneWidget);
      expect(find.text('Afogamento'), findsOneWidget);
      p.startFrom(_duo, fen('8/8/8/4k3/8/8/8/K7 w - - 0 1'));
      await tester.pumpAndSettle();
      expect(find.text('Só sobraram peças que não dão mate'), findsOneWidget);
      p.startFrom(_duo, fen('4k3/8/8/8/8/8/8/R3K3 w - - 100 80'));
      await tester.pumpAndSettle();
      expect(find.text('50 lances sem captura nem peão'), findsOneWidget);
      p.startFrom(_duo, fen('4k3/8/8/8/8/8/8/R3K3 w - - 0 1'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        for (final (from, to) in [(60, 59), (4, 3), (59, 60), (3, 4)]) {
          await tapSq(tester, from);
          await tapSq(tester, to);
        }
      }
      expect(find.text('A mesma posição 3 vezes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Jogar de novo e Trocar jogadores ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, fen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'));
      await tester.pumpAndSettle();
      final panel = tester.widget<ResultPanel>(find.byType(ResultPanel));
      expect(panel.actions.map((a) => a.label),
          ['Jogar de novo', 'Trocar jogadores']);
      await tester.tap(find.text('Jogar de novo'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultPanel), findsNothing);
      expect(p.draws, 1);
      expect(p.phase, XadrezPhase.playing);
      p.startFrom(_duo, fen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trocar jogadores'));
      await tester.pumpAndSettle();
      expect(find.text('Jogar!'), findsOneWidget);
      expect(p.phase, XadrezPhase.setup);
    });

    testWidgets('título mostra o nível do computador ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      for (final (level, label) in [(0, 'Fácil'), (1, 'Médio'), (2, 'Difícil')]) {
        p.startFrom(
          PlayerSetupResult(
            mode: PlayMode.solo,
            player1: 'Ana',
            player2: 'Computador',
            levelIndex: level,
            sideIndex: 0,
          ),
          ChessPosition.initial(),
        );
        await tester.pumpAndSettle();
        expect(find.text('Xadrez • $label'), findsOneWidget);
      }
      p.startFrom(_duo, ChessPosition.initial());
      await tester.pumpAndSettle();
      expect(find.textContaining('Xadrez •'), findsNothing);
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

    testWidgets('com as pretas o computador começa e o tabuleiro vira ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      await tapText(tester, 'Pretas');
      await tapText(tester, 'Jogar!');
      expect(find.text('Xadrez • Fácil'), findsOneWidget);
      expect(p.flipped, isTrue);
      expect(p.lastMove, isNotNull);
      expect(find.text('Vez de ⚫ Jogador 1'), findsOneWidget);
      final top = tester.getTopLeft(find.byKey(const Key('sq-63')));
      final bottom = tester.getTopLeft(find.byKey(const Key('sq-0')));
      expect(top.dy, lessThan(bottom.dy));
      expect(top.dx, lessThan(bottom.dx));
      // Toques ainda endereçam as casas reais: peão preto em e7 (12).
      await tapSq(tester, 12);
      expect(p.selected, 12);
      expect(tester.takeException(), isNull);
    });

    testWidgets('coordenadas respeitam o giro ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, ChessPosition.initial());
      await tester.pumpAndSettle();
      expect(find.text('a'), findsOneWidget);
      expect(find.text('h'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      final a = tester.getTopLeft(find.text('a'));
      final h = tester.getTopLeft(find.text('h'));
      expect(a.dx, lessThan(h.dx));
    });

    testWidgets('coordenadas viram com as pretas ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_vsPretas,
          fen('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1'));
      await tester.pumpAndSettle();
      expect(p.flipped, isTrue);
      final a = tester.getTopLeft(find.text('a'));
      final h = tester.getTopLeft(find.text('h'));
      // Na fileira de baixo o 'h' fica à esquerda do 'a'.
      expect(h.dx, lessThan(a.dx));
      expect(h.dy, closeTo(a.dy, 0.01));
      // O '8' fica embaixo e o '1' em cima.
      final one = tester.getTopLeft(find.text('1'));
      final eight = tester.getTopLeft(find.text('8'));
      expect(one.dy, lessThan(eight.dy));
      // '8' na casa h8 (canto de baixo à esquerda) e '1' em h1 (em cima).
      Finder inSq(int i, String t) =>
          find.descendant(of: find.byKey(Key('sq-$i')), matching: find.text(t));
      expect(inSq(7, '8'), findsOneWidget);
      expect(inSq(7, 'h'), findsOneWidget);
      expect(inSq(0, 'a'), findsOneWidget);
      expect(inSq(63, '1'), findsOneWidget);
      final bottomLeft = tester.getTopLeft(find.byKey(const Key('sq-7')));
      final topLeft = tester.getTopLeft(find.byKey(const Key('sq-63')));
      expect(bottomLeft.dy, greaterThan(topLeft.dy));
      expect(bottomLeft.dx, closeTo(topLeft.dx, 0.01));
    });

    testWidgets('rei em mate fica com a casa vermelha ($tag)', (tester) async {
      final p = await pumpScreen(tester, size);
      await tapText(tester, 'Dois jogadores');
      await tapText(tester, 'Jogar!');
      for (final (from, to) in [(53, 45), (12, 28), (54, 38), (3, 39)]) {
        await tapSq(tester, from);
        await tapSq(tester, to);
      }
      expect(p.game.end, XadrezEnd.checkmate);
      Color colorOf(int i) => tester
          .widget<ColoredBox>(find
              .descendant(
                  of: find.byKey(Key('sq-$i')),
                  matching: find.byType(ColoredBox))
              .first)
          .color;
      expect(colorOf(60), const Color(0xFFEF4444));
      expect(colorOf(4), isNot(const Color(0xFFEF4444)));
    });

    testWidgets('promoção das pretas mostra peças pretas ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, fen('7k/8/8/8/8/8/p7/7K b - - 0 1'));
      await tester.pumpAndSettle();
      await tapSq(tester, 48);
      await tapSq(tester, 56);
      expect(find.text('Promover para:'), findsOneWidget);
      for (final t in [5, 4, 3, 2]) {
        final piece = tester.widget<ChessPiece>(find.descendant(
            of: find.byKey(Key('promo-$t')),
            matching: find.byType(ChessPiece)));
        expect(piece.value, -t);
      }
      await tester.tap(find.byKey(const Key('promo-5')));
      await tester.pumpAndSettle();
      expect(p.game.position.cells[56], -5);
      // A dama nova em a1 dá xeque no rei branco em h1.
      expect(find.text('Vez de ⚪ Ana • Xeque!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('voltar depois do fim sai sem perguntar ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_duo, fen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'));
      await tester.pumpAndSettle();
      expect(p.phase, XadrezPhase.finished);
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text('Sair do jogo?'), findsNothing);
      expect(find.byType(XadrezScreen), findsNothing);
      expect(find.text('menu'), findsOneWidget);
    });

    testWidgets('sem overflow com placar, vez e resultado ($tag)',
        (tester) async {
      final p = await pumpScreen(tester, size);
      p.startFrom(_vsBrancas, fen(
          'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ChessPiece: brancas com contorno, pretas cheias',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Row(children: [
        ChessPiece(value: 5, size: 40),
        ChessPiece(value: -6, size: 40),
      ]),
    ));
    final glyphs = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(glyphs, ['♛', '♕', '♚']);
  });
}
