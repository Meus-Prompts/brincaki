// test/screens/menu_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brincaki/main.dart';

const _menuSubtitle = 'Escolha um jogo para brincar!';

/// Avança o relógio em passos, para animações encadeadas (fechar diálogo e
/// depois a tela). Não usa pumpAndSettle porque a partida de Sudoku tem um
/// cronômetro periódico.
Future<void> pumpSteps(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> openGame(WidgetTester tester, String title) async {
  // O card do 2048 tem o texto "2048" no título e no ícone.
  final card = find.text(title).first;
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('menu mostra os 8 jogos', (tester) async {
    await tester.pumpWidget(const BrincakiApp());
    await tester.pumpAndSettle();
    for (final title in [
      'Caça-Palavras',
      'Sudoku',
      '2048',
      'Jogo da Velha',
      'Jogo da Forca',
      'Jogo da Memória',
      'Termo',
      'Lig 4',
    ]) {
      await tester.ensureVisible(find.text(title).first);
      expect(find.text(title), findsWidgets);
    }
  });

  // Texto que só existe na primeira tela de cada jogo.
  final games = <String, Finder>{
    'Caça-Palavras': find.textContaining('Caça-Palavras • Nível 1'),
    'Sudoku': find.text('Selecione a dificuldade'),
    '2048': find.text('Novo jogo'),
    'Jogo da Velha': find.text('Jogo da Velha'),
    'Jogo da Forca': find.textContaining('Jogo da Forca  •  Nível 1'),
    'Jogo da Memória': find.text('Sozinho'),
    'Termo': find.text('Ilimitado'),
    'Lig 4': find.text('Contra o computador'),
  };

  for (final entry in games.entries) {
    testWidgets('${entry.key}: abre pelo card e volta pela seta', (tester) async {
      await tester.pumpWidget(const BrincakiApp());
      await tester.pumpAndSettle();

      await openGame(tester, entry.key);
      expect(entry.value, findsWidgets);
      expect(find.text(_menuSubtitle), findsNothing);

      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text(_menuSubtitle), findsOneWidget);
    });

    testWidgets('${entry.key}: "voltar" do sistema volta ao menu', (tester) async {
      await tester.pumpWidget(const BrincakiApp());
      await tester.pumpAndSettle();

      await openGame(tester, entry.key);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(_menuSubtitle), findsOneWidget);
    });
  }

  testWidgets('Sudoku: "voltar" na partida confirma, volta à dificuldade e depois ao menu',
      (tester) async {
    await tester.pumpWidget(const BrincakiApp());
    await tester.pumpAndSettle();
    await openGame(tester, 'Sudoku');

    await tester.tap(find.text('Fácil'));
    await pumpSteps(tester);
    expect(find.text('Selecione a dificuldade'), findsNothing);

    await tester.binding.handlePopRoute();
    await pumpSteps(tester);
    expect(find.text('Sair do Jogo'), findsOneWidget);

    await tester.tap(find.text('Sair'));
    await pumpSteps(tester);
    expect(find.text('Selecione a dificuldade'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_menuSubtitle), findsOneWidget);
  });
}
