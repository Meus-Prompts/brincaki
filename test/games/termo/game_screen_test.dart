// test/games/termo/game_screen_test.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/termo/data/daily_store.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/models/game_state.dart';
import 'package:brincaki/games/termo/providers/game_provider.dart';
import 'package:brincaki/games/termo/screens/game_screen.dart';
import 'package:brincaki/games/termo/widgets/guess_grid.dart';
import 'package:brincaki/games/termo/widgets/termo_keyboard.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/result_panel.dart';

class _Store implements DailyStore {
  DailyState? state;
  @override
  Future<DailyState?> load() async => state;
  @override
  Future<void> save(DailyState s) async => state = s;
}

final _bank = WordBank(
  valid: {
    'CARRO': 'CARRO', 'PEDRA': 'PEDRA', 'AVIAO': 'AVIÃO',
    'PORTA': 'PORTA', 'MESAS': 'MESAS',
  },
  answers: ['CARRO', 'PEDRA', 'AVIAO'],
);

const _sizes = [Size(360, 740), Size(320, 568)];

String _sizeName(Size s) => '${s.width.toInt()}x${s.height.toInt()}';

/// Menu de mentira que abre o Termo do mesmo jeito que o menu de verdade.
Future<TermoProvider> pumpGame(
  WidgetTester tester, {
  Size size = const Size(360, 740),
  Future<WordBank>? bank,
  DailyStore? store,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = TermoProvider(
    bank: bank ?? Future.value(_bank),
    store: store ?? _Store(),
    now: () => DateTime(2026, 10, 4),
    random: Random(3),
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
                  theme: kTermoPalette.theme,
                  wrapProvider: (child) =>
                      ChangeNotifierProvider.value(value: provider, child: child),
                  home: (_) => const TermoScreen(),
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

/// Deixa terminar a animação de revelar.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> tapWord(WidgetTester tester, String word) async {
  for (final letter in word.split('')) {
    await tester.tap(find.byKey(Key('key-$letter')));
  }
  await tester.tap(find.byKey(const Key('key-ENTER')));
  await settle(tester);
}

String wrongWord(TermoProvider p) => ['PORTA', 'MESAS'].firstWhere((w) => w != p.answer);

Future<void> loseAll(WidgetTester tester, TermoProvider p) async {
  final wrong = wrongWord(p);
  for (var i = 0; i < TermoProvider.maxGuesses; i++) {
    await tapWord(tester, wrong);
  }
  expect(p.phase, TermoPhase.lost);
}

Future<void> goUnlimited(WidgetTester tester, TermoProvider p) async {
  await tester.tap(find.text('Ilimitado'));
  await tester.pumpAndSettle();
  expect(p.mode, TermoMode.unlimited);
}

Finder _inPanel(String text) =>
    find.descendant(of: find.byType(ResultPanel), matching: find.text(text));

void main() {
  testWidgets('abre com título, seletor de modo, grade, teclado e fundo da paleta',
      (tester) async {
    await pumpGame(tester);
    expect(find.text('Termo'), findsOneWidget);
    expect(find.text('Palavra do dia'), findsOneWidget);
    expect(find.text('Ilimitado'), findsOneWidget);
    expect(find.byType(GuessGrid), findsOneWidget);
    expect(find.byType(TermoKeyboard), findsOneWidget);
    expect(find.byType(ResultPanel), findsNothing);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, kTermoPalette.background);
  });

  testWidgets('mostra "Carregando palavras..." até o banco chegar', (tester) async {
    final words = Completer<WordBank>();
    final p = await pumpGame(tester, bank: words.future);
    expect(find.text('Carregando palavras...'), findsOneWidget);
    expect(find.byType(TermoKeyboard), findsNothing);
    expect(find.byType(GuessGrid), findsNothing);

    words.complete(_bank);
    await tester.pumpAndSettle();
    expect(p.loading, isFalse);
    expect(find.text('Carregando palavras...'), findsNothing);
    expect(find.byType(TermoKeyboard), findsOneWidget);
  });

  group('mensagens de erro no topo', () {
    testWidgets('palavra curta', (tester) async {
      await pumpGame(tester);
      await tapWord(tester, 'CAR');
      expect(find.text('Só palavras com 5 letras'), findsOneWidget);
    });

    testWidgets('palavra inválida', (tester) async {
      final p = await pumpGame(tester);
      await tapWord(tester, 'CARRA'); // 5 letras, mas não está no dicionário
      expect(find.text('Palavra inválida'), findsOneWidget);
      expect(p.guesses, isEmpty);
    });

    testWidgets('fica acima da grade e do teclado', (tester) async {
      await pumpGame(tester);
      await tapWord(tester, 'CARRA');
      final warning = tester.getRect(find.text('Palavra inválida'));
      expect(warning.bottom, lessThanOrEqualTo(tester.getRect(find.byType(GuessGrid)).top));
      expect(warning.bottom, lessThan(tester.getRect(find.byKey(const Key('key-Q'))).top));
    });

    testWidgets('some ao apagar e digitar de novo', (tester) async {
      await pumpGame(tester);
      await tapWord(tester, 'CARRA');
      await tester.tap(find.byKey(const Key('key-⌫')));
      await tester.tap(find.byKey(const Key('key-O')));
      await tester.pump();
      expect(find.text('Palavra inválida'), findsNothing);
    });
  });

  group('teclado físico', () {
    testWidgets('letras, apagar e Enter', (tester) async {
      final p = await pumpGame(tester);
      final wrong = wrongWord(p);
      LogicalKeyboardKey key(String letter) =>
          LogicalKeyboardKey.findKeyByKeyId(letter.toLowerCase().codeUnitAt(0))!;

      for (final letter in wrong.split('')) {
        await tester.sendKeyEvent(key(letter));
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      expect(p.current, wrong.substring(0, 4));
      await tester.sendKeyEvent(key(wrong[4]));
      expect(p.current, wrong);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(p.guesses, [wrong]);
    });

    testWidgets('teclas sem letra são ignoradas', (tester) async {
      final p = await pumpGame(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(p.current, '');
    });

    testWidgets('soltar ou repetir a tecla não digita de novo', (tester) async {
      final p = await pumpGame(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      expect(p.current, 'C');
    });
  });

  for (final size in _sizes) {
    group('palavra do dia em ${_sizeName(size)}', () {
      testWidgets('acertar mostra a vitória e esconde o teclado', (tester) async {
        final p = await pumpGame(tester, size: size);
        await tapWord(tester, wrongWord(p));
        await tapWord(tester, p.answer);
        expect(p.phase, TermoPhase.won);
        expect(_inPanel('🎉'), findsOneWidget);
        expect(_inPanel('Acertou em 2!'), findsOneWidget);
        expect(_inPanel('Volte amanhã para a próxima palavra!'), findsOneWidget);
        expect(find.byType(TermoKeyboard), findsNothing);
        // A palavra do dia não tem botão de nova palavra.
        expect(find.text('Nova palavra'), findsNothing);
        expect(tester.takeException(), isNull);
        expect(tester.getRect(find.byType(ResultPanel)).bottom, lessThanOrEqualTo(size.height));
      });

      testWidgets('errar 6 vezes mostra a resposta', (tester) async {
        final p = await pumpGame(tester, size: size);
        await loseAll(tester, p);
        expect(_inPanel('😢'), findsOneWidget);
        expect(_inPanel('A palavra era: ${p.answerDisplay}'), findsOneWidget);
        expect(_inPanel('Volte amanhã para a próxima palavra!'), findsOneWidget);
        expect(find.byType(TermoKeyboard), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('trocar para ilimitado e voltar restaura o dia terminado',
          (tester) async {
        final p = await pumpGame(tester, size: size);
        await tapWord(tester, p.answer);
        await goUnlimited(tester, p);
        expect(find.byType(ResultPanel), findsNothing);
        expect(find.byType(TermoKeyboard), findsOneWidget);

        await tester.tap(find.text('Palavra do dia'));
        await settle(tester);
        expect(p.mode, TermoMode.daily);
        expect(_inPanel('Acertou em 1!'), findsOneWidget);
      });
    });

    group('ilimitado em ${_sizeName(size)}', () {
      testWidgets('acertar mostra a vitória e Nova palavra recomeça', (tester) async {
        final p = await pumpGame(tester, size: size);
        await goUnlimited(tester, p);
        await tapWord(tester, p.answer);
        expect(_inPanel('Acertou em 1!'), findsOneWidget);
        expect(_inPanel('Volte amanhã para a próxima palavra!'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.tap(_inPanel('Nova palavra'));
        await tester.pumpAndSettle();
        expect(p.phase, TermoPhase.playing);
        expect(p.guesses, isEmpty);
        expect(find.byType(ResultPanel), findsNothing);
        expect(find.byType(TermoKeyboard), findsOneWidget);
      });

      testWidgets('perder mostra a resposta e Nova palavra', (tester) async {
        final p = await pumpGame(tester, size: size);
        await goUnlimited(tester, p);
        await loseAll(tester, p);
        expect(_inPanel('A palavra era: ${p.answerDisplay}'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(tester.getRect(_inPanel('Nova palavra')).bottom, lessThanOrEqualTo(size.height));

        await tester.tap(_inPanel('Nova palavra'));
        await tester.pumpAndSettle();
        expect(p.phase, TermoPhase.playing);
        expect(find.byType(TermoKeyboard), findsOneWidget);
      });

      testWidgets('jogo em andamento cabe na tela', (tester) async {
        final p = await pumpGame(tester, size: size);
        await goUnlimited(tester, p);
        await tapWord(tester, wrongWord(p));
        await tapWord(tester, 'CAR');
        expect(tester.takeException(), isNull);
        expect(tester.getRect(find.byKey(const Key('key-⌫'))).bottom,
            lessThanOrEqualTo(size.height));
      });
    });
  }

  testWidgets('a resposta aparece com acento', (tester) async {
    final p = await pumpGame(
      tester,
      bank: Future.value(WordBank(
        valid: const {'AVIAO': 'AVIÃO', 'PORTA': 'PORTA'},
        answers: const ['AVIAO'],
      )),
    );
    await loseAll(tester, p);
    expect(_inPanel('A palavra era: AVIÃO'), findsOneWidget);
  });

  testWidgets('seta de voltar sai para o menu', (tester) async {
    await pumpGame(tester);
    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsOneWidget);
    expect(find.byType(TermoScreen), findsNothing);
  });

  testWidgets('seta de voltar também funciona com a partida terminada',
      (tester) async {
    final p = await pumpGame(tester);
    await tapWord(tester, p.answer);
    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsOneWidget);
  });
}
