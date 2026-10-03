// test/games/sudoku/game_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/sudoku/models/difficulty.dart';
import 'package:brincaki/games/sudoku/providers/game_provider.dart';
import 'package:brincaki/games/sudoku/screens/game_screen.dart';

void main() {
  testWidgets('tela da partida não estoura num celular', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final provider = GameProvider()..startGame(Difficulty.easy);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const GameScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    provider.dispose(); // cancela o cronômetro antes do fim do teste
  });
}
