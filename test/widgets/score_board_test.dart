// test/widgets/score_board_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/widgets/score_board.dart';

void main() {
  testWidgets('mostra nomes, pontos e empates', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ScoreBoard(
          name1: 'Ana',
          name2: 'Beto',
          symbol1: '🔴',
          symbol2: '🟡',
          score1: 3,
          score2: 1,
          draws: 2,
          activePlayer: 1,
          accent: Colors.red,
        ),
      ),
    ));
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Empates'), findsOneWidget);
  });

  testWidgets('nomes longos não estouram num celular pequeno', (tester) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ScoreBoard(
          name1: 'Maria Eduarda',
          name2: 'João Guilherme',
          symbol1: '🐶',
          symbol2: '🐱',
          score1: 10,
          score2: 12,
          draws: 3,
          accent: Colors.purple,
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
