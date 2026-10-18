// integration_test/app_test.dart
//
// O app de verdade: abre cada jogo pelo menu, joga uma partida até o painel de
// resultado tocando na tela e volta ao menu.
//
// Rodar: flutter test integration_test -d linux

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brincaki/games/2048/providers/game_provider.dart';
import 'package:brincaki/games/cacapalavras/providers/game_provider.dart';
import 'package:brincaki/games/cacapalavras/widgets/letter_grid.dart';
import 'package:brincaki/games/contas/providers/game_provider.dart';
import 'package:brincaki/games/damas/providers/game_provider.dart';
import 'package:brincaki/games/forca/providers/game_provider.dart';
import 'package:brincaki/games/lig4/logic/board.dart' as lig4;
import 'package:brincaki/games/lig4/providers/game_provider.dart';
import 'package:brincaki/games/memoria/providers/game_provider.dart';
import 'package:brincaki/games/sudoku/providers/game_provider.dart';
import 'package:brincaki/games/termo/models/game_state.dart';
import 'package:brincaki/games/termo/providers/game_provider.dart';
import 'package:brincaki/games/tictactoe/providers/game_provider.dart';
import 'package:brincaki/games/xadrez/logic/position.dart' show squareOf;
import 'package:brincaki/games/xadrez/providers/game_provider.dart';
import 'package:brincaki/main.dart';
import 'package:brincaki/widgets/game_scaffold.dart';
import 'package:brincaki/widgets/result_panel.dart';

const _menuSubtitle = 'Escolha um jogo para brincar!';

Future<void> launchApp(WidgetTester tester) async {
  // Recorde do 2048 e palavra do dia começam do zero, sem mexer nos dados
  // de quem joga neste computador.
  SharedPreferences.setMockInitialValues({});
  await configureApp();
  await tester.pumpWidget(const BrincakiApp());
  await tester.pumpAndSettle();
  expect(find.text(_menuSubtitle), findsOneWidget);
}

Future<void> openGame(WidgetTester tester, String title) async {
  final card = find.text(title).first;
  await tester.scrollUntilVisible(card, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
  expect(find.byType(GameScaffold), findsOneWidget);
}

/// Seta de voltar; se o jogo perguntar, confirma a saída.
Future<void> backToMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Voltar ao menu'));
  await steps(tester);
  if (find.text('Sair do jogo?').evaluate().isNotEmpty) {
    await tester.tap(find.text('Sair'));
    await steps(tester);
  }
  expect(find.text(_menuSubtitle), findsOneWidget);
  expect(find.byType(GameScaffold), findsNothing);
}

