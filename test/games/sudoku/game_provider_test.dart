// test/games/sudoku/game_provider_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/sudoku/models/difficulty.dart';
import 'package:brincaki/games/sudoku/models/game_state.dart';
import 'package:brincaki/games/sudoku/providers/game_provider.dart';

import 'fixtures.dart';

/// Preenche certo todas as casas vazias menos as [keep] últimas (modo
/// célula-primeiro).
void fillAllBut(SudokuProvider p, int keep) {
  final cells = emptyCells(p.board!);
  for (final (r, c) in cells.take(cells.length - keep)) {
    p.selectCell(r, c);
    p.enterNumber(p.board!.solution[r][c]);
  }
}

/// Uma casa vazia e um número fixo da mesma linha (que sempre conflita).
(int, int, int) conflictFor(SudokuProvider p) {
  final (row, col) = emptyCells(p.board!).first;
  final fixed = [
    for (var c = 0; c < 9; c++)
      if (p.board!.getCell(row, c).isFixed) p.board!.getCell(row, c).value,
  ].first;
  return (row, col, fixed);
}

(int, int) firstFixed(SudokuProvider p) {
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      if (p.board!.getCell(r, c).isFixed) return (r, c);
    }
  }
  throw StateError('sem casa fixa');
}

void main() {
  late SudokuProvider p;
  var notifications = 0;

  setUp(() {
    p = SudokuProvider(random: Random(7));
    notifications = 0;
    p.addListener(() => notifications++);
  });

  tearDown(() => p.dispose());

  group('estado inicial', () {
    test('começa no setup, sem tabuleiro e sem cronômetro', () {
      expect(p.phase, SudokuPhase.setup);
      expect(p.board, isNull);
      expect(p.difficulty, Difficulty.easy);
      expect(p.hintsRemaining, kSudokuHints);
      expect(p.elapsedSeconds, 0);
      expect(p.formattedTime, '00:00');
      expect(p.isComplete, isFalse);
      expect(p.isPlaying, isFalse);
      expect(p.hasSelection, isFalse);
      expect(p.numberFirstMode, isFalse);
      expect(p.selectedNumber, isNull);
      expect(p.timerRunning, isFalse);
    });

    test('sem tabuleiro, todo número ainda falta 9 vezes', () {
      for (var n = 1; n <= 9; n++) {
        expect(p.getRemainingCount(n), 9);
        expect(p.isNumberComplete(n), isFalse);
      }
    });

    test('jogadas fora da partida são ignoradas', () {
      p.selectCell(0, 0);
      p.selectNumber(1);
      p.enterNumber(1);
      p.clearCell();
      p.useHint();
      p.toggleInputMode();
      p.newGame();
      p.exitToSetup();
      expect(p.phase, SudokuPhase.setup);
      expect(p.board, isNull);
      expect(p.hasSelection, isFalse);
      expect(p.numberFirstMode, isFalse);
      expect(notifications, 0);
    });
  });

  group('start / newGame / exitToSetup', () {
    for (final difficulty in Difficulty.values) {
      test('start(${difficulty.name}) começa a partida com a faixa certa de casas vazias', () {
        p.start(difficulty);
        expect(p.phase, SudokuPhase.playing);
        expect(p.isPlaying, isTrue);
        expect(p.difficulty, difficulty);
        expect(p.timerRunning, isTrue);
        expect(
          emptyCells(p.board!).length,
          inInclusiveRange(difficulty.minEmpty, difficulty.maxEmpty),
        );
        expect(notifications, 1);
      });
    }

    test('start no meio da partida é ignorado', () {
      p.start(Difficulty.easy);
      final board = p.board;
      p.start(Difficulty.master);
      expect(p.board, same(board));
      expect(p.difficulty, Difficulty.easy);
    });

    test('newGame troca o tabuleiro e zera dicas, seleção e tempo', () {
      p.start(Difficulty.medium);
      final old = p.board;
      final (r, c) = emptyCells(old!).first;
      p.selectCell(r, c);
      p.useHint();
      expect(p.hintsRemaining, kSudokuHints - 1);

      p.newGame();
      expect(p.board, isNot(same(old)));
      expect(p.difficulty, Difficulty.medium);
      expect(p.hintsRemaining, kSudokuHints);
      expect(p.hasSelection, isFalse);
      expect(p.elapsedSeconds, 0);
      expect(p.phase, SudokuPhase.playing);
    });

    test('exitToSetup volta à escolha, guarda a dificuldade e para o cronômetro', () {
      p.start(Difficulty.hard);
      p.selectCell(0, 0);
      p.exitToSetup();
      expect(p.phase, SudokuPhase.setup);
      expect(p.board, isNull);
      expect(p.hasSelection, isFalse);
      expect(p.difficulty, Difficulty.hard);
      expect(p.timerRunning, isFalse);
    });
  });

  group('modo célula-primeiro', () {
    setUp(() => p.start(Difficulty.easy));

    test('selectCell só seleciona', () {
      final (r, c) = emptyCells(p.board!).first;
      p.selectCell(r, c);
      expect(p.selectedRow, r);
      expect(p.selectedCol, c);
      expect(p.hasSelection, isTrue);
      expect(p.board!.getCell(r, c).isEmpty, isTrue);
    });

    test('selectNumber escreve na casa selecionada e solta a seleção', () {
      final (r, c) = emptyCells(p.board!).first;
      final right = p.board!.solution[r][c];
      p.selectCell(r, c);
      p.selectNumber(right);
      expect(p.board!.getCell(r, c).value, right);
      expect(p.board!.getCell(r, c).isError, isFalse);
      expect(p.hasSelection, isFalse);
      expect(p.selectedNumber, isNull);
    });

    test('enterNumber sem casa selecionada não faz nada', () {
      final board = p.board;
      p.enterNumber(5);
      p.selectNumber(5);
      expect(p.board, same(board));
    });

    test('enterNumber numa casa fixa não muda nada', () {
      final (r, c) = firstFixed(p);
      final value = p.board!.getCell(r, c).value;
      p.selectCell(r, c);
      p.enterNumber(value == 9 ? 1 : value + 1);
      expect(p.board!.getCell(r, c).value, value);
      expect(p.hasSelection, isTrue);
    });

    test('número repetido na linha fica com erro', () {
      final (r, c, fixed) = conflictFor(p);
      p.selectCell(r, c);
      p.enterNumber(fixed);
      expect(p.board!.getCell(r, c).value, fixed);
      expect(p.board!.getCell(r, c).isError, isTrue);
    });

    test('trocar o número errado pelo certo tira o vermelho da outra casa', () {
      // Duas casas vazias na mesma linha.
      final empties = emptyCells(p.board!);
      final (row, colA) = empties.first;
      final colB = empties.firstWhere((e) => e.$1 == row && e.$2 != colA).$2;
      final rightA = p.board!.solution[row][colA];
      final rightB = p.board!.solution[row][colB];

      p.selectCell(row, colA);
      p.enterNumber(rightB);
      p.selectCell(row, colB);
      p.enterNumber(rightB);
      expect(p.board!.getCell(row, colA).isError, isTrue);
      expect(p.board!.getCell(row, colB).isError, isTrue);

      p.selectCell(row, colA);
      p.enterNumber(rightA);
      expect(p.board!.getCell(row, colA).isError, isFalse);
      expect(p.board!.getCell(row, colB).isError, isFalse);
    });
  });

  group('modo número-primeiro', () {
    setUp(() {
      p.start(Difficulty.easy);
      p.toggleInputMode();
    });

    test('toggleInputMode alterna o modo e limpa a seleção', () {
      expect(p.numberFirstMode, isTrue);
      p.selectNumber(3);
      p.selectCell(0, 0);
      p.toggleInputMode();
      expect(p.numberFirstMode, isFalse);
      expect(p.selectedNumber, isNull);
      expect(p.hasSelection, isFalse);
    });

    test('selectNumber escolhe e, de novo, solta o número', () {
      p.selectNumber(4);
      expect(p.selectedNumber, 4);
      p.selectNumber(6);
      expect(p.selectedNumber, 6);
      p.selectNumber(6);
      expect(p.selectedNumber, isNull);
    });

    test('sem número escolhido, tocar na casa só seleciona', () {
      final (r, c) = emptyCells(p.board!).first;
      p.selectCell(r, c);
      expect(p.board!.getCell(r, c).isEmpty, isTrue);
      expect(p.selectedRow, r);
    });

    test('com número escolhido, tocar na casa escreve e mantém o número', () {
      final (r, c) = emptyCells(p.board!).first;
      final right = p.board!.solution[r][c];
      p.selectNumber(right);
      p.selectCell(r, c);
      expect(p.board!.getCell(r, c).value, right);
      expect(p.selectedRow, r);
      expect(p.selectedCol, c);
      expect(p.selectedNumber, right);
    });

    test('tocar numa casa fixa não escreve nada', () {
      final (r, c) = firstFixed(p);
      final value = p.board!.getCell(r, c).value;
      p.selectNumber(value == 9 ? 1 : value + 1);
      p.selectCell(r, c);
      expect(p.board!.getCell(r, c).value, value);
    });

    test('ao completar um número, passa para o próximo que ainda falta', () {
      // Completa o número que menos falta.
      final number = [
        for (var n = 1; n <= 9; n++) n,
      ].reduce((a, b) => p.getRemainingCount(a) <= p.getRemainingCount(b) ? a : b);
      final targets = [
        for (final (r, c) in emptyCells(p.board!))
          if (p.board!.solution[r][c] == number) (r, c),
      ];
      p.selectNumber(number);
      for (final (r, c) in targets) {
        p.selectCell(r, c);
      }
      expect(p.isNumberComplete(number), isTrue);
      final next = [for (var n = 1; n <= 9; n++) n].firstWhere((n) => !p.isNumberComplete(n));
      expect(p.selectedNumber, next);
    });

    test('resolver pelo modo número-primeiro termina a partida', () {
      for (final (r, c) in emptyCells(p.board!)) {
        final n = p.board!.solution[r][c];
        // Tocar de novo no número escolhido o soltaria.
        if (p.selectedNumber != n) p.selectNumber(n);
        p.selectCell(r, c);
      }
      expect(p.phase, SudokuPhase.solved);
      expect(p.timerRunning, isFalse);
    });
  });

  group('resolver no modo célula-primeiro', () {
    test('preencher tudo certo resolve, para o cronômetro e bloqueia jogadas', () {
      p.start(Difficulty.easy);
      fillAllBut(p, 0);
      expect(p.phase, SudokuPhase.solved);
      expect(p.isComplete, isTrue);
      expect(p.isPlaying, isFalse);
      expect(p.timerRunning, isFalse);
      for (var n = 1; n <= 9; n++) {
        expect(p.getRemainingCount(n), 0);
        expect(p.isNumberComplete(n), isTrue);
      }

      final board = p.board;
      p.selectCell(0, 0);
      p.selectNumber(1);
      p.clearCell();
      p.useHint();
      p.toggleInputMode();
      expect(p.board, same(board));
      expect(p.numberFirstMode, isFalse);
    });

    test('preenchido mas com conflito não resolve', () {
      p.start(Difficulty.easy);
      fillAllBut(p, 1);
      final (r, c) = emptyCells(p.board!).single;
      final wrong = p.board!.solution[r][c] % 9 + 1;
      p.selectCell(r, c);
      p.enterNumber(wrong);
      expect(p.board!.getCell(r, c).isError, isTrue);
      expect(p.phase, SudokuPhase.playing);
    });

    test('newGame depois de resolver volta a jogar', () {
      p.start(Difficulty.easy);
      fillAllBut(p, 0);
      p.newGame();
      expect(p.phase, SudokuPhase.playing);
      expect(p.timerRunning, isTrue);
    });

    test('exitToSetup depois de resolver volta à escolha', () {
      p.start(Difficulty.easy);
      fillAllBut(p, 0);
      p.exitToSetup();
      expect(p.phase, SudokuPhase.setup);
    });
  });

  group('contagem que falta', () {
    test('acompanha o que é escrito e apagado', () {
      p.start(Difficulty.easy);
      final (r, c) = emptyCells(p.board!).first;
      final right = p.board!.solution[r][c];
      final before = p.getRemainingCount(right);
      p.selectCell(r, c);
      p.enterNumber(right);
      expect(p.getRemainingCount(right), before - 1);
      p.selectCell(r, c);
      p.clearCell();
      expect(p.getRemainingCount(right), before);
    });
  });

  group('clearCell', () {
    setUp(() => p.start(Difficulty.easy));

    test('apaga a casa e tira o vermelho', () {
      final (r, c, fixed) = conflictFor(p);
      p.selectCell(r, c);
      p.enterNumber(fixed);
      p.selectCell(r, c);
      p.clearCell();
      expect(p.board!.getCell(r, c).isEmpty, isTrue);
      expect(p.board!.getCell(r, c).isError, isFalse);
      expect(p.hasSelection, isTrue);
    });

    test('sem seleção ou em casa fixa não faz nada', () {
      final board = p.board;
      p.clearCell();
      expect(p.board, same(board));

      final (r, c) = firstFixed(p);
      p.selectCell(r, c);
      p.clearCell();
      expect(p.board, same(board));
    });
  });

  group('useHint', () {
    setUp(() => p.start(Difficulty.easy));

    test('preenche a casa com a solução e gasta uma dica', () {
      final (r, c) = emptyCells(p.board!).first;
      p.selectCell(r, c);
      p.useHint();
      expect(p.hintsRemaining, kSudokuHints - 1);
      expect(p.board!.getCell(r, c).value, p.board!.solution[r][c]);
      expect(p.board!.getCell(r, c).isError, isFalse);
    });

    test('dicas acabam depois de 3 usos', () {
      for (var i = 0; i < kSudokuHints + 1; i++) {
        final (r, c) = emptyCells(p.board!).first;
        p.selectCell(r, c);
        p.useHint();
      }
      expect(p.hintsRemaining, 0);
      expect(
        emptyCells(p.board!).length,
        greaterThanOrEqualTo(Difficulty.easy.minEmpty - kSudokuHints),
      );
    });

    test('sem dicas, a quarta não preenche nada', () {
      for (var i = 0; i < kSudokuHints; i++) {
        final (r, c) = emptyCells(p.board!).first;
        p.selectCell(r, c);
        p.useHint();
      }
      final (r, c) = emptyCells(p.board!).first;
      p.selectCell(r, c);
      p.useHint();
      expect(p.board!.getCell(r, c).isEmpty, isTrue);
    });

    test('sem seleção, em casa fixa ou já preenchida não gasta dica', () {
      p.useHint();
      final (fr, fc) = firstFixed(p);
      p.selectCell(fr, fc);
      p.useHint();

      final (r, c, fixed) = conflictFor(p);
      p.selectCell(r, c);
      p.enterNumber(fixed);
      p.selectCell(r, c);
      p.useHint();
      expect(p.board!.getCell(r, c).value, fixed);
      expect(p.hintsRemaining, kSudokuHints);
    });

    test('a dica na última casa resolve a partida', () {
      fillAllBut(p, 1);
      final (r, c) = emptyCells(p.board!).single;
      p.selectCell(r, c);
      p.useHint();
      expect(p.phase, SudokuPhase.solved);
      expect(p.timerRunning, isFalse);
    });
  });

  group('cronômetro', () {
    testWidgets('conta os segundos e formata mm:ss', (tester) async {
      final timed = SudokuProvider(random: Random(1))..start(Difficulty.easy);
      await tester.pump(const Duration(seconds: 5));
      expect(timed.elapsedSeconds, 5);
      expect(timed.formattedTime, '00:05');
      await tester.pump(const Duration(seconds: 70));
      expect(timed.formattedTime, '01:15');
      timed.dispose();
    });

    testWidgets('para ao resolver', (tester) async {
      final timed = SudokuProvider(random: Random(1))..start(Difficulty.easy);
      await tester.pump(const Duration(seconds: 3));
      fillAllBut(timed, 0);
      await tester.pump(const Duration(seconds: 10));
      expect(timed.elapsedSeconds, 3);
      timed.dispose();
    });

    testWidgets('para ao voltar ao setup e recomeça do zero no newGame', (tester) async {
      final timed = SudokuProvider(random: Random(1))..start(Difficulty.easy);
      await tester.pump(const Duration(seconds: 4));
      timed.exitToSetup();
      await tester.pump(const Duration(seconds: 4));
      expect(timed.elapsedSeconds, 4);

      timed.start(Difficulty.easy);
      expect(timed.elapsedSeconds, 0);
      await tester.pump(const Duration(seconds: 2));
      timed.newGame();
      await tester.pump(const Duration(seconds: 1));
      expect(timed.elapsedSeconds, 1);
      timed.dispose();
    });

    testWidgets('dispose com o cronômetro rodando cancela o timer', (tester) async {
      final timed = SudokuProvider(random: Random(1))..start(Difficulty.easy);
      expect(timed.timerRunning, isTrue);
      timed.dispose();
      expect(timed.timerRunning, isFalse);
      // Se o timer seguisse, notifyListeners num provider descartado daria erro.
      await tester.pump(const Duration(seconds: 3));
      expect(timed.elapsedSeconds, 0);
    });
  });
}
