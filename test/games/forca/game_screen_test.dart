// test/games/forca/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/forca/models/game_state.dart';
import 'package:brincaki/games/forca/providers/game_provider.dart';
import 'package:brincaki/games/forca/screens/game_screen.dart';
import 'package:brincaki/games/forca/widgets/hangman_painter.dart';
import 'package:brincaki/games/forca/widgets/letter_keyboard.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/result_panel.dart';
import 'package:brincaki/widgets/solo_setup.dart';

const _menu = 'Menu de teste';

/// Abre a Forca como o menu abre: rota com provider, tema e Navigator próprio.
Future<ForcaProvider> pumpGame(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = ForcaProvider(random: Random(7));
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameShell(
                  wrapProvider: (child) =>
                      ChangeNotifierProvider.value(value: provider, child: child),
                  theme: kForcaPalette.theme,
                  home: (_) => const ForcaScreen(),
                ),
              ),
            ),
            child: const Text(_menu),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text(_menu));
  await tester.pumpAndSettle();
  return provider;
}

Future<void> tapKey(WidgetTester tester, String letter) async {
  final key = find.byKey(ValueKey('tecla-$letter'));
  await tester.ensureVisible(key);
  await tester.pumpAndSettle();
  await tester.tap(key);
  await tester.pumpAndSettle();
}

