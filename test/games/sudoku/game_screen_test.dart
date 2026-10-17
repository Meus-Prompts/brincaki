// test/games/sudoku/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/sudoku/models/difficulty.dart';
import 'package:brincaki/games/sudoku/models/game_state.dart';
import 'package:brincaki/games/sudoku/providers/game_provider.dart';
import 'package:brincaki/games/sudoku/screens/game_screen.dart';
import 'package:brincaki/games/sudoku/widgets/sudoku_cell_widget.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/result_panel.dart';

import 'fixtures.dart';

const _sizes = [Size(360, 740), Size(320, 568)];

/// Menu de mentira que abre o Sudoku como o menu de verdade: provider no
/// GameShell, tema da paleta.
Future<void> openSudoku(WidgetTester tester, {Size size = const Size(360, 740)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
                    wrapProvider: (child) => ChangeNotifierProvider(
                      create: (_) => SudokuProvider(random: Random(3)),
                      child: child,
                    ),
                    theme: kSudokuPalette.theme,
                    home: (_) => const SudokuScreen(),
                  ),
                ),
              ),
              child: const Text('menu'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('menu'));
  await tester.pumpAndSettle();
}

SudokuProvider providerOf(WidgetTester tester) =>
    tester.element(find.byType(SudokuScreen)).read<SudokuProvider>();

