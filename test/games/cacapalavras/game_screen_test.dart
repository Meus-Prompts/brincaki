// test/games/cacapalavras/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/cacapalavras/models/game_state.dart';
import 'package:brincaki/games/cacapalavras/providers/game_provider.dart';
import 'package:brincaki/games/cacapalavras/screens/game_screen.dart';
import 'package:brincaki/games/cacapalavras/widgets/letter_grid.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/game_shell.dart';
import 'package:brincaki/widgets/result_panel.dart';

const _menuText = 'Menu de teste';

/// Menu mínimo que abre o jogo do mesmo jeito que o menu de verdade.
class _FakeMenu extends StatelessWidget {
  const _FakeMenu({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameShell(
                wrapProvider: (child) => ChangeNotifierProvider(
                  create: (_) => WordSearchProvider(random: Random(seed)),
                  child: child,
                ),
                theme: kCacaPalavrasPalette.theme,
                home: (_) => const CacaPalavrasScreen(),
              ),
            ),
          ),
          child: const Text(_menuText),
        ),
      ),
    );
  }
}

void useScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openGame(WidgetTester tester, {int seed = 11}) async {
  await tester.pumpWidget(MaterialApp(home: _FakeMenu(seed: seed)));
  await tester.tap(find.text(_menuText));
  await tester.pumpAndSettle();
}

WordSearchProvider providerOf(WidgetTester tester) => Provider.of<WordSearchProvider>(
      tester.element(find.byType(CacaPalavrasScreen)),
      listen: false,
    );

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> chooseLevel(WidgetTester tester, String label) async {
  await tapText(tester, label);
  await tapText(tester, 'Jogar!');
}

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

/// Encontra todas as palavras arrastando sobre a grade, alternando o sentido.
Future<void> findAllByDragging(WidgetTester tester) async {
  final p = providerOf(tester);
  final rect = tester.getRect(find.byType(LetterGrid));
  final size = p.config.size;
  final words = p.words;
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    final (from, to) = i.isEven
        ? (w.cells.first, w.cells.last)
        : (w.cells.last, w.cells.first);
    await drag(tester, cellCenter(rect, size, from), cellCenter(rect, size, to));
    expect(p.found, contains(w.word), reason: '${w.word} no nível ${p.level}');
    expect(tester.takeException(), isNull);
  }
  await tester.pumpAndSettle();
  expect(p.phase, WordSearchPhase.won);
}