/// Avança o relógio sem esperar tudo parar (o Sudoku tem cronômetro).
Future<void> steps(WidgetTester tester, [int count = 8]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

T providerOf<T>(WidgetTester tester) => Provider.of<T>(
    tester.element(find.byType(GameScaffold)),
    listen: false);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Finder inPanel(String text) =>
    find.descendant(of: find.byType(ResultPanel), matching: find.text(text));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('menu mostra os 11 jogos', (tester) async {
    await launchApp(tester);
    for (final title in [
      'Caça-Palavras', 'Sudoku', '2048', 'Jogo da Velha',
      'Jogo da Forca', 'Jogo da Memória', 'Termo', 'Lig 4', 'Contas',
      'Damas', 'Xadrez',
    ]) {
      await tester.scrollUntilVisible(find.text(title).first, 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text(title), findsWidgets);
    }
  });

  testWidgets('Jogo da Velha: dois jogadores e contra o computador',
      (tester) async {
    await launchApp(tester);
    await openGame(tester, 'Jogo da Velha');

    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    for (final (r, c) in [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)]) {
      await tester.tap(find.byKey(Key('cell-$r-$c')));
      await tester.pumpAndSettle();
    }
    expect(inPanel('Jogador 1 venceu!'), findsOneWidget);
    await tester.tap(find.text('Jogar de novo'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultPanel), findsNothing);

    // O computador difícil nunca perde.
    final p = providerOf<TicTacToeProvider>(tester);
    p.exitToSetup();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Difícil'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Jogo da Velha • Difícil'), findsOneWidget);
    while (find.byType(ResultPanel).evaluate().isEmpty) {
      if (p.isComputerTurn || p.aiThinking) {
        await tester.pump(const Duration(milliseconds: 100));
        continue;
      }
      final free = [
        for (var r = 0; r < 3; r++)
          for (var c = 0; c < 3; c++)
            if (p.board[r][c] == 0) (r, c),
      ].first;
      await tester.tap(find.byKey(Key('cell-${free.$1}-${free.$2}')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(inPanel('Jogador 1 venceu!'), findsNothing);
    expect(
      inPanel('O computador venceu!').evaluate().length +
          inPanel('Empate!').evaluate().length,
      1,
    );
    await backToMenu(tester);
  });

  testWidgets('Lig 4: dois jogadores e contra o computador', (tester) async {
    await launchApp(tester);
    await openGame(tester, 'Lig 4');

    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    for (final col in [0, 1, 0, 1, 0, 1, 0]) {
      await tester.tap(find.byKey(Key('col-$col')));
      await tester.pumpAndSettle();
    }
    expect(inPanel('Jogador 1 venceu!'), findsOneWidget);
    await tester.tap(find.text('Trocar jogadores'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Lig 4 • Fácil'), findsOneWidget);
    final p = providerOf<Lig4Provider>(tester);
    while (find.byType(ResultPanel).evaluate().isEmpty) {
      if (p.isComputerTurn || p.aiThinking) {
        await tester.pump(const Duration(milliseconds: 100));
        continue;
      }
      final col = lig4.validColumns(p.board).first;
      await tester.tap(find.byKey(Key('col-$col')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Jogar de novo'), findsOneWidget);
    await backToMenu(tester);
  });

  testWidgets('Jogo da Memória: completa o nível 1 sem errar', (tester) async {
    await launchApp(tester);
    await openGame(tester, 'Jogo da Memória');
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Memória • Nível 1'), findsOneWidget);

    final p = providerOf<MemoryProvider>(tester);
    final byEmoji = <String, List<int>>{};
    for (final card in p.cards) {
      byEmoji.putIfAbsent(card.emoji, () => []).add(card.id);
    }
    for (final pair in byEmoji.values) {
      for (final id in pair) {
        await tester.tap(find.byKey(Key('card-$id')));
        await tester.pumpAndSettle();
      }
    }
    expect(p.moves, byEmoji.length);
    expect(find.byType(ResultPanel), findsOneWidget);
    await tester.tap(find.text('Próximo nível'));
    await tester.pumpAndSettle();
    expect(find.text('Memória • Nível 2'), findsOneWidget);
    await backToMenu(tester);
  });

  testWidgets('Jogo da Forca: acerta, avança de nível, perde e tenta de novo',
      (tester) async {
    await launchApp(tester);
    await openGame(tester, 'Jogo da Forca');
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Jogo da Forca • Nível 1'), findsOneWidget);

    final p = providerOf<ForcaProvider>(tester);
    for (final letter in p.currentWord.split('').toSet()) {
      await tapVisible(tester, find.byKey(ValueKey('tecla-$letter')));
    }
    await tester.pumpAndSettle();
    expect(inPanel('Parabéns!'), findsOneWidget);
    await tester.tap(find.text('Próxima palavra'));
    await tester.pumpAndSettle();
    expect(find.text('Jogo da Forca • Nível 2'), findsOneWidget);

    final wrong = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        .split('')
        .where((l) => !p.currentWord.contains(l))
        .take(6);
    for (final letter in wrong) {
      await tapVisible(tester, find.byKey(ValueKey('tecla-$letter')));
    }
    await tester.pumpAndSettle();
    expect(inPanel('Que pena...'), findsOneWidget);
    expect(inPanel('A palavra era: ${p.currentWord}'), findsOneWidget);
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Jogo da Forca • Nível 2'), findsOneWidget);
    await backToMenu(tester);
  });

  testWidgets('Caça-Palavras: acha todas as palavras arrastando',
      (tester) async {
    await launchApp(tester);
    await openGame(tester, 'Caça-Palavras');
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();

    final p = providerOf<WordSearchProvider>(tester);
    final rect = tester.getRect(find.byType(LetterGrid));
    final size = p.config.size;
    Offset center((int, int) cell) => Offset(
          rect.left + (cell.$2 + 0.5) * rect.width / size,
          rect.top + (cell.$1 + 0.5) * rect.height / size,
        );
    for (final word in p.words) {
      final from = center(word.cells.first);
      final to = center(word.cells.last);
      final gesture = await tester.startGesture(from);
      for (var i = 1; i <= 8; i++) {
        await gesture.moveTo(Offset.lerp(from, to, i / 8)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();
      expect(p.found, contains(word.word));
    }
    await tester.pumpAndSettle();
    expect(inPanel('Nível 1 completo!'), findsOneWidget);
    await tester.tap(find.text('Próximo nível'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Caça-Palavras • Nível 2'), findsOneWidget);
    await backToMenu(tester);
  });

  testWidgets('Sudoku: resolve tocando nas casas e no teclado',
      (tester) async {
    await launchApp(tester);
    await openGame(tester, 'Sudoku');
    await tester.tap(find.text('Jogar!'));
    await steps(tester);
    expect(find.text('Sudoku • Fácil'), findsOneWidget);

    final p = providerOf<SudokuProvider>(tester);
    final board = p.board!;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (!board.getCell(r, c).isEmpty) continue;
        await tapVisible(tester, find.byKey(Key('cell-$r-$c')));
        await tapVisible(tester, find.byKey(Key('pad-${board.solution[r][c]}')));
      }
    }
    await steps(tester);
    expect(inPanel('Parabéns!'), findsOneWidget);
    expect(p.timerRunning, isFalse);

    // Partida nova em andamento: sair pede confirmação.
    await tester.tap(find.text('Jogar de novo'));
    await steps(tester);
    expect(find.byType(ResultPanel), findsNothing);
    await tester.tap(find.byTooltip('Voltar ao menu'));
    await steps(tester);
    expect(find.text('Sair do jogo?'), findsOneWidget);
    await backToMenuAfterDialog(tester);
  });

  testWidgets('2048: arrasta, chega ao 2048, continua e recomeça',
      (tester) async {
    await launchApp(tester);
    await openGame(tester, '2048');
    final p = providerOf<Game2048Provider>(tester);

    // Algum dos quatro arrastos sempre move as peças de um tabuleiro novo.
    for (final offset in const [
      Offset(-200, 0), Offset(200, 0), Offset(0, -200), Offset(0, 200),
    ]) {
      await tester.drag(find.byKey(const Key('board2048')), offset);
      await tester.pumpAndSettle();
      if (p.moveCount > 0) break;
    }
    expect(p.moveCount, greaterThan(0));

    p.debugSetBoard([
      [1024, 1024, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(inPanel('Você chegou ao 2048!'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultPanel), findsNothing);
    expect(p.best, greaterThanOrEqualTo(2048));

    await tester.tap(find.byKey(const Key('header-new-game')));
    await tester.pumpAndSettle();
    expect(p.score, 0);
    await backToMenu(tester);
  });

  testWidgets('Termo: acerta a palavra do dia e uma do ilimitado',
      (tester) async {
    await launchApp(tester);
    await openGame(tester, 'Termo');
    final p = providerOf<TermoProvider>(tester);
    while (p.loading) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    Future<void> typeAnswer() async {
      for (final letter in p.answer.split('')) {
        await tapVisible(tester, find.byKey(Key('key-$letter')));
      }
      await tapVisible(tester, find.byKey(const Key('key-ENTER')));
      await tester.pumpAndSettle();
    }

    await typeAnswer();
    expect(p.mode, TermoMode.daily);
    expect(inPanel('Acertou em 1!'), findsOneWidget);
    await tester.tap(find.text('Jogar ilimitado'));
    await tester.pumpAndSettle();
    expect(p.mode, TermoMode.unlimited);

    await typeAnswer();
    expect(inPanel('Acertou em 1!'), findsOneWidget);
    await tester.tap(find.text('Nova palavra'));
    await tester.pumpAndSettle();
    expect(p.guesses, isEmpty);
    await backToMenu(tester);
  });

  testWidgets('Contas: acerta pelo teclado, erra 3 vezes e volta',
      (tester) async {
    await launchApp(tester);
    await openGame(tester, 'Contas');
    await tapVisible(tester, find.text('× Multiplicação'));
    await tapVisible(tester, find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Contas • Multiplicação 1'), findsOneWidget);

    final p = providerOf<ContasProvider>(tester);
    Future<void> type(int value) async {
      for (final digit in '$value'.split('')) {
        await tapVisible(tester, find.byKey(Key('tecla-$digit')));
      }
      await tapVisible(tester, find.byKey(const Key('tecla-ok')));
      await tester.pumpAndSettle();
    }

    for (var i = 0; i < 3; i++) {
      await type(p.problem!.answer);
    }
    expect(p.score, 30);
    for (var i = 0; i < 3; i++) {
      await type(p.problem!.answer + 1);
      if (i < 2) {
        // Espera a pausa contra toque duplo do "Continuar".
        await tester.pump(const Duration(milliseconds: 400));
        await tapVisible(tester, find.text('Continuar'));
        await tester.pumpAndSettle();
      }
    }
    expect(inPanel('Novo recorde!'), findsOneWidget);
    await backToMenu(tester);
  });

  testWidgets(
    'Xadrez: mate do louco em dois jogadores e uma partida contra o computador',
    (tester) async {
      await launchApp(tester);
      await openGame(tester, 'Xadrez');

      await tester.tap(find.text('Dois jogadores'));
      await tester.pump();
      await tester.tap(find.text('Jogar!'));
      await tester.pumpAndSettle();
      for (final square in ['f2', 'f3', 'e7', 'e5', 'g2', 'g4', 'd8', 'h4']) {
        await tester.tap(find.byKey(Key('sq-${squareOf(square)}')));
        await tester.pumpAndSettle();
      }
      expect(inPanel('Xeque-mate!'), findsOneWidget);
      expect(inPanel('Jogador 2 venceu!'), findsOneWidget);
      await tester.tap(find.text('Trocar jogadores'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fácil'));
      await tester.pump();
      await tester.tap(find.text('Jogar!'));
      await tester.pumpAndSettle();
      expect(find.text('Xadrez • Fácil'), findsOneWidget);
      final p = providerOf<XadrezProvider>(tester);
      var humanMoves = 0;
      var pumps = 0;
      while (find.byType(ResultPanel).evaluate().isEmpty && humanMoves < 40) {
        if (p.isComputerTurn || p.aiThinking) {
          if (pumps++ > 3000) fail('O computador de Xadrez não jogou a tempo');
          await tester.pump(const Duration(milliseconds: 100));
          continue;
        }
        final move = p.game.legalMoves.first;
        final isPromotion =
            p.game.legalMoves
                .where((m) => m.from == move.from && m.to == move.to)
                .length >
            1;
        await tester.tap(find.byKey(Key('sq-${move.from}')));
        await tester.pump();
        await tester.tap(find.byKey(Key('sq-${move.to}')));
        await tester.pump();
        if (isPromotion) {
          await tester.tap(find.byKey(const Key('promo-5')));
          await tester.pump();
        }
        humanMoves++;
      }
      expect(humanMoves, greaterThan(0));
      await tester.pumpAndSettle();
      await backToMenu(tester);
    },
  );

  testWidgets('Damas: dois jogadores até o fim', (tester) async {
    await launchApp(tester);
    await openGame(tester, 'Damas');

    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    final p = providerOf<DamasProvider>(tester);
    var moves = 0;
    while (find.byType(ResultPanel).evaluate().isEmpty) {
      if (moves++ >= 400) fail('A partida de Damas não terminou em 400 lances');
      for (final square in p.game.legalMoves.first.path) {
        await tester.tap(find.byKey(Key('sq-$square')));
        await tester.pump();
      }
    }
    await tester.pumpAndSettle();
    expect(find.text('Jogar de novo'), findsOneWidget);
    await backToMenu(tester);
  });
}

Future<void> backToMenuAfterDialog(WidgetTester tester) async {
  await tester.tap(find.text('Sair'));
  await steps(tester);
  expect(find.text(_menuSubtitle), findsOneWidget);
}
