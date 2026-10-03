// test/games/cacapalavras/home_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/cacapalavras/models/game_state.dart';
import 'package:brincaki/games/cacapalavras/providers/game_provider.dart';
import 'package:brincaki/games/cacapalavras/screens/home_screen.dart';
import 'package:brincaki/games/cacapalavras/widgets/letter_grid.dart';

Offset cellCenter(Rect grid, int size, (int, int) cell) {
  final side = grid.width / size;
  return grid.topLeft + Offset((cell.$2 + 0.5) * side, (cell.$1 + 0.5) * side);
}

/// Arrasta devagar, em vários passos, como um dedo de verdade.
Future<void> drag(WidgetTester tester, Offset from, Offset to) async {
  final gesture = await tester.startGesture(from);
  for (var i = 1; i <= 8; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / 8)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump();
}

/// Tela de celular: células pequenas, como no uso real.
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('arrastar sobre cada palavra marca todas e mostra a vitória',
      (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(random: Random(11))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nível 1'), findsOneWidget);

    final gridFinder = find.byType(LetterGrid);
    final provider =
        Provider.of<WordSearchProvider>(tester.element(gridFinder), listen: false);
    final rect = tester.getRect(gridFinder);
    final size = provider.config.size;
    expect(provider.words.map((w) => w.direction), contains(Direction.down),
        reason: 'a seed precisa ter uma palavra vertical');

    for (final w in provider.words) {
      await drag(
        tester,
        cellCenter(rect, size, w.cells.first),
        cellCenter(rect, size, w.cells.last),
      );
      expect(provider.found, contains(w.word), reason: w.word);
    }

    await tester.pumpAndSettle();
    expect(find.text('Nível 1 completo!'), findsOneWidget);

    await tester.tap(find.text('Próximo nível'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nível 2'), findsOneWidget);
  });

  testWidgets('arrasto que sai da grade fica preso na borda', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(random: Random(11))));
    await tester.pumpAndSettle();

    final gridFinder = find.byType(LetterGrid);
    final provider =
        Provider.of<WordSearchProvider>(tester.element(gridFinder), listen: false);
    final rect = tester.getRect(gridFinder);

    final gesture = await tester.startGesture(cellCenter(rect, 6, (0, 0)));
    await gesture.moveTo(rect.topRight + const Offset(100, 0));
    await tester.pump();
    expect(provider.selectedCells.last, (0, 5));
    await gesture.up();
  });
}