void main() {
  for (final screen in const [Size(360, 740), Size(320, 568)]) {
    final label = '${screen.width.toInt()}x${screen.height.toInt()}';

    testWidgets('$label: fluxo completo do setup ao menu', (tester) async {
      useScreenSize(tester, screen);
      await openGame(tester);
      final p = providerOf(tester);

      // Tela de início.
      expect(p.phase, WordSearchPhase.setup);
      expect(find.text('🔍'), findsOneWidget);
      expect(find.text('Caça-Palavras'), findsWidgets);
      expect(find.text('1 • Animais'), findsOneWidget);
      expect(find.text('10 • Ciência'), findsOneWidget);
      expect(find.byType(LetterGrid), findsNothing);
      expect(tester.takeException(), isNull);

      // Escolhe o nível 3.
      await chooseLevel(tester, '3 • Cores');
      expect(find.text('Caça-Palavras • Nível 3 — Cores'), findsOneWidget);
      expect(find.byType(LetterGrid), findsOneWidget);
      expect(find.byType(ResultPanel), findsNothing);
      for (final w in p.words) {
        expect(find.text(w.word), findsOneWidget);
      }

      await findAllByDragging(tester);
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('Nível 3 completo!'), findsOneWidget);
      expect(find.text('Mudar nível'), findsOneWidget);
      // O painel não cobre a grade: dá para ver a grade final.
      expect(find.byType(LetterGrid), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Próximo nível.
      await tapText(tester, 'Próximo nível');
      expect(find.text('Caça-Palavras • Nível 4 — Corpo humano'), findsOneWidget);
      expect(find.byType(ResultPanel), findsNothing);
      expect(p.found, isEmpty);

      // Termina o 4 e vai para Mudar nível: volta ao setup com o 4 marcado.
      await findAllByDragging(tester);
      expect(find.text('Nível 4 completo!'), findsOneWidget);
      await tapText(tester, 'Mudar nível');
      expect(p.phase, WordSearchPhase.setup);
      expect(find.text('Caça-Palavras'), findsWidgets);
      final chip = tester.widget<ChoiceChip>(
        find.ancestor(of: find.text('4 • Corpo humano'), matching: find.byType(ChoiceChip)),
      );
      expect(chip.selected, isTrue);

      // Último nível: troféu e Jogar de novo volta ao nível 1.
      await chooseLevel(tester, '10 • Ciência');
      expect(find.text('Caça-Palavras • Nível 10 — Ciência'), findsOneWidget);
      await findAllByDragging(tester);
      expect(find.text('🏆'), findsOneWidget);
      expect(find.text('Você completou todos os níveis!'), findsOneWidget);
      expect(find.text('Próximo nível'), findsNothing);
      expect(find.text('Mudar nível'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tapText(tester, 'Jogar de novo');
      expect(find.text('Caça-Palavras • Nível 1 — Animais'), findsOneWidget);

      // Seta de voltar sai do jogo.
      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text(_menuText), findsOneWidget);
      expect(find.byType(CacaPalavrasScreen), findsNothing);
    });

    testWidgets('$label: Mudar nível no último nível volta ao setup', (tester) async {
      useScreenSize(tester, screen);
      await openGame(tester, seed: 3);
      await chooseLevel(tester, '10 • Ciência');
      await findAllByDragging(tester);
      await tapText(tester, 'Mudar nível');
      expect(find.text('Jogar!'), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text(_menuText), findsOneWidget);
    });
  }

  testWidgets('voltar no setup sai para o menu', (tester) async {
    await openGame(tester);
    await tester.tap(find.byTooltip('Voltar ao menu'));
    await tester.pumpAndSettle();
    expect(find.text(_menuText), findsOneWidget);
  });

  testWidgets('"voltar" do sistema na partida sai para o menu', (tester) async {
    await openGame(tester);
    await chooseLevel(tester, '2 • Frutas');
    expect(find.text('Caça-Palavras • Nível 2 — Frutas'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_menuText), findsOneWidget);
  });

  testWidgets('arrastar sobre uma palavra pinta a seleção e depois a marca', (tester) async {
    useScreenSize(tester, const Size(360, 740));
    await openGame(tester);
    await tapText(tester, 'Jogar!');
    final p = providerOf(tester);
    expect(p.level, 1);
    final rect = tester.getRect(find.byType(LetterGrid));
    final w = p.words.first;

    final gesture = await tester.startGesture(cellCenter(rect, 6, w.cells.first));
    await gesture.moveTo(cellCenter(rect, 6, w.cells.last));
    await tester.pump();
    expect(p.selectedCells, w.cells);
    await gesture.up();
    await tester.pump();
    expect(p.selectedCells, isEmpty);
    expect(p.found, {w.word});
  });

  testWidgets('arrasto que sai da grade fica preso na borda', (tester) async {
    useScreenSize(tester, const Size(360, 740));
    await openGame(tester);
    await tapText(tester, 'Jogar!');
    final p = providerOf(tester);
    final rect = tester.getRect(find.byType(LetterGrid));

    final gesture = await tester.startGesture(cellCenter(rect, 6, (0, 0)));
    await gesture.moveTo(rect.topRight + const Offset(100, 0));
    await tester.pump();
    expect(p.selectedCells.last, (0, 5));
    await gesture.up();
    await tester.pump();
  });

  testWidgets('tocar sem arrastar não marca nada', (tester) async {
    useScreenSize(tester, const Size(360, 740));
    await openGame(tester);
    await tapText(tester, 'Jogar!');
    final p = providerOf(tester);
    final rect = tester.getRect(find.byType(LetterGrid));
    await tester.tapAt(cellCenter(rect, 6, p.words.first.cells.first));
    await tester.pump();
    expect(p.found, isEmpty);
    expect(p.selectedCells, isEmpty);
  });
}
