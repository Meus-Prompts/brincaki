// test/games/silabas/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/silabas/data/word_list.dart';
import 'package:brincaki/games/silabas/logic/word.dart';
import 'package:brincaki/games/silabas/models/game_state.dart';
import 'package:brincaki/games/silabas/providers/game_provider.dart';
import 'package:brincaki/games/silabas/screens/game_screen.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/result_panel.dart';
import 'package:brincaki/widgets/solo_setup.dart';

const _menu = 'Menu de teste';

/// Abre Sílabas como o menu abre: rota com provider, tema e Navigator próprio.
Future<SilabasProvider> pumpGame(
  WidgetTester tester,
  Size size, {
  Map<int, List<String>>? words,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = SilabasProvider(random: Random(7), words: words);
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameShell(
                  wrapProvider: (child) => ChangeNotifierProvider.value(
                      value: provider, child: child),
                  theme: kSilabasPalette.theme,
                  home: (_) => const SilabasScreen(),
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

Future<void> tapButton(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> cutAll(WidgetTester tester, Iterable<int> positions) async {
  for (final pos in positions) {
    await tapKey(tester, 'corte-$pos');
  }
}

/// Joga as três etapas da palavra atual, sem errar.
Future<void> solveWord(WidgetTester tester, SilabasProvider p) async {
  final word = p.word!;
  await cutAll(tester, word.cutPositions);
  await tapButton(tester, 'Conferir');
  await tapKey(tester, 'silaba-${word.stressIndex}');
  await tapKey(tester, 'classe-${word.stressClass.name}');
}

Finder resultButton(String label) =>
    find.descendant(of: find.byType(ResultPanel), matching: find.text(label));

/// Joga a partida inteira até aparecer o painel de resultado.
Future<void> playWholeGame(WidgetTester tester, SilabasProvider p) async {
  for (var i = 0; i < p.wordCount; i++) {
    await solveWord(tester, p);
    await tapButton(
        tester, i == p.wordCount - 1 ? 'Ver resultado' : 'Próxima palavra');
  }
}

String longestWord(Iterable<List<String>> lists) {
  final all = [for (final l in lists) ...l];
  all.sort((a, b) =>
      parseWord(b).text.length.compareTo(parseWord(a).text.length));
  return all.first;
}

void main() {
  for (final size in const [Size(360, 740), Size(320, 568)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('$tag: fluxo completo do início ao menu', (tester) async {
      final p = await pumpGame(tester, size);

      // Escolha de nível.
      expect(find.byType(SoloSetup), findsOneWidget);
      expect(find.text('Sílabas'), findsNWidgets(2)); // AppBar e cabeçalho
      expect(find.text('🔤'), findsOneWidget);
      for (final name in SilabasProvider.levelNames) {
        expect(find.widgetWithText(ChoiceChip, name), findsOneWidget);
      }
      await tapButton(tester, 'Médio');
      await tapButton(tester, 'Jogar!');
      expect(p.phase, SilabasPhase.playing);
      expect(p.level, 1);
      expect(find.text('Sílabas • Médio'), findsOneWidget);
      expect(find.text('Palavra 1 de 10'), findsOneWidget);
      expect(find.text('⭐ 0'), findsOneWidget);
      expect(find.text('Toque entre as letras para separar as sílabas'),
          findsOneWidget);
      expect(tester.takeException(), isNull);

      // Etapa 1: "Conferir" desabilitado sem cortes.
      ElevatedButton check() =>
          tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Conferir'));
      expect(check().onPressed, isNull);

      // Corte errado fica vermelho; com todos os cortes certos mais um
      // errado, não falta nenhum.
      final word = p.word!;
      final correct = word.cutPositions;
      final wrongPos =
          [for (var i = 1; i < word.text.length; i++) i].firstWhere((i) => !correct.contains(i));
      await cutAll(tester, [...correct, wrongPos]);
      await tapButton(tester, 'Conferir');
      expect(p.wrongCuts, {wrongPos});
      expect(find.text('Os cortes em vermelho estão no lugar errado'),
          findsOneWidget);
      expect(find.textContaining('A palavra tem'), findsNothing);
      expect(p.step, SilabasStep.split);

      // Corrige o corte e, antes de conferir, tira um certo: falta corte e
      // aparece a dica.
      await tapKey(tester, 'corte-$wrongPos');
      expect(find.textContaining('lugar errado'), findsNothing);
      final removed = correct.first;
      await tapKey(tester, 'corte-$removed');
      // Com uma só sílaba de corte, o botão ficaria desabilitado sem cortes.
      if (correct.length == 1) await tapKey(tester, 'corte-$wrongPos');
      await tapButton(tester, 'Conferir');
      expect(find.text('A palavra tem ${word.syllables.length} sílabas'),
          findsOneWidget);
      if (correct.length == 1) await tapKey(tester, 'corte-$wrongPos');
      await tapKey(tester, 'corte-$removed');
      await tapButton(tester, 'Conferir');

      // Etapa 2: erra e depois acerta.
      expect(p.step, SilabasStep.stress);
      expect(find.text('Qual é a sílaba mais forte?'), findsOneWidget);
      final wrongStress = [for (var i = 0; i < word.syllables.length; i++) i]
          .firstWhere((i) => i != word.stressIndex);
      await tapKey(tester, 'silaba-$wrongStress');
      expect(find.text('Essa não é a mais forte. Tente de novo!'),
          findsOneWidget);
      expect(p.step, SilabasStep.stress);
      await tapKey(tester, 'silaba-${word.stressIndex}');

      // Etapa 3: erra e depois acerta.
      expect(p.step, SilabasStep.classify);
      expect(find.text('Como ela se chama?'), findsOneWidget);
      expect(find.text('Essa não é a mais forte. Tente de novo!'), findsNothing);
      final wrongClass =
          StressClass.values.firstWhere((c) => c != word.stressClass);
      await tapKey(tester, 'classe-${wrongClass.name}');
      expect(find.text('Quase! Conte as sílabas de trás para frente.'),
          findsOneWidget);
      await tapKey(tester, 'classe-${word.stressClass.name}');

      // Palavra resolvida: 10 + 5 (corte errado + falta de corte = 2 erros -> 2),
      // então lê os pontos do provider.
      expect(p.step, SilabasStep.solved);
      expect(find.text('+${p.wordPoints}'), findsOneWidget);
      expect(find.text(stressClassLabel(word.stressClass)), findsOneWidget);
      expect(find.text('Próxima palavra'), findsOneWidget);
      expect(find.byType(ResultPanel), findsNothing);
      expect(tester.takeException(), isNull);

      await tapButton(tester, 'Próxima palavra');
      expect(p.index, 1);
      expect(find.text('Palavra 2 de 10'), findsOneWidget);
      expect(find.text('⭐ ${p.score}'), findsOneWidget);

      // Sem errar, até a 10ª palavra.
      for (var i = 1; i < 9; i++) {
        await solveWord(tester, p);
        await tapButton(tester, 'Próxima palavra');
      }
      expect(p.isLastWord, isTrue);
      await solveWord(tester, p);
      expect(find.text('Próxima palavra'), findsNothing);
      await tapButton(tester, 'Ver resultado');

      // Resultado: a última palavra continua visível.
      expect(p.phase, SilabasPhase.finished);
      expect(find.byType(ResultPanel), findsOneWidget);
      expect(find.text('🏆'), findsOneWidget);
      expect(find.text('Ver resultado'), findsNothing);
      expect(find.text('Próxima palavra'), findsNothing);
      expect(find.text('+10'), findsNothing);
      expect(find.text('+30'), findsOneWidget);
      final lastWord = p.word!;
      for (final s in lastWord.syllables) {
        expect(find.text(s), findsWidgets);
      }
      // Só a primeira palavra teve erros: 3 estrelas.
      expect(p.stars, 3);
      expect(find.text('Mandou muito!'), findsOneWidget);
      expect(find.text('${p.score} pontos de 300\n⭐⭐⭐'), findsOneWidget);
      expect(resultButton('Jogar de novo'), findsOneWidget);
      expect(resultButton('Mudar nível'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Jogar de novo.
      await tapButton(tester, 'Jogar de novo');
      expect(p.phase, SilabasPhase.playing);
      expect(p.score, 0);
      expect(p.index, 0);
      expect(find.text('Palavra 1 de 10'), findsOneWidget);
      expect(find.byType(ResultPanel), findsNothing);

      // Mudar nível: a escolha anterior continua marcada.
      await playWholeGame(tester, p);
      await tapButton(tester, 'Mudar nível');
      expect(p.phase, SilabasPhase.setup);
      expect(find.byType(SoloSetup), findsOneWidget);
      expect(
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Médio')).selected,
        isTrue,
      );

      // Seta de voltar sai direto do início.
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text(_menu), findsOneWidget);
      expect(find.byType(SilabasScreen), findsNothing);
    });

    testWidgets('$tag: partida perfeita mostra "Mandou muito!"', (tester) async {
      final p = await pumpGame(tester, size);
      await tapButton(tester, 'Jogar!');
      await playWholeGame(tester, p);
      expect(p.score, 300);
      expect(find.text('Mandou muito!'), findsOneWidget);
      expect(find.text('300 pontos de 300\n⭐⭐⭐'), findsOneWidget);
    });

    testWidgets('$tag: partida com um erro por palavra mostra "Muito bem!"',
        (tester) async {
      final p = await pumpGame(tester, size);
      await tapButton(tester, 'Jogar!');
      for (var i = 0; i < p.wordCount; i++) {
        final word = p.word!;
        await cutAll(tester, word.cutPositions);
        await tapButton(tester, 'Conferir');
        final wrongStress = [for (var k = 0; k < word.syllables.length; k++) k]
            .firstWhere((k) => k != word.stressIndex);
        await tapKey(tester, 'silaba-$wrongStress');
        await tapKey(tester, 'silaba-${word.stressIndex}');
        await tapKey(tester, 'classe-${word.stressClass.name}');
        await tapButton(
            tester, i == p.wordCount - 1 ? 'Ver resultado' : 'Próxima palavra');
      }
      expect(p.score, 250);
      expect(find.text('Muito bem!'), findsOneWidget);
      expect(find.text('250 pontos de 300\n⭐⭐'), findsOneWidget);
    });

    testWidgets('$tag: partida com muitos erros mostra "Boa tentativa!"',
        (tester) async {
      final p = await pumpGame(tester, size);
      await tapButton(tester, 'Jogar!');
      for (var i = 0; i < p.wordCount; i++) {
        final word = p.word!;
        // Dois erros em cada etapa: 2 pontos por etapa.
        final wrongPositions = [
          for (var k = 1; k < word.text.length; k++)
            if (!word.cutPositions.contains(k)) k
        ];
        if (wrongPositions.isNotEmpty) {
          await tapKey(tester, 'corte-${wrongPositions.first}');
          await tapButton(tester, 'Conferir');
          await tapButton(tester, 'Conferir');
          await tapKey(tester, 'corte-${wrongPositions.first}');
        } else {
          await tapKey(tester, 'corte-${word.cutPositions.first}');
          await tapButton(tester, 'Conferir');
          await tapButton(tester, 'Conferir');
          await tapKey(tester, 'corte-${word.cutPositions.first}');
        }
        await cutAll(tester, word.cutPositions);
        await tapButton(tester, 'Conferir');
        final wrongStress = [for (var k = 0; k < word.syllables.length; k++) k]
            .where((k) => k != word.stressIndex)
            .take(2);
        for (final k in wrongStress) {
          await tapKey(tester, 'silaba-$k');
        }
        await tapKey(tester, 'silaba-${word.stressIndex}');
        for (final c in StressClass.values
            .where((c) => c != word.stressClass)
            .take(2)) {
          await tapKey(tester, 'classe-${c.name}');
        }
        await tapKey(tester, 'classe-${word.stressClass.name}');
        await tapButton(
            tester, i == p.wordCount - 1 ? 'Ver resultado' : 'Próxima palavra');
      }
      expect(p.score, lessThan(180));
      expect(find.text('Boa tentativa!'), findsOneWidget);
      expect(find.textContaining('${p.score} pontos de 300\n⭐'), findsOneWidget);
    });

    testWidgets('$tag: seta de voltar pergunta "Sair do jogo?" durante a partida',
        (tester) async {
      final p = await pumpGame(tester, size);
      await tapButton(tester, 'Jogar!');

      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text('Sair do jogo?'), findsOneWidget);

      await tester.tap(find.text('Continuar jogando'));
      await tester.pumpAndSettle();
      expect(find.text('Sair do jogo?'), findsNothing);
      expect(p.phase, SilabasPhase.playing);
      expect(find.byType(SilabasScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(find.text(_menu), findsOneWidget);
      expect(find.byType(SilabasScreen), findsNothing);
    });

    testWidgets('$tag: do resultado a seta sai direto', (tester) async {
      final p = await pumpGame(tester, size);
      await tapButton(tester, 'Jogar!');
      await playWholeGame(tester, p);
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text('Sair do jogo?'), findsNothing);
      expect(find.text(_menu), findsOneWidget);
    });
  }

  testWidgets('palavra mais longa cabe em 320x568', (tester) async {
    final longest = longestWord(kSilabasWordsByLevel.values);
    final text = parseWord(longest).text;
    final p = await pumpGame(
      tester,
      const Size(320, 568),
      words: {for (var i = 0; i < 3; i++) i: [longest]},
    );
    expect(text.length, greaterThanOrEqualTo(9));
    await tapButton(tester, 'Jogar!');
    expect(p.wordCount, 1);
    expect(tester.takeException(), isNull);

    // Etapa 1: todos os espaços cabem na tela, com 24 px.
    for (var pos = 1; pos < text.length; pos++) {
      final rect = tester.getRect(find.byKey(Key('corte-$pos')));
      expect(rect.width, closeTo(24, 0.001));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
    await cutAll(tester, p.word!.cutPositions);
    await tapButton(tester, 'Conferir');
    expect(tester.takeException(), isNull);

    // Etapa 2 e 3.
    await tapKey(tester, 'silaba-${p.word!.stressIndex}');
    expect(tester.takeException(), isNull);
    await tapKey(tester, 'classe-${p.word!.stressClass.name}');
    expect(tester.takeException(), isNull);
    expect(p.step, SilabasStep.solved);
    await tapButton(tester, 'Ver resultado');
    expect(find.byType(ResultPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
