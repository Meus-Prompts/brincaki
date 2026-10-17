// test/games/memoria/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/memoria/models/game_state.dart';
import 'package:brincaki/games/memoria/providers/game_provider.dart';
import 'package:brincaki/games/memoria/screens/game_screen.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_scaffold.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/result_panel.dart';

/// Abre a Memória a partir de um "menu" de mentira, como no app.
Future<MemoryProvider> pumpScreen(
  WidgetTester tester, {
  Size size = const Size(360, 740),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = MemoryProvider(random: Random(2));
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameShell(
                  theme: kMemoriaPalette.theme,
                  wrapProvider: (child) =>
                      ChangeNotifierProvider.value(value: provider, child: child),
                  home: (_) => const MemoryScreen(),
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

Map<String, List<int>> byEmoji(MemoryProvider p) {
  final map = <String, List<int>>{};
  for (final c in p.cards) {
    if (!c.matched) map.putIfAbsent(c.emoji, () => []).add(c.id);
  }
  return map;
}

Future<void> startSolo(WidgetTester tester, {String level = '1'}) async {
  await tester.tap(find.widgetWithText(ChoiceChip, level));
  await tester.pump();
  await tester.tap(find.text('Jogar!'));
  await tester.pumpAndSettle();
}

Future<void> startDuo(WidgetTester tester, {String? name1, String? name2}) async {
  await tester.tap(find.text('Dois jogadores'));
  await tester.pump();
  if (name1 != null) await tester.enterText(find.byKey(const Key('name1')), name1);
  if (name2 != null) await tester.enterText(find.byKey(const Key('name2')), name2);
  await tester.tap(find.text('Jogar!'));
  await tester.pumpAndSettle();
}

Future<void> tapCard(WidgetTester tester, int id) async {
  await tester.ensureVisible(find.byKey(Key('card-$id')));
  await tester.tap(find.byKey(Key('card-$id')));
}

/// Acha [count] pares (todos, se nulo) lendo `provider.cards`.
Future<void> findPairs(WidgetTester tester, MemoryProvider p, [int? count]) async {
  final pairs = byEmoji(p).values.toList();
  for (final ids in pairs.take(count ?? pairs.length)) {
    await tapCard(tester, ids[0]);
    await tapCard(tester, ids[1]);
    await tester.pumpAndSettle();
  }
}

/// Erra de propósito e espera as cartas desvirarem (passa a vez em dupla).
Future<void> miss(WidgetTester tester, MemoryProvider p) async {
  final groups = byEmoji(p).values.toList();
  await tapCard(tester, groups[0][0]);
  await tapCard(tester, groups[1][0]);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 950));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tela de início: GameScaffold da Memória e níveis 1 a 5 só no solo',
      (tester) async {
    await pumpScreen(tester);
    final scaffold = tester.widget<GameScaffold>(find.byType(GameScaffold));
    expect(scaffold.palette, kMemoriaPalette);
    expect(scaffold.result, isNull);
    expect(find.text('Jogo da Memória'), findsWidgets);
    expect(find.text('Sozinho'), findsOneWidget);
    expect(find.text('Nível'), findsOneWidget);
    for (var i = 1; i <= 5; i++) {
      expect(find.widgetWithText(ChoiceChip, '$i'), findsOneWidget);
    }
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Nome do Jogador 2'), findsOneWidget);
  });

  for (var level = 1; level <= 5; level++) {
    testWidgets('solo: escolher o nível $level começa nele', (tester) async {
      final p = await pumpScreen(tester);
      await startSolo(tester, level: '$level');
      expect(p.level, level);
      expect(find.text('Memória • Nível $level'), findsOneWidget);
      final count = p.grid.rows * p.grid.cols;
      expect(find.byKey(Key('card-${count - 1}')), findsOneWidget);
      expect(find.byKey(Key('card-$count')), findsNothing);
      expect(find.text('Jogadas: 0'), findsOneWidget);
    });
  }

  testWidgets('solo: fluxo completo com Próximo nível e Mudar nível', (tester) async {
    final p = await pumpScreen(tester);
    await startSolo(tester);
    expect(find.text('Memória • Nível 1'), findsOneWidget);

    await miss(tester, p);
    expect(find.text('Jogadas: 1'), findsOneWidget);
    await findPairs(tester, p);
    expect(p.phase, MemoryPhase.finished);
    expect(find.byType(ResultPanel), findsOneWidget);
    expect(find.text('🎉'), findsOneWidget);
    expect(find.text('Nível 1 completo em 7 jogadas!'), findsOneWidget);
    final panel = tester.widget<ResultPanel>(find.byType(ResultPanel));
    expect(panel.palette, kMemoriaPalette);
    expect(panel.actions.map((a) => (a.label, a.primary)),
        [('Próximo nível', true), ('Mudar nível', false)]);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Próximo nível'));
    await tester.pumpAndSettle();
    expect(find.text('Memória • Nível 2'), findsOneWidget);
    expect(find.byType(ResultPanel), findsNothing);
    expect(find.text('Jogadas: 0'), findsOneWidget);

    await findPairs(tester, p);
    expect(find.text('Nível 2 completo em 8 jogadas!'), findsOneWidget);
    await tester.tap(find.text('Mudar nível'));
    await tester.pumpAndSettle();
    expect(p.phase, MemoryPhase.setup);
    expect(find.text('Jogar!'), findsOneWidget);
    expect(find.text('Jogo da Memória'), findsWidgets);
  });

  testWidgets('solo: no último nível o botão é Jogar de novo e repete o nível',
      (tester) async {
    final p = await pumpScreen(tester);
    await startSolo(tester, level: '5');
    await findPairs(tester, p);
    expect(find.text('Nível 5 completo em 18 jogadas!'), findsOneWidget);
    expect(find.text('Próximo nível'), findsNothing);
    await tester.tap(find.text('Jogar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Memória • Nível 5'), findsOneWidget);
    expect(p.phase, MemoryPhase.playing);
  });

  testWidgets('erro: cartas desviram sozinhas depois de um instante', (tester) async {
    final p = await pumpScreen(tester);
    await startSolo(tester);

    final groups = byEmoji(p).values.toList();
    await tapCard(tester, groups[0][0]);
    await tapCard(tester, groups[1][0]);
    await tester.pump();
    expect(p.waitingToHide, isTrue);
    await tapCard(tester, groups[2][0]); // ignorado enquanto espera
    await tester.pump(const Duration(milliseconds: 500));
    expect(p.waitingToHide, isTrue, reason: 'ainda não desvirou');

    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(p.waitingToHide, isFalse);
    expect(p.cards.where((c) => c.faceUp), isEmpty);
  });

  testWidgets('sair com cartas erradas à mostra não deixa timer pendente', (tester) async {
    // Como no GameShell: o provider é criado na árvore e descartado ao sair.
    late MemoryProvider p;
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => p = MemoryProvider(random: Random(2)),
      child: const MaterialApp(home: MemoryScreen()),
    ));
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    final groups = byEmoji(p).values.toList();
    await tester.tap(find.byKey(Key('card-${groups[0][0]}')));
    await tester.tap(find.byKey(Key('card-${groups[1][0]}')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox()); // a tela sai da árvore
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dois jogadores: fluxo completo, vez, placar e os dois botões',
      (tester) async {
    final p = await pumpScreen(tester);
    await startDuo(tester, name1: 'Ana', name2: 'Beto');
    expect(find.text('Memória'), findsOneWidget, reason: 'sem nível no título');
    expect(find.text('Empates'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('Vitórias: 0 × 0'), findsOneWidget);

    await findPairs(tester, p, 1);
    expect(p.currentPlayer, 1, reason: 'acertou, continua');
    await miss(tester, p);
    expect(p.currentPlayer, 2, reason: 'errou, passa a vez');
    await findPairs(tester, p);
    expect(p.winner, 2);
    expect(find.text('🏆'), findsOneWidget);
    expect(find.text('Beto venceu!'), findsOneWidget);
    expect(find.text('1 × 9 pares'), findsOneWidget);
    final panel = tester.widget<ResultPanel>(find.byType(ResultPanel));
    expect(panel.actions.map((a) => (a.label, a.primary)),
        [('Jogar de novo', true), ('Trocar jogadores', false)]);

    await tester.tap(find.text('Jogar de novo'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultPanel), findsNothing);
    expect(find.text('Vitórias: 0 × 1'), findsOneWidget);
    expect(p.currentPlayer, 2, reason: 'quem começa alterna');
    await findPairs(tester, p);
    expect(find.text('Beto venceu!'), findsOneWidget);
    expect(find.text('0 × 10 pares'), findsOneWidget);

    await tester.tap(find.text('Trocar jogadores'));
    await tester.pumpAndSettle();
    expect(find.text('Jogar!'), findsOneWidget);
    expect(p.wins1 + p.wins2 + p.draws, 0);
  });

  testWidgets('dois jogadores: empate mostra 🤝 Empate!', (tester) async {
    final p = await pumpScreen(tester);
    await startDuo(tester);
    await tester.tap(find.text('Pequena'));
    await tester.pumpAndSettle();
    await findPairs(tester, p, 3); // jogador 1: 3 pares
    await miss(tester, p);
    await findPairs(tester, p); // jogador 2: os 3 restantes
    expect(p.draws, 1);
    expect(find.text('Empate!'), findsOneWidget);
    expect(find.text('3 × 3 pares'), findsOneWidget);
    expect(find.text('🤝'), findsWidgets); // placar e painel
  });

  testWidgets('dois jogadores: tamanho da grade troca antes da 1ª jogada', (tester) async {
    final p = await pumpScreen(tester);
    await startDuo(tester);
    expect(find.byKey(const Key('card-19')), findsOneWidget);
    await tester.tap(find.text('Grande'));
    await tester.pumpAndSettle();
    expect(p.duoSize, 'Grande');
    expect(find.byKey(const Key('card-35')), findsOneWidget);
    await tester.tap(find.text('Pequena'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-11')), findsOneWidget);
    expect(find.byKey(const Key('card-12')), findsNothing);
  });

  testWidgets('jogar de novo não mostra as figuras da grade nova', (tester) async {
    final p = await pumpScreen(tester);
    await startDuo(tester);
    await findPairs(tester, p);
    await tester.tap(find.text('Jogar de novo'));
    await tester.pump(); // primeiro quadro da grade nova
    await tester.pump(const Duration(milliseconds: 50));
    for (final card in p.cards) {
      expect(find.text(card.emoji), findsNothing,
          reason: 'figura ${card.emoji} visível na grade nova');
    }
  });

  testWidgets('tamanhos somem ao virar a 1ª carta sem a grade pular', (tester) async {
    final p = await pumpScreen(tester);
    await startDuo(tester);
    final before = tester.getRect(find.byKey(const Key('card-0')));

    final groups = byEmoji(p).values.toList();
    await tester.tap(find.byKey(Key('card-${groups[0][0]}')));
    await tester.pumpAndSettle();
    expect(find.text('Grande'), findsNothing);
    await tester.tap(find.byKey(Key('card-${groups[1][0]}')));
    await tester.pump();
    expect(tester.getRect(find.byKey(const Key('card-0'))), before);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('seta de voltar fecha o jogo e volta ao menu', (tester) async {
    final p = await pumpScreen(tester);
    await startSolo(tester);
    await findPairs(tester, p, 1);
    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsOneWidget);
    expect(find.byType(MemoryScreen), findsNothing);
  });

  for (final size in [const Size(360, 740), const Size(320, 568)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('sem overflow em $label: solo no maior nível até o resultado',
        (tester) async {
      final p = await pumpScreen(tester, size: size);
      expect(tester.takeException(), isNull, reason: 'tela de início');
      await startSolo(tester, level: '5');
      expect(tester.takeException(), isNull, reason: 'grade 6×6');
      await findPairs(tester, p);
      expect(find.byType(ResultPanel), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'resultado');
      final card = tester.getSize(find.byKey(const Key('card-0')));
      expect(card.width, greaterThan(20));
    });

    testWidgets('sem overflow em $label: dupla na grade Grande até o resultado',
        (tester) async {
      final p = await pumpScreen(tester, size: size);
      await startDuo(tester);
      expect(tester.takeException(), isNull, reason: 'tela de início');
      await tester.tap(find.text('Grande'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'grade 6×6');
      await findPairs(tester, p);
      expect(find.byType(ResultPanel), findsOneWidget);
      expect(find.text('Jogador 1 venceu!'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'resultado');
      final card = tester.getSize(find.byKey(const Key('card-0')));
      expect(card.width, greaterThan(12), reason: 'cartas ainda visíveis');
    });
  }
}
