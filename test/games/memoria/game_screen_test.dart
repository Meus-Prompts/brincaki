// test/games/memoria/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/memoria/models/game_state.dart';
import 'package:brincaki/games/memoria/providers/game_provider.dart';
import 'package:brincaki/games/memoria/screens/game_screen.dart';

Future<MemoryProvider> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = MemoryProvider(random: Random(2));
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: MemoryScreen()),
  ));
  return provider;
}

Map<String, List<int>> byEmoji(MemoryProvider p) {
  final map = <String, List<int>>{};
  for (final c in p.cards) {
    if (!c.matched) map.putIfAbsent(c.emoji, () => []).add(c.id);
  }
  return map;
}

void main() {
  testWidgets('solo: acha todos os pares e vê o nível completo', (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Memória • Nível 1'), findsOneWidget);
    expect(find.byKey(const Key('card-0')), findsOneWidget);

    for (final ids in byEmoji(p).values) {
      await tester.tap(find.byKey(Key('card-${ids[0]}')));
      await tester.tap(find.byKey(Key('card-${ids[1]}')));
      await tester.pumpAndSettle();
    }
    expect(p.phase, MemoryPhase.finished);
    expect(find.text('Nível 1 completo em 6 jogadas!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Próximo nível'));
    await tester.pumpAndSettle();
    expect(find.text('Memória • Nível 2'), findsOneWidget);
  });

  testWidgets('erro: cartas desviram sozinhas depois de um instante',
      (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();

    final groups = byEmoji(p).values.toList();
    await tester.tap(find.byKey(Key('card-${groups[0][0]}')));
    await tester.tap(find.byKey(Key('card-${groups[1][0]}')));
    await tester.pump();
    expect(p.waitingToHide, isTrue);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();
    expect(p.waitingToHide, isFalse);
    expect(p.cards.where((c) => c.faceUp), isEmpty);
  });

  testWidgets('sair com cartas erradas à mostra não deixa timer pendente',
      (tester) async {
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

  testWidgets('dois jogadores: placar e fim de partida', (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Empates'), findsOneWidget);
    expect(find.text('Grande'), findsOneWidget); // tamanho antes da 1ª jogada

    for (final ids in byEmoji(p).values) {
      await tester.tap(find.byKey(Key('card-${ids[0]}')));
      await tester.tap(find.byKey(Key('card-${ids[1]}')));
      await tester.pumpAndSettle();
    }
    expect(find.text('🏆 Jogador 1 venceu!'), findsOneWidget);
    await tester.tap(find.text('Trocar jogadores'));
    await tester.pumpAndSettle();
    expect(find.text('Jogar!'), findsOneWidget);
  });
}