Future<void> tapButton(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> guessWholeWord(WidgetTester tester, ForcaProvider p) async {
  for (final letter in p.currentWord.split('').toSet()) {
    await tapKey(tester, letter);
  }
}

Future<void> missSixTimes(WidgetTester tester, ForcaProvider p) async {
  final wrong = ForcaProvider.alphabet
      .split('')
      .where((l) => !p.currentWord.contains(l))
      .take(ForcaProvider.maxErrors)
      .toList();
  for (final letter in wrong) {
    await tapKey(tester, letter);
  }
}

Finder resultButton(String label) =>
    find.descendant(of: find.byType(ResultPanel), matching: find.text(label));

void main() {
  for (final size in const [Size(360, 740), Size(320, 568)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('$tag: fluxo completo do setup ao menu', (tester) async {
      final p = await pumpGame(tester, size);

      // Escolha de nível.
      expect(find.byType(SoloSetup), findsOneWidget);
      expect(find.text('Jogo da Forca'), findsNWidgets(2)); // AppBar e cabeçalho
      expect(find.text('🪢'), findsOneWidget);
      expect(find.text('Nível'), findsOneWidget);
      for (var level = 1; level <= 7; level++) {
        expect(find.widgetWithText(ChoiceChip, '$level'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      await tapButton(tester, '3');
      await tapButton(tester, 'Jogar!');
      expect(p.phase, ForcaPhase.playing);
      expect(find.text('Jogo da Forca • Nível 3'), findsOneWidget);
      expect(find.text('Erros: 0 / 6'), findsOneWidget);
      expect(find.byType(HangmanWidget), findsOneWidget);
      expect(find.byType(LetterKeyboard), findsOneWidget);
      expect(find.byType(ResultPanel), findsNothing);
      expect(tester.takeException(), isNull);

      // Acerta a palavra.
      final firstWord = p.currentWord;
      await guessWholeWord(tester, p);
      expect(p.phase, ForcaPhase.won);
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('Parabéns!'), findsOneWidget);
      expect(find.text('Avançando para o nível 4!'), findsOneWidget);
      expect(resultButton('Próxima palavra'), findsOneWidget);
      expect(resultButton('Mudar nível'), findsOneWidget);
      // O teclado some; o boneco e a palavra continuam.
      expect(find.byType(LetterKeyboard), findsNothing);
      expect(find.byType(HangmanWidget), findsOneWidget);
      for (final letter in firstWord.split('')) {
        expect(find.text(letter), findsWidgets);
      }
      expect(tester.takeException(), isNull);

      // Próxima palavra, no nível 4.
      await tapButton(tester, 'Próxima palavra');
      expect(p.level, 4);
      expect(find.text('Jogo da Forca • Nível 4'), findsOneWidget);
      expect(find.byType(ResultPanel), findsNothing);
      expect(find.byType(LetterKeyboard), findsOneWidget);
      expect(find.text('Erros: 0 / 6'), findsOneWidget);

      // Erra seis vezes.
      final lostWord = p.currentWord;
      await missSixTimes(tester, p);
      expect(p.phase, ForcaPhase.lost);
      expect(find.text('Erros: 6 / 6'), findsOneWidget);
      expect(find.text('😢'), findsOneWidget);
      expect(find.text('Que pena...'), findsOneWidget);
      expect(find.text('A palavra era: $lostWord'), findsOneWidget);
      expect(resultButton('Tentar de novo'), findsOneWidget);
      expect(resultButton('Mudar nível'), findsOneWidget);
      expect(find.byType(LetterKeyboard), findsNothing);
      expect(find.byType(HangmanWidget), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tentar de novo: mesmo nível, palavra nova.
      await tapButton(tester, 'Tentar de novo');
      expect(p.phase, ForcaPhase.playing);
      expect(p.level, 4);
      expect(p.currentWord, isNot(lostWord));
      expect(find.text('Jogo da Forca • Nível 4'), findsOneWidget);
      expect(find.text('Erros: 0 / 6'), findsOneWidget);

      // Perde de novo e muda de nível.
      await missSixTimes(tester, p);
      await tapButton(tester, 'Mudar nível');
      expect(p.phase, ForcaPhase.setup);
      expect(find.byType(SoloSetup), findsOneWidget);
      expect(find.text('Jogo da Forca'), findsNWidgets(2));
      // O nível atual já vem marcado.
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '4')).selected, isTrue);

      // Volta ao menu pela seta.
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text(_menu), findsOneWidget);
      expect(find.byType(ForcaScreen), findsNothing);
    });
  }

  testWidgets('sem escolher, começa no nível 1', (tester) async {
    final p = await pumpGame(tester, const Size(360, 740));
    await tapButton(tester, 'Jogar!');
    expect(p.level, 1);
    expect(find.text('Jogo da Forca • Nível 1'), findsOneWidget);
  });

  testWidgets('a palavra mostra só lacunas no começo', (tester) async {
    final p = await pumpGame(tester, const Size(360, 740));
    await tapButton(tester, 'Jogar!');
    final slots = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.text(' '),
    );
    expect(slots, findsNWidgets(p.currentWord.length));
  });

  testWidgets('letra certa aparece na palavra e a tecla fica verde', (tester) async {
    final p = await pumpGame(tester, const Size(360, 740));
    await tapButton(tester, 'Jogar!');
    final letter = p.currentWord[0];
    await tapKey(tester, letter);
    expect(p.letterStates[letter], LetterState.correct);
    // Uma vez na tecla e ao menos uma na palavra.
    expect(find.text(letter), findsAtLeastNWidgets(2));
  });

  testWidgets('erros ficam vermelhos a partir do quarto', (tester) async {
    final p = await pumpGame(tester, const Size(360, 740));
    await tapButton(tester, 'Jogar!');
    final wrong = ForcaProvider.alphabet
        .split('')
        .where((l) => !p.currentWord.contains(l))
        .toList();
    Color errorsColor(int n) => tester.widget<Text>(find.text('Erros: $n / 6')).style!.color!;
    await tapKey(tester, wrong[0]);
    expect(errorsColor(1), const Color(0xFF475569));
    for (final l in wrong.sublist(1, 4)) {
      await tapKey(tester, l);
    }
    expect(errorsColor(4), const Color(0xFFDC2626));
  });

  testWidgets('no último nível, vencer avisa que já está no fim', (tester) async {
    final p = await pumpGame(tester, const Size(320, 568));
    await tapButton(tester, '7');
    await tapButton(tester, 'Jogar!');
    expect(find.text('Jogo da Forca • Nível 7'), findsOneWidget);
    await guessWholeWord(tester, p);
    expect(find.text('Você está no último nível!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tapButton(tester, 'Próxima palavra');
    expect(p.level, 7);
    expect(find.text('Jogo da Forca • Nível 7'), findsOneWidget);
  });

  testWidgets('Mudar nível depois de vencer e começar em outro nível', (tester) async {
    final p = await pumpGame(tester, const Size(360, 740));
    await tapButton(tester, 'Jogar!');
    await guessWholeWord(tester, p);
    await tapButton(tester, 'Mudar nível');
    expect(find.byType(SoloSetup), findsOneWidget);
    await tapButton(tester, '6');
    await tapButton(tester, 'Jogar!');
    expect(p.level, 6);
    expect(find.text('Jogo da Forca • Nível 6'), findsOneWidget);
  });

  testWidgets('"voltar" do sistema no meio da partida volta ao menu', (tester) async {
    final p = await pumpGame(tester, const Size(360, 740));
    await tapButton(tester, 'Jogar!');
    await tapKey(tester, p.currentWord[0]);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_menu), findsOneWidget);
  });
}
