// test/widgets/player_setup_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/widgets/game_palette.dart';
import 'package:brincaki/widgets/player_setup.dart';

void main() {
  PlayerSetupResult? result;

  Future<void> pumpSetup(WidgetTester tester,
      {List<String>? levels, String? opponent}) async {
    result = null;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayerSetup(
          title: 'Lig 4',
          emoji: '🔴',
          palette: kLig4Palette,
          soloLabel: 'Contra o computador',
          symbols: ('🔴', '🟡'),
          levels: levels,
          soloOpponentName: opponent,
          onStart: (r) => result = r,
        ),
      ),
    ));
  }

  testWidgets('solo sem nome usa os nomes padrão e o primeiro nível',
      (tester) async {
    await pumpSetup(tester,
        levels: ['Fácil', 'Médio', 'Difícil'], opponent: 'Computador');
    await tester.tap(find.text('Jogar!'));
    expect(result!.mode, PlayMode.solo);
    expect(result!.player1, 'Jogador 1');
    expect(result!.player2, 'Computador');
    expect(result!.levelIndex, 0);
  });

  testWidgets('solo com nível escolhido', (tester) async {
    await pumpSetup(tester,
        levels: ['Fácil', 'Médio', 'Difícil'], opponent: 'Computador');
    await tester.enterText(find.byKey(const Key('name1')), '  Ana  ');
    await tester.tap(find.text('Difícil'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    expect(result!.player1, 'Ana');
    expect(result!.levelIndex, 2);
  });

  testWidgets('dois jogadores mostra dois nomes e esconde os níveis',
      (tester) async {
    await pumpSetup(tester,
        levels: ['Fácil', 'Médio', 'Difícil'], opponent: 'Computador');
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    expect(find.text('Médio'), findsNothing);
    await tester.enterText(find.byKey(const Key('name1')), 'Ana');
    await tester.enterText(find.byKey(const Key('name2')), 'Beto');
    await tester.tap(find.text('Jogar!'));
    expect(result!.mode, PlayMode.twoPlayers);
    expect(result!.player1, 'Ana');
    expect(result!.player2, 'Beto');
    expect(result!.levelIndex, isNull);
  });

  testWidgets('dois jogadores sem nomes usa Jogador 1 e Jogador 2',
      (tester) async {
    await pumpSetup(tester);
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    expect(result!.player1, 'Jogador 1');
    expect(result!.player2, 'Jogador 2');
  });

  testWidgets('solo sem adversário (Memória) deixa player2 vazio',
      (tester) async {
    await pumpSetup(tester);
    await tester.tap(find.text('Jogar!'));
    expect(result!.player2, '');
    expect(result!.levelIndex, isNull);
  });

  testWidgets('cabe num celular pequeno', (tester) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpSetup(tester,
        levels: ['Fácil', 'Médio', 'Difícil'], opponent: 'Computador');
    expect(tester.takeException(), isNull);
  });
}
