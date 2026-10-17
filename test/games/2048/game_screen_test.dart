// test/games/2048/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/2048/data/high_score_store.dart';
import 'package:brincaki/games/2048/models/game_state.dart';
import 'package:brincaki/games/2048/providers/game_provider.dart';
import 'package:brincaki/games/2048/screens/game_screen.dart';
import 'package:brincaki/games/2048/widgets/tile_widget.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/result_panel.dart';

class _MemoryStore implements HighScoreStore {
  _MemoryStore([this.saved = 0]);
  int saved;

  @override
  Future<int> load() async => saved;
  @override
  Future<void> save(int value) async => saved = value;
}

final _board = find.byKey(const Key('board2048'));
final _headerNewGame = find.byKey(const Key('header-new-game'));

Finder _inPanel(String text) =>
    find.descendant(of: find.byType(ResultPanel), matching: find.text(text));

const _single8 = [
  [0, 0, 0, 0],
  [0, 8, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 0],
];

const _winning = [
  [1024, 1024, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 0],
];

/// Travado depois de ir para a direita.
const _losing = [
  [2, 4, 2, 4],
  [4, 2, 4, 2],
  [32, 4, 2, 4],
  [8, 16, 8, 0],
];

/// Menu de mentira que abre o 2048 do mesmo jeito que o menu de verdade.
Future<Game2048Provider> pumpGame(
  WidgetTester tester, {
  Size size = const Size(360, 740),
  int saved = 0,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final provider = Game2048Provider(store: _MemoryStore(saved), random: Random(3));
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameShell(
                  theme: k2048Palette.theme,
                  wrapProvider: (child) =>
                      ChangeNotifierProvider.value(value: provider, child: child),
                  home: (_) => const Game2048Screen(),
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

Future<void> setBoard(WidgetTester tester, Game2048Provider p, List<List<int>> board) async {
  p.debugSetBoard(board);
  await tester.pump();
}

Future<void> fling(WidgetTester tester, Offset offset) async {
  await tester.fling(_board, offset, 1000);
  await tester.pumpAndSettle();
}

Future<void> win(WidgetTester tester, Game2048Provider p) async {
  await setBoard(tester, p, _winning);
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
  await tester.pumpAndSettle();
  expect(p.phase, Game2048Phase.won);
}

Future<void> lose(WidgetTester tester, Game2048Provider p) async {
  await setBoard(tester, p, _losing);
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  await tester.pumpAndSettle();
  expect(p.phase, Game2048Phase.lost);
}

void main() {
  testWidgets('mostra título, Pontos, Recorde, Novo jogo e o fundo da paleta',
      (tester) async {
    await pumpGame(tester, saved: 300);
    expect(find.text('2048'), findsOneWidget);
    expect(find.text('PONTOS'), findsOneWidget);
    expect(find.text('RECORDE'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(_headerNewGame, findsOneWidget);
    expect(find.byType(ResultPanel), findsNothing);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, k2048Palette.background);
  });

  testWidgets('as peças mantêm as cores clássicas', (tester) async {
    final p = await pumpGame(tester);
    await setBoard(tester, p, [
      [2, 4, 8, 16],
      [32, 64, 128, 256],
      [512, 1024, 2048, 4096],
      [16384, 0, 0, 0],
    ]);
    expect(find.text('16384'), findsOneWidget);
    expect(find.text('1024'), findsOneWidget);
    expect(tileColor(0), const Color(0xFFCDC1B4));
    expect(tileColor(2), const Color(0xFFEEE4DA));
    expect(tileColor(2048), const Color(0xFFEDC22E));
    expect(tileColor(4096), const Color(0xFF3C3A32));
    expect(tester.takeException(), isNull);
  });

  group('swipe', () {
    for (final (name, offset, cell) in [
      ('esquerda', const Offset(-300, 0), (1, 0)),
      ('direita', const Offset(300, 0), (1, 3)),
      ('cima', const Offset(0, -300), (0, 1)),
      ('baixo', const Offset(0, 300), (3, 1)),
    ]) {
      testWidgets('para a $name move as peças', (tester) async {
        final p = await pumpGame(tester);
        await setBoard(tester, p, _single8);
        await fling(tester, offset);
        final (r, c) = cell;
        expect(p.board[r][c], 8);
        expect(p.moveCount, 1);
      });
    }

    testWidgets('arrasto lento, parando antes de soltar, também move',
        (tester) async {
      final p = await pumpGame(tester);
      await setBoard(tester, p, _single8);

      final gesture = await tester.startGesture(tester.getCenter(_board));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(-15, 0));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 500)); // dedo parado
      await gesture.up();
      await tester.pumpAndSettle();

      expect(p.board[1][0], 8);
    });

    testWidgets('arrasto curto não move nada', (tester) async {
      final p = await pumpGame(tester);
      await setBoard(tester, p, _single8);
      final gesture = await tester.startGesture(tester.getCenter(_board));
      await gesture.moveBy(const Offset(5, 3));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(p.moveCount, 0);
      expect(p.board[1][1], 8);
    });
  });

  group('teclado', () {
    for (final (key, cell) in [
      (LogicalKeyboardKey.arrowLeft, (1, 0)),
      (LogicalKeyboardKey.arrowRight, (1, 3)),
      (LogicalKeyboardKey.arrowUp, (0, 1)),
      (LogicalKeyboardKey.arrowDown, (3, 1)),
    ]) {
      testWidgets('${key.keyLabel} move as peças', (tester) async {
        final p = await pumpGame(tester);
        await setBoard(tester, p, _single8);
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        final (r, c) = cell;
        expect(p.board[r][c], 8);
      });
    }

    testWidgets('outras teclas são ignoradas', (tester) async {
      final p = await pumpGame(tester);
      await setBoard(tester, p, _single8);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pumpAndSettle();
      expect(p.moveCount, 0);
    });

    testWidgets('segurar a seta não repete a jogada', (tester) async {
      final p = await pumpGame(tester);
      await setBoard(tester, p, _single8);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(p.moveCount, 1);
    });
  });

  testWidgets('Novo jogo do cabeçalho recomeça a partida', (tester) async {
    final p = await pumpGame(tester);
    await setBoard(tester, p, [
      [4, 4, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(p.score, 8);
    expect(find.text('8'), findsWidgets);

    await tester.tap(_headerNewGame);
    await tester.pumpAndSettle();
    expect(p.score, 0);
    expect(p.moveCount, 0);
    // O recorde continua.
    expect(p.best, 8);
  });

  group('vitória', () {
    testWidgets('mostra o painel com Continuar e Novo jogo', (tester) async {
      final p = await pumpGame(tester);
      await win(tester, p);
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('Você chegou ao 2048!'), findsOneWidget);
      expect(_inPanel('Continuar'), findsOneWidget);
      expect(_inPanel('Novo jogo'), findsOneWidget);
      // Continuar é o principal; Novo jogo, o secundário.
      expect(
        find.ancestor(of: _inPanel('Continuar'), matching: find.byType(ElevatedButton)),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: _inPanel('Novo jogo'), matching: find.byType(OutlinedButton)),
        findsOneWidget,
      );
      // O tabuleiro continua à vista.
      expect(find.descendant(of: _board, matching: find.text('2048')), findsOneWidget);
    });

    testWidgets('Continuar fecha o painel e deixa jogar', (tester) async {
      final p = await pumpGame(tester);
      await win(tester, p);
      await tester.tap(_inPanel('Continuar'));
      await tester.pumpAndSettle();
      expect(p.phase, Game2048Phase.playing);
      expect(find.byType(ResultPanel), findsNothing);
      expect(p.board[0][0], 2048);
    });

    testWidgets('Novo jogo do painel recomeça', (tester) async {
      final p = await pumpGame(tester);
      await win(tester, p);
      await tester.tap(_inPanel('Novo jogo'));
      await tester.pumpAndSettle();
      expect(p.phase, Game2048Phase.playing);
      expect(p.score, 0);
      expect(find.byType(ResultPanel), findsNothing);
    });

    testWidgets('setas não mexem no tabuleiro com o painel aberto', (tester) async {
      final p = await pumpGame(tester);
      await win(tester, p);
      final moves = p.moveCount;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(p.moveCount, moves);
    });
  });

  group('derrota', () {
    testWidgets('mostra Fim de jogo com a pontuação', (tester) async {
      final p = await pumpGame(tester);
      await lose(tester, p);
      expect(find.text('😵'), findsOneWidget);
      expect(find.text('Fim de jogo'), findsOneWidget);
      expect(find.text('Pontuação: ${p.score}'), findsOneWidget);
      expect(_inPanel('Novo jogo'), findsOneWidget);
      expect(_inPanel('Continuar'), findsNothing);
    });

    testWidgets('Novo jogo do painel recomeça', (tester) async {
      final p = await pumpGame(tester);
      await lose(tester, p);
      await tester.tap(_inPanel('Novo jogo'));
      await tester.pumpAndSettle();
      expect(p.phase, Game2048Phase.playing);
      expect(find.byType(ResultPanel), findsNothing);
    });
  });

  testWidgets('seta de voltar sai para o menu', (tester) async {
    await pumpGame(tester);
    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsOneWidget);
    expect(find.byType(Game2048Screen), findsNothing);
  });

  group('telas pequenas', () {
    for (final size in const [Size(360, 740), Size(320, 568)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}: jogo e painéis cabem',
          (tester) async {
        final p = await pumpGame(tester, size: size);
        expect(tester.takeException(), isNull);
        final board = tester.getRect(_board);
        expect(board.right, lessThanOrEqualTo(size.width));
        expect(board.bottom, lessThanOrEqualTo(size.height));

        await win(tester, p);
        expect(tester.takeException(), isNull);
        expect(tester.getRect(_inPanel('Continuar')).bottom, lessThanOrEqualTo(size.height));

        await tester.tap(_inPanel('Novo jogo'));
        await tester.pumpAndSettle();
        await lose(tester, p);
        expect(tester.takeException(), isNull);
        expect(tester.getRect(_inPanel('Novo jogo')).bottom, lessThanOrEqualTo(size.height));
      });
    }

    testWidgets('cabeçalho cabe com fonte grande e recorde alto', (tester) async {
      final p = await pumpGame(tester, size: const Size(320, 640), saved: 25000, textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(p.best, 25000);
      expect(tester.getRect(_headerNewGame).right, lessThanOrEqualTo(320));
    });
  });
}