/// Avança o relógio em passos (o cronômetro impede o pumpAndSettle).
Future<void> steps(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Fecha tudo, para o provider (e o cronômetro) ser descartado.
Future<void> closeAll(WidgetTester tester) => tester.pumpWidget(const SizedBox());

Future<void> startGame(WidgetTester tester, [String level = 'Fácil']) async {
  await tester.tap(find.text(level));
  await tester.pump();
  await tester.tap(find.text('Jogar!'));
  await steps(tester);
}

Future<void> tapCell(WidgetTester tester, int row, int col) async {
  await tester.tap(find.byKey(Key('cell-$row-$col')));
  await tester.pump();
}

Future<void> tapPad(WidgetTester tester, int number) async {
  await tester.tap(find.byKey(Key('pad-$number')));
  await tester.pump();
}

/// Preenche pela tela, lendo a solução do provider, todas as casas vazias
/// menos as [keep] últimas.
Future<void> fillByTapping(WidgetTester tester, {int keep = 0}) async {
  final p = providerOf(tester);
  final cells = emptyCells(p.board!);
  for (final (r, c) in cells.take(cells.length - keep)) {
    await tapCell(tester, r, c);
    await tapPad(tester, p.board!.solution[r][c]);
  }
}

/// Resolve direto pelo provider (mais rápido que tocar em tudo).
Future<void> solveQuickly(WidgetTester tester) async {
  final p = providerOf(tester);
  for (final (r, c) in emptyCells(p.board!)) {
    p.selectCell(r, c);
    p.enterNumber(p.board!.solution[r][c]);
  }
  await steps(tester);
}

void main() {
  for (final size in _sizes) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('$label: fluxo completo — setup, partida, resultado e botões', (tester) async {
      await openSudoku(tester, size: size);

      // Tela de início.
      expect(find.text('Sudoku'), findsNWidgets(2)); // AppBar e cabeçalho
      expect(find.text('🔢'), findsOneWidget);
      expect(find.text('Dificuldade'), findsOneWidget);
      for (final d in Difficulty.values) {
        expect(find.text(d.name), findsOneWidget);
      }
      expect(find.byIcon(Icons.timer_outlined), findsNothing);
      expect(tester.takeException(), isNull);

      // Escolhe Médio e começa.
      await startGame(tester, 'Médio');
      final p = providerOf(tester);
      expect(p.phase, SudokuPhase.playing);
      expect(p.difficulty, Difficulty.medium);
      expect(find.text('Sudoku • Médio'), findsOneWidget);
      expect(find.text('Dificuldade'), findsNothing);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.byType(ResultPanel), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('00:02'), findsOneWidget);

      // Preenche tudo tocando nas casas e no teclado.
      await fillByTapping(tester, keep: 1);
      expect(p.phase, SudokuPhase.playing);
      final (r, c) = emptyCells(p.board!).single;
      final last = p.board!.solution[r][c];
      expect(find.byKey(Key('pad-$last')), findsOneWidget);
      await tapCell(tester, r, c);
      await tapPad(tester, last);
      await steps(tester);

      // Resultado: teclado e controles somem, cronômetro para.
      expect(p.phase, SudokuPhase.solved);
      expect(find.byType(ResultPanel), findsOneWidget);
      expect(find.text('🏆'), findsOneWidget);
      expect(find.text('Parabéns!'), findsOneWidget);
      expect(find.text('Tempo: 00:02'), findsOneWidget);
      expect(find.byKey(const Key('pad-1')), findsNothing);
      expect(find.text('Apagar'), findsNothing);
      expect(find.text('Sudoku • Médio'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Tempo: 00:02'), findsOneWidget);
      expect(find.text('00:02'), findsOneWidget);

      // Jogar de novo: nova partida na mesma dificuldade.
      final solvedBoard = p.board;
      await tester.tap(find.text('Jogar de novo'));
      await steps(tester);
      expect(p.phase, SudokuPhase.playing);
      expect(p.board, isNot(same(solvedBoard)));
      expect(find.text('Sudoku • Médio'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.byType(ResultPanel), findsNothing);

      // Mudar dificuldade: volta ao setup com a última escolhida marcada.
      await solveQuickly(tester);
      await tester.tap(find.text('Mudar dificuldade'));
      await steps(tester);
      expect(p.phase, SudokuPhase.setup);
      expect(find.text('Dificuldade'), findsOneWidget);
      expect(find.text('Sudoku'), findsNWidgets(2));
      final medium = tester.widget<ChoiceChip>(
        find.ancestor(of: find.text('Médio'), matching: find.byType(ChoiceChip)),
      );
      expect(medium.selected, isTrue);

      // E dá para começar outra, numa dificuldade diferente.
      await startGame(tester, 'Master');
      expect(find.text('Sudoku • Master'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await closeAll(tester);
    });

    testWidgets('$label: voltar no meio da partida pede confirmação', (tester) async {
      await openSudoku(tester, size: size);
      await startGame(tester);

      await tester.tap(find.byTooltip('Voltar ao menu'));
      await steps(tester);
      expect(find.text('Sair do jogo?'), findsOneWidget);
      await tester.tap(find.text('Continuar jogando'));
      await steps(tester);
      expect(find.text('Sair do jogo?'), findsNothing);
      expect(find.text('Sudoku • Fácil'), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar ao menu'));
      await steps(tester);
      await tester.tap(find.text('Sair'));
      await steps(tester);
      expect(find.text('menu'), findsOneWidget);
      expect(find.byType(SudokuScreen), findsNothing);
      // O provider foi descartado junto com o jogo: nenhum timer pendente.
    });
  }

  testWidgets('voltar na tela de início sai direto', (tester) async {
    await openSudoku(tester);
    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    expect(find.text('Sair do jogo?'), findsNothing);
    expect(find.text('menu'), findsOneWidget);
  });

  testWidgets('voltar depois de resolver sai sem confirmação', (tester) async {
    await openSudoku(tester);
    await startGame(tester);
    await solveQuickly(tester);
    expect(find.text('Parabéns!'), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar ao menu'));
    await steps(tester);
    expect(find.text('Sair do jogo?'), findsNothing);
    expect(find.text('menu'), findsOneWidget);
  });

  testWidgets('"voltar" do sistema na partida pede confirmação', (tester) async {
    await openSudoku(tester);
    await startGame(tester);

    await tester.binding.handlePopRoute();
    await steps(tester);
    expect(find.text('Sair do jogo?'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await steps(tester);
    expect(find.text('menu'), findsOneWidget);
  });

  group('controles', () {
    testWidgets('número errado fica vermelho e Apagar limpa a casa', (tester) async {
      await openSudoku(tester);
      await startGame(tester);
      final p = providerOf(tester);
      final (row, col) = emptyCells(p.board!).first;
      final fixed = [
        for (var c = 0; c < 9; c++)
          if (p.board!.getCell(row, c).isFixed) p.board!.getCell(row, c).value,
      ].first;

      await tapCell(tester, row, col);
      await tapPad(tester, fixed);
      expect(p.board!.getCell(row, col).isError, isTrue);
      final cellText = find.descendant(
        of: find.byKey(Key('cell-$row-$col')),
        matching: find.text('$fixed'),
      );
      expect(tester.widget<Text>(cellText).style!.color, kSudokuError);

      await tapCell(tester, row, col);
      await tester.tap(find.byTooltip('Apagar'));
      await tester.pump();
      expect(p.board!.getCell(row, col).isEmpty, isTrue);
      expect(cellText, findsNothing);
      await closeAll(tester);
    });

    testWidgets('modo número-primeiro: escolhe o número e toca nas casas', (tester) async {
      await openSudoku(tester);
      await startGame(tester);
      final p = providerOf(tester);

      expect(find.text('Casa'), findsOneWidget);
      await tester.tap(find.byTooltip('Casa'));
      await tester.pump();
      expect(p.numberFirstMode, isTrue);
      expect(find.text('Número'), findsOneWidget);

      final (r, c) = emptyCells(p.board!).first;
      final n = p.board!.solution[r][c];
      final remaining = p.getRemainingCount(n);
      await tapPad(tester, n);
      expect(p.selectedNumber, n);
      await tapCell(tester, r, c);
      expect(p.board!.getCell(r, c).value, n);
      // A tecla mostra quantos ainda faltam.
      expect(
        find.descendant(of: find.byKey(Key('pad-$n')), matching: find.text('${remaining - 1}')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Número'));
      await tester.pump();
      expect(p.numberFirstMode, isFalse);
      expect(p.selectedNumber, isNull);
      await closeAll(tester);
    });

    testWidgets('número completo some do teclado', (tester) async {
      await openSudoku(tester);
      await startGame(tester);
      final p = providerOf(tester);
      // Completa o número que menos falta.
      final n = [
        for (var i = 1; i <= 9; i++) i,
      ].reduce((a, b) => p.getRemainingCount(a) <= p.getRemainingCount(b) ? a : b);
      for (final (r, c) in emptyCells(p.board!)) {
        if (p.board!.solution[r][c] != n) continue;
        await tapCell(tester, r, c);
        await tapPad(tester, n);
      }
      expect(p.isNumberComplete(n), isTrue);
      expect(find.byKey(Key('pad-$n')), findsNothing);
      await closeAll(tester);
    });

    testWidgets('Dica preenche a casa e acaba depois de 3', (tester) async {
      await openSudoku(tester);
      await startGame(tester);
      final p = providerOf(tester);
      expect(find.text('Dica (3)'), findsOneWidget);

      for (var used = 1; used <= 3; used++) {
        final (r, c) = emptyCells(p.board!).first;
        await tapCell(tester, r, c);
        await tester.tap(find.byTooltip('Dica (${4 - used})'));
        await tester.pump();
        expect(p.board!.getCell(r, c).value, p.board!.solution[r][c]);
        expect(find.text('Dica (${3 - used})'), findsOneWidget);
      }

      final button = tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(Icons.lightbulb_outline), matching: find.byType(IconButton)),
      );
      expect(button.onPressed, isNull);
      await closeAll(tester);
    });

    testWidgets('Novo jogo pede confirmação e troca o tabuleiro', (tester) async {
      await openSudoku(tester);
      await startGame(tester, 'Difícil');
      final p = providerOf(tester);
      final first = p.board;
      await tester.pump(const Duration(seconds: 3));

      await tester.tap(find.byTooltip('Novo jogo'));
      await steps(tester);
      expect(find.text('Novo jogo?'), findsOneWidget);
      await tester.tap(find.text('Continuar jogando'));
      await steps(tester);
      expect(p.board, same(first));

      await tester.tap(find.byTooltip('Novo jogo'));
      await steps(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Novo jogo'));
      await steps(tester);
      expect(p.board, isNot(same(first)));
      expect(p.difficulty, Difficulty.hard);
      expect(find.text('00:00'), findsOneWidget);
      await closeAll(tester);
    });

    testWidgets('casa selecionada, mesma linha e mesmo número ficam destacados', (tester) async {
      await openSudoku(tester);
      await startGame(tester);
      final p = providerOf(tester);
      // Uma casa fixa: destaca as outras com o mesmo número.
      late int row, col;
      search:
      for (row = 0; row < 9; row++) {
        for (col = 0; col < 9; col++) {
          if (p.board!.getCell(row, col).isFixed) break search;
        }
      }
      await tapCell(tester, row, col);

      SudokuCellWidget cellAt(int r, int c) => tester.widget<SudokuCellWidget>(
        find.descendant(of: find.byKey(Key('cell-$r-$c')), matching: find.byType(SudokuCellWidget)),
      );
      expect(cellAt(row, col).isSelected, isTrue);
      expect(cellAt(row, (col + 4) % 9).isHighlighted, isTrue);
      final value = p.board!.getCell(row, col).value;
      final twin = [
        for (var r = 0; r < 9; r++)
          for (var c = 0; c < 9; c++)
            if ((r, c) != (row, col) && p.board!.getCell(r, c).value == value) (r, c),
      ].first;
      expect(cellAt(twin.$1, twin.$2).isSameNumber, isTrue);
      await closeAll(tester);
    });
  });
}
