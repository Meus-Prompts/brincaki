// test/games/lig4/game_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/lig4/logic/ai.dart';
import 'package:brincaki/games/lig4/logic/board.dart';
import 'package:brincaki/games/lig4/providers/game_provider.dart';
import 'package:brincaki/games/lig4/screens/game_screen.dart';

Future<int> firstFree(List<List<int>> board, int me, AiLevel level) async =>
    validColumns(board).first;

Future<Lig4Provider> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree);
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: Lig4Screen()),
  ));
  return provider;
}

void main() {
  testWidgets('dois jogadores: tocar na coluna solta a peça', (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('col-3')));
    await tester.pumpAndSettle();
    expect(p.board[5][3], 1);
    expect(find.text('Vez de 🟡 Jogador 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('buracos e peças aparecem com tamanho de verdade', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('col-0')));
    await tester.pumpAndSettle();

    final cells = find.descendant(
      of: find.byKey(const Key('col-0')),
      matching: find.byType(DecoratedBox),
    );
    expect(cells, findsNWidgets(6));
    for (final element in cells.evaluate()) {
      final size = (element.renderObject! as RenderBox).size;
      expect(size.width, greaterThan(20), reason: 'célula sem largura');
      expect(size.height, greaterThan(20), reason: 'célula sem altura');
    }
  });

  testWidgets('contra o computador: ele responde e o título mostra o nível',
      (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Difícil'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Lig 4 • Difícil'), findsOneWidget);
    await tester.tap(find.byKey(const Key('col-3')));
    await tester.pumpAndSettle();
    expect(p.board[5][0], Lig4Provider.computer);
  });

  testWidgets('vitória mostra o resultado e Trocar jogadores volta ao setup',
      (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    for (final col in [0, 1, 0, 1, 0, 1, 0]) {
      await tester.tap(find.byKey(Key('col-$col')));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(seconds: 2));
    expect(p.winner, 1);
    expect(find.text('🏆 Jogador 1 venceu!'), findsOneWidget);
    await tester.tap(find.text('Trocar jogadores'));
    await tester.pumpAndSettle();
    expect(find.text('Jogar!'), findsOneWidget);
  });
}
