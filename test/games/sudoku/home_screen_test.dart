// test/games/sudoku/home_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/sudoku/providers/game_provider.dart';
import 'package:brincaki/games/sudoku/screens/home_screen.dart';

void main() {
  testWidgets('tela inicial cabe num celular pequeno sem estourar', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameProvider(),
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Master'));
    expect(find.text('Master'), findsOneWidget);
  });
}
