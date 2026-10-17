// test/widgets/game_scaffold_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_scaffold.dart';
import 'package:brincaki/widgets/game_shell.dart';

/// Menu de mentira com um botão que abre o jogo dentro de um GameShell.
Future<void> pumpGame(
  WidgetTester tester, {
  bool confirmExit = false,
  Widget? result,
  List<Widget>? actions,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameShell(
                  theme: kVelhaPalette.theme,
                  home: (_) => GameScaffold(
                    palette: kVelhaPalette,
                    title: 'Jogo • Nível 2',
                    confirmExit: confirmExit,
                    actions: actions,
                    result: result,
                    body: const Text('corpo do jogo'),
                  ),
                ),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra título, corpo, ações e cores da paleta', (tester) async {
    await pumpGame(tester, actions: [const Text('00:10')]);
    expect(find.text('Jogo • Nível 2'), findsOneWidget);
    expect(find.text('corpo do jogo'), findsOneWidget);
    expect(find.text('00:10'), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, kVelhaPalette.background);
    final title = tester.widget<Text>(find.text('Jogo • Nível 2'));
    expect(title.style!.color, kVelhaPalette.dark);
  });

  testWidgets('resultado aparece abaixo do corpo', (tester) async {
    await pumpGame(tester, result: const Text('resultado'));
    final body = tester.getCenter(find.text('corpo do jogo'));
    final result = tester.getCenter(find.text('resultado'));
    expect(result.dy, greaterThan(body.dy));
  });

  testWidgets('sem resultado, só o corpo', (tester) async {
    await pumpGame(tester);
    expect(find.text('resultado'), findsNothing);
  });

  testWidgets('seta de voltar sai direto para o menu', (tester) async {
    await pumpGame(tester);
    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    expect(find.text('abrir'), findsOneWidget);
    expect(find.text('corpo do jogo'), findsNothing);
  });

  testWidgets('voltar do sistema sai para o menu', (tester) async {
    await pumpGame(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('abrir'), findsOneWidget);
  });

  group('confirmExit', () {
    testWidgets('seta pergunta; "Continuar jogando" fica no jogo',
        (tester) async {
      await pumpGame(tester, confirmExit: true);
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text('Sair do jogo?'), findsOneWidget);
      expect(find.text('O progresso desta partida será perdido.'), findsOneWidget);
      await tester.tap(find.text('Continuar jogando'));
      await tester.pumpAndSettle();
      expect(find.text('Sair do jogo?'), findsNothing);
      expect(find.text('corpo do jogo'), findsOneWidget);
    });

    testWidgets('seta pergunta; "Sair" volta ao menu', (tester) async {
      await pumpGame(tester, confirmExit: true);
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(find.text('abrir'), findsOneWidget);
      expect(find.text('corpo do jogo'), findsNothing);
    });

    testWidgets('tocar fora do diálogo conta como continuar', (tester) async {
      await pumpGame(tester, confirmExit: true);
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Sair do jogo?'), findsNothing);
      expect(find.text('corpo do jogo'), findsOneWidget);
    });

    testWidgets('voltar do sistema também pergunta', (tester) async {
      await pumpGame(tester, confirmExit: true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Sair do jogo?'), findsOneWidget);
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(find.text('abrir'), findsOneWidget);
    });
  });
}
