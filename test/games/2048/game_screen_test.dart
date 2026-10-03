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
  _MemoryStore([this.saved = 0]);
  final int saved;

  @override
  Future<int> load() async => saved;
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

  testWidgets('cabeçalho cabe num celular com fonte grande e recorde alto',
      (tester) async {
    // 320dp: celular de 360dp com "tamanho de exibição" grande.
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    provider = Game2048Provider(store: _MemoryStore(25000), random: Random(3));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const Game2048Screen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(provider.best, 25000);
    final button = tester.getRect(find.text('Novo jogo'));
    expect(button.right, lessThanOrEqualTo(320));
  });

  testWidgets('arrasto lento, parando antes de soltar, também move',
      (tester) async {
    await pumpScreen(tester);
    provider.debugSetBoard([
      [0, 0, 0, 2],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    await tester.pump();

    final center = tester.getCenter(find.byKey(const Key('board2048')));
    final gesture = await tester.startGesture(center);
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-15, 0));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 500)); // dedo parado
    await gesture.up();
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
