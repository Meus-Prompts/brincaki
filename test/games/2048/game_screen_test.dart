// test/games/2048/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/2048/data/high_score_store.dart';
import 'package:brincaki/games/2048/logic/board_logic.dart';
import 'package:brincaki/games/2048/models/game_state.dart';
import 'package:brincaki/games/2048/providers/game_provider.dart';
import 'package:brincaki/games/2048/screens/game_screen.dart';

class _MemoryStore implements HighScoreStore {
  @override
  Future<int> load() async => 0;
  @override
  Future<void> save(int value) async {}
}

void main() {
  late Game2048Provider provider;

  Future<void> pumpScreen(WidgetTester tester) async {
    provider = Game2048Provider(store: _MemoryStore(), random: Random(3));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Game2048Screen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra Pontos, Recorde e Novo jogo', (tester) async {
    await pumpScreen(tester);
    expect(find.text('PONTOS'), findsOneWidget);
    expect(find.text('RECORDE'), findsOneWidget);
    expect(find.text('Novo jogo'), findsOneWidget);
  });

  testWidgets('seta do teclado move as peças', (tester) async {
    await pumpScreen(tester);
    provider.debugSetBoard([
      [0, 0, 0, 2],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(provider.board[0][0], 2);
  });

  testWidgets('swipe para a esquerda move as peças', (tester) async {
    await pumpScreen(tester);
    provider.debugSetBoard([
      [0, 0, 0, 2],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    await tester.pump();
    await tester.fling(find.byKey(const Key('board2048')), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(provider.board[0][0], 2);
  });

  testWidgets('overlay de vitória com Continuar', (tester) async {
    await pumpScreen(tester);
    provider.debugSetBoard([
      [1024, 1024, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    provider.move(Direction.left);
    await tester.pumpAndSettle();
    expect(find.text('Você chegou ao 2048!'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(provider.phase, Game2048Phase.playing);
    expect(find.text('Você chegou ao 2048!'), findsNothing);
  });
}
