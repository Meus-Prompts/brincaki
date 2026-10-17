// lib/games/lig4/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../../../widgets/game_scaffold.dart';
import '../../../widgets/player_setup.dart';
import '../../../widgets/result_panel.dart';
import '../../../widgets/score_board.dart';
import '../logic/ai.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/board_view.dart';

const _levels = ['Fácil', 'Médio', 'Difícil'];

class Lig4Screen extends StatelessWidget {
  const Lig4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Lig4Provider>();
    final title = p.phase != Lig4Phase.setup && p.mode == PlayMode.solo
        ? 'Lig 4 • ${_levels[AiLevel.values.indexOf(p.aiLevel)]}'
        : 'Lig 4';

    return GameScaffold(
      palette: kLig4Palette,
      title: title,
      body: p.phase == Lig4Phase.setup
          ? PlayerSetup(
              title: 'Lig 4',
              emoji: '🔴',
              palette: kLig4Palette,
              soloLabel: 'Contra o computador',
              symbols: ('🔴', '🟡'),
              levels: _levels,
              soloOpponentName: 'Computador',
              onStart: p.start,
            )
          : const _GameView(),
      result: p.phase == Lig4Phase.finished ? _result(p) : null,
    );
  }

  Widget _result(Lig4Provider p) {
    final (emoji, title) = switch (p.winner) {
      null => ('🤝', 'Empate!'),
      Lig4Provider.computer when p.mode == PlayMode.solo =>
        ('🤖', 'O computador venceu!'),
      1 => ('🏆', '${p.name1} venceu!'),
      _ => ('🏆', '${p.name2} venceu!'),
    };
    return ResultPanel(
      palette: kLig4Palette,
      emoji: emoji,
      title: title,
      actions: [
        ResultAction('Jogar de novo', p.playAgain),
        ResultAction('Trocar jogadores', p.exitToSetup, primary: false),
      ],
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Lig4Provider>();
    final symbol = p.currentPlayer == 1 ? '🔴' : '🟡';
    final name = p.currentPlayer == 1 ? p.name1 : p.name2;
    final turn = p.isComputerTurn || p.aiThinking ? '🤖 Pensando...' : 'Vez de $symbol $name';

    return Column(
      children: [
        ScoreBoard(
          name1: p.name1,
          name2: p.name2,
          symbol1: '🔴',
          symbol2: '🟡',
          score1: p.wins1,
          score2: p.wins2,
          draws: p.draws,
          activePlayer: p.phase == Lig4Phase.playing ? p.currentPlayer : null,
          accent: kLig4Palette.accent,
        ),
        if (p.phase == Lig4Phase.playing)
          Text(
            turn,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kLig4Palette.dark,
            ),
          ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: BoardView()),
          ),
        ),
      ],
    );
  }
}
