// test/games/contas/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/contas/models/game_state.dart';
import 'package:brincaki/games/contas/providers/game_provider.dart';
import 'package:brincaki/games/contas/screens/game_screen.dart';
import 'package:brincaki/games/contas/widgets/choice_grid.dart';
import 'package:brincaki/games/contas/widgets/number_pad.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/result_panel.dart';

import 'fake_record_store.dart';

const _menu = 'Menu de teste';

/// Abre as Contas como o menu abre: rota com provider, tema e Navigator
/// próprio.
Future<ContasProvider> pumpGame(WidgetTester tester, Size size,
    {FakeRecordStore? store}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider =
      ContasProvider(store: store ?? FakeRecordStore(), random: Random(7));
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
                  theme: kContasPalette.theme,
                  home: (_) => const ContasScreen(),
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

/// Toca e espera a pausa contra toque duplo passar.
Future<void> tapFinder(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> tapText(WidgetTester tester, String text) =>
    tapFinder(tester, find.text(text));

Future<void> tapKey(WidgetTester tester, String key) =>
    tapFinder(tester, find.byKey(Key(key)));

Future<void> typeNumber(WidgetTester tester, int value) async {
  for (final digit in '$value'.split('')) {
    await tapKey(tester, 'tecla-$digit');
  }
  await tapKey(tester, 'tecla-ok');
}

Future<void> answerRight(WidgetTester tester, ContasProvider p) async {
  if (p.answerMode == AnswerMode.choices) {
    await tapKey(tester, 'opcao-${p.problem!.answer}');
  } else {
    await typeNumber(tester, p.problem!.answer);
  }
}

Future<void> answerWrong(WidgetTester tester, ContasProvider p) async {
  if (p.answerMode == AnswerMode.choices) {
    final wrong = p.choices.firstWhere((c) => c != p.problem!.answer);
    await tapKey(tester, 'opcao-$wrong');
  } else {
    await typeNumber(tester, p.problem!.answer + 1);
  }
}

Finder inPanel(String text) =>
    find.descendant(of: find.byType(ResultPanel), matching: find.text(text));

IconData heart(WidgetTester tester, int i) =>
    tester.widget<Icon>(find.byKey(Key('vida-$i'))).icon!;

void main() {
  for (final size in const [Size(360, 740), Size(320, 568)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('$tag: teclado, do início ao menu', (tester) async {
      final p = await pumpGame(tester, size);

      // Tela de início.
      expect(find.text('Contas'), findsNWidgets(2)); // AppBar e cabeçalho
      expect(find.text('🧮'), findsOneWidget);
      for (final label in [
        'Operação', '+ Adição', '− Subtração', '× Multiplicação', '÷ Divisão',
        'Nível', '1', '2', '3', 'Responder com', '⌨️ Teclado', '🔘 Opções',
        'Somas até 100', '🏆 Recorde: 0', 'Jogar!',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(tester.takeException(), isNull);

      await tapText(tester, '× Multiplicação');
      await tapText(tester, '2');
      expect(find.text('Tabuada do 6 ao 10'), findsOneWidget);
      await tapText(tester, 'Jogar!');
      expect(find.text('Contas • Multiplicação 2'), findsOneWidget);
      expect(find.byType(NumberPad), findsOneWidget);
      expect(find.text('${p.problem!.text} = ?'), findsOneWidget);
      expect(find.byTooltip('Parar'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Acerto.
      await answerRight(tester, p);
      expect(find.text('⭐ 10'), findsOneWidget);
      expect(find.text('🔥 1'), findsOneWidget);
      expect(find.text('${p.problem!.text} = ?'), findsOneWidget);

      // Erro: mostra a resposta e espera o "Continuar".
      final missed = p.problem!;
      await answerWrong(tester, p);
      expect(find.text('Quase!'), findsOneWidget);
      expect(find.text('A resposta certa é ${missed.answer}'), findsOneWidget);
      expect(find.text('${missed.text} = ${missed.answer}'), findsOneWidget);
      expect(find.byType(NumberPad), findsNothing);
      expect(heart(tester, 2), Icons.favorite_border);
      expect(find.text('🔥 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Continuar');
      expect(find.byType(NumberPad), findsOneWidget);
      expect(find.text('Quase!'), findsNothing);

      // Mais dois erros: fim, com a última conta à vista.
      await answerWrong(tester, p);
      await tapText(tester, 'Continuar');
      final last = p.problem!;
      await answerWrong(tester, p);
      expect(inPanel('Novo recorde!'), findsOneWidget);
      expect(inPanel('🏆'), findsOneWidget);
      expect(inPanel('⭐ 10 pontos · Recorde: 10\n🔥 Maior sequência: 1'),
          findsOneWidget);
      expect(find.text('${last.text} = ${last.answer}'), findsOneWidget);
      expect(find.byType(NumberPad), findsNothing);
      expect(find.text('Quase!'), findsNothing);
      expect(find.byTooltip('Parar'), findsNothing);
      expect(tester.takeException(), isNull);

      // Jogar de novo.
      await tapFinder(tester, inPanel('Jogar de novo'));
      expect(find.byType(ResultPanel), findsNothing);
      expect(find.text('⭐ 0'), findsOneWidget);
      expect(find.byType(NumberPad), findsOneWidget);

      // Perde de novo sem pontos e muda de nível.
      for (var i = 0; i < 3; i++) {
        await answerWrong(tester, p);
        if (i < 2) await tapText(tester, 'Continuar');
      }
      expect(inPanel('Fim de jogo!'), findsOneWidget);
      expect(inPanel('🎯'), findsOneWidget);
      await tapFinder(tester, inPanel('Mudar nível'));
      expect(p.phase, ContasPhase.setup);
      expect(find.text('🏆 Recorde: 10'), findsOneWidget);
      expect(find.text('Tabuada do 6 ao 10'), findsOneWidget);

      // Na tela de início a seta volta direto.
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text(_menu), findsOneWidget);
      expect(find.byType(ContasScreen), findsNothing);
    });

    testWidgets('$tag: opções', (tester) async {
      final p = await pumpGame(tester, size);
      await tapText(tester, '− Subtração');
      await tapText(tester, '3');
      expect(find.text('Três números até 1000'), findsOneWidget);
      await tapText(tester, '🔘 Opções');
      await tapText(tester, 'Jogar!');
      expect(find.text('Contas • Subtração 3'), findsOneWidget);
      expect(find.byType(ChoiceGrid), findsOneWidget);
      expect(find.byType(NumberPad), findsNothing);
      for (final c in p.choices) {
        expect(find.byKey(Key('opcao-$c')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      await answerRight(tester, p);
      expect(find.text('⭐ 10'), findsOneWidget);
      await answerWrong(tester, p);
      expect(find.text('Quase!'), findsOneWidget);
      expect(find.byType(ChoiceGrid), findsNothing);
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Continuar');
      expect(find.byType(ChoiceGrid), findsOneWidget);
    });

    testWidgets('$tag: 5 seguidas comemora e sobe o multiplicador',
        (tester) async {
      final p = await pumpGame(tester, size);
      await tapText(tester, 'Jogar!');
      for (var i = 0; i < 4; i++) {
        await answerRight(tester, p);
      }
      expect(find.text('+10'), findsNothing); // o aviso some sozinho
      // Pega o aviso logo depois do toque, antes de sumir.
      for (final digit in '${p.problem!.answer}'.split('')) {
        await tapKey(tester, 'tecla-$digit');
      }
      await tester.tap(find.byKey(const Key('tecla-ok')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('5 seguidas! 🔥 Agora ×2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('5 seguidas! 🔥 Agora ×2'), findsNothing);
      expect(find.text('×2 pontos · faltam 5 para ×3'), findsOneWidget);
    });
  }

  testWidgets('parar no meio da rodada mostra o resultado', (tester) async {
    final p = await pumpGame(tester, const Size(320, 568));
    await tapText(tester, 'Jogar!');
    await answerRight(tester, p);
    await tester.tap(find.byTooltip('Parar'));
    await tester.pumpAndSettle();
    expect(inPanel('Novo recorde!'), findsOneWidget);
    expect(find.byType(NumberPad), findsNothing);
    expect(find.text('${p.problem!.text} = ?'), findsOneWidget);
    expect(find.byTooltip('Parar'), findsNothing);
    // Parar não pergunta nada, e no resultado a seta sai direto.
    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    expect(find.text(_menu), findsOneWidget);
  });

  testWidgets('parar sem pontos é fim de jogo', (tester) async {
    await pumpGame(tester, const Size(360, 740));
    await tapText(tester, 'Jogar!');
    await tester.tap(find.byTooltip('Parar'));
    await tester.pumpAndSettle();
    expect(inPanel('Fim de jogo!'), findsOneWidget);
  });

  testWidgets('parar depois de errar mantém a resposta certa à vista',
      (tester) async {
    final p = await pumpGame(tester, const Size(320, 568));
    await tapText(tester, 'Jogar!');
    final missed = p.problem!;
    await answerWrong(tester, p);
    await tester.tap(find.byTooltip('Parar'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultPanel), findsOneWidget);
    expect(find.text('${missed.text} = ${missed.answer}'), findsOneWidget);
    expect(find.text('Continuar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a seta no meio da rodada pergunta antes de sair',
      (tester) async {
    final store = FakeRecordStore();
    final p = await pumpGame(tester, const Size(360, 740), store: store);
    await tapText(tester, 'Jogar!');
    await answerRight(tester, p);

    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    expect(find.text('Sair do jogo?'), findsOneWidget);
    await tester.tap(find.text('Continuar jogando'));
    await tester.pumpAndSettle();
    expect(find.byType(NumberPad), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.text(_menu), findsOneWidget);
    // Sair pela seta não salva o recorde.
    expect(store.saves, isEmpty);
  });

  testWidgets('a seta depois de um erro também pergunta', (tester) async {
    final p = await pumpGame(tester, const Size(360, 740));
    await tapText(tester, 'Jogar!');
    await answerWrong(tester, p);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Sair do jogo?'), findsOneWidget);
  });

  testWidgets('recorde e frase acompanham a escolha',
      (tester) async {
    await pumpGame(
      tester,
      const Size(360, 740),
      store: FakeRecordStore(records: {'division_3': 90}),
    );
    await tapText(tester, '÷ Divisão');
    await tapText(tester, '3');
    expect(find.text('Dividir por 1 a 10'), findsOneWidget);
    expect(find.text('🏆 Recorde: 90'), findsOneWidget);
    await tapText(tester, '1');
    expect(find.text('Dividir por 1 a 5'), findsOneWidget);
    expect(find.text('🏆 Recorde: 0'), findsOneWidget);
  });

  testWidgets('todas as frases de nível', (tester) async {
    await pumpGame(tester, const Size(360, 740));
    const hints = {
      '+ Adição': ['Somas até 100', 'Somas até 1000', 'Três números até 1000'],
      '− Subtração': ['Números até 100', 'Números até 1000', 'Três números até 1000'],
      '× Multiplicação': ['Tabuada do 1 ao 5', 'Tabuada do 6 ao 10', 'Tabuada do 1 ao 10'],
      '÷ Divisão': ['Dividir por 1 a 5', 'Dividir por 6 a 10', 'Dividir por 1 a 10'],
    };
    for (final MapEntry(key: op, value: texts) in hints.entries) {
      await tapText(tester, op);
      for (var level = 1; level <= 3; level++) {
        await tapText(tester, '$level');
        expect(find.text(texts[level - 1]), findsOneWidget, reason: '$op $level');
      }
    }
  });

  testWidgets('título de cada operação na partida', (tester) async {
    final p = await pumpGame(tester, const Size(360, 740));
    for (final (label, title) in const [
      ('+ Adição', 'Contas • Adição 1'),
      ('− Subtração', 'Contas • Subtração 1'),
      ('× Multiplicação', 'Contas • Multiplicação 1'),
      ('÷ Divisão', 'Contas • Divisão 1'),
    ]) {
      await tapText(tester, label);
      await tapText(tester, '1');
      await tapText(tester, 'Jogar!');
      expect(find.text(title), findsOneWidget);
      p.stop();
      await tester.pumpAndSettle();
      await tapFinder(tester, inPanel('Mudar nível'));
    }
  });

  testWidgets('320x568: teclado, erro e resultado cabem sem rolar',
      (tester) async {
    final p = await pumpGame(tester, const Size(320, 568));
    await tapText(tester, 'Jogar!');
    bool onScreen(Finder f) {
      final rect = tester.getRect(f);
      return rect.top >= 0 && rect.bottom <= 568;
    }

    expect(onScreen(find.byKey(const Key('tecla-ok'))), isTrue);
    expect(onScreen(find.byKey(const Key('tecla-0'))), isTrue);
    await answerWrong(tester, p);
    expect(onScreen(find.text('Continuar')), isTrue);
    p.stop();
    await tester.pumpAndSettle();
    expect(onScreen(find.text('${p.problem!.text} = ${p.problem!.answer}')),
        isTrue);
    expect(onScreen(inPanel('Jogar de novo')), isTrue);
  });

  testWidgets('toque duplo numa opção responde só uma conta', (tester) async {
    final p = await pumpGame(tester, const Size(360, 740));
    await tapText(tester, '🔘 Opções');
    await tapText(tester, 'Jogar!');
    final key = find.byKey(Key('opcao-${p.problem!.answer}'));
    final spot = tester.getCenter(key);
    await tester.tapAt(spot);
    await tester.pump();
    await tester.tapAt(spot);
    await tester.pump();
    expect(p.score, 10);
    expect(p.lives, 3);
    expect(p.phase, ContasPhase.playing);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('apagar no teclado', (tester) async {
    final p = await pumpGame(tester, const Size(360, 740));
    await tapText(tester, 'Jogar!');
    await tapKey(tester, 'tecla-4');
    await tapKey(tester, 'tecla-2');
    expect(find.text('42'), findsOneWidget);
    await tapKey(tester, 'tecla-apagar');
    expect(p.typed, '4');
    expect(find.text('4'), findsWidgets);
  });
}
