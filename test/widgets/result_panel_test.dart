// test/widgets/result_panel_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/result_panel.dart';

void main() {
  Future<void> pumpPanel(WidgetTester tester, ResultPanel panel) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: panel)));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra emoji, título, mensagem e botões', (tester) async {
    var again = 0;
    var change = 0;
    await pumpPanel(
      tester,
      ResultPanel(
        palette: kLig4Palette,
        emoji: '🏆',
        title: 'Ana venceu!',
        message: 'Tempo: 01:30',
        actions: [
          ResultAction('Jogar de novo', () => again++),
          ResultAction('Trocar jogadores', () => change++, primary: false),
        ],
      ),
    );
    expect(find.text('🏆'), findsOneWidget);
    expect(find.text('Ana venceu!'), findsOneWidget);
    expect(find.text('Tempo: 01:30'), findsOneWidget);

    await tester.tap(find.text('Jogar de novo'));
    await tester.tap(find.text('Trocar jogadores'));
    expect(again, 1);
    expect(change, 1);
  });

  testWidgets('principal é cheio na cor do jogo; secundário só contorno',
      (tester) async {
    await pumpPanel(
      tester,
      ResultPanel(
        palette: kLig4Palette,
        emoji: '🤝',
        title: 'Empate!',
        actions: [
          ResultAction('A', () {}),
          ResultAction('B', () {}, primary: false),
        ],
      ),
    );
    expect(find.widgetWithText(ElevatedButton, 'A'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'B'), findsOneWidget);
    final a = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'A'));
    expect(a.style!.backgroundColor!.resolve({}), kLig4Palette.accent);
  });

  testWidgets('sem mensagem não mostra a linha extra', (tester) async {
    await pumpPanel(
      tester,
      ResultPanel(
        palette: kTermoPalette,
        emoji: '🎉',
        title: 'Acertou!',
        actions: [ResultAction('Nova palavra', () {})],
      ),
    );
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
    expect(texts, ['🎉', 'Acertou!', 'Nova palavra']);
  });

  testWidgets('entra com animação e termina visível', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ResultPanel(
          palette: kTermoPalette,
          emoji: '🎉',
          title: 'Acertou!',
          actions: [ResultAction('OK', () {})],
        ),
      ),
    ));
    final opacity = find.descendant(
        of: find.byType(ResultPanel), matching: find.byType(Opacity));
    expect(tester.widget<Opacity>(opacity).opacity, lessThan(1));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(opacity).opacity, 1);
  });

  testWidgets('em 320 px os dois botões ficam na mesma linha, sem overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpPanel(
      tester,
      ResultPanel(
        palette: kMemoriaPalette,
        emoji: '🏆',
        title: 'Um nome bem comprido venceu!',
        message: 'Vitórias: 3 × 2',
        actions: [
          ResultAction('Próximo nível', () {}),
          ResultAction('Trocar jogadores', () {}, primary: false),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    final a = tester.getCenter(find.text('Próximo nível'));
    final b = tester.getCenter(find.text('Trocar jogadores'));
    expect(a.dy, moreOrLessEquals(b.dy, epsilon: 0.5));
    expect(tester.getSize(find.byType(ResultPanel)).height, lessThan(200));
  });
}
