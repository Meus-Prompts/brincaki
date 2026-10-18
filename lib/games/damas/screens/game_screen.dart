// lib/games/damas/screens/game_screen.dart

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

class DamasScreen extends StatelessWidget {
  const DamasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DamasProvider>();
    final title = p.phase != DamasPhase.setup && p.mode == PlayMode.solo
        ? 'Damas • ${_levels[AiLevel.values.indexOf(p.aiLevel)]}'
        : 'Damas';

    return GameScaffold(
      palette: kDamasPalette,
      title: title,
      confirmExit: p.phase == DamasPhase.playing,
      body: p.phase == DamasPhase.setup
          ? PlayerSetup(
              title: 'Damas',
              emoji: '⚫',
              palette: kDamasPalette,
              soloLabel: 'Contra o computador',
              symbols: ('⚪', '⚫'),
              levels: _levels,
              sides: ('Brancas', 'Pretas'),
              soloOpponentName: 'Computador',
              onStart: p.start,
            )
          : const _GameView(),
      result: p.phase == DamasPhase.finished ? _result(p) : null,
    );
  }

  Widget _result(DamasProvider p) {
    final winner = p.winnerPlayer;
    final (emoji, title) = switch (winner) {
      null => ('🤝', 'Empate!'),
      2 when p.mode == PlayMode.solo => ('🤖', 'O computador venceu!'),
      1 => ('🏆', '${p.name1} venceu!'),
      _ => ('🏆', '${p.name2} venceu!'),
    };
    final message = switch (p.game.end) {
      DamasEnd.noPieces => 'Sem peças para jogar',
      DamasEnd.noMoves => 'Sem jogadas possíveis',
      DamasEnd.repetition => 'A mesma posição 3 vezes',
      DamasEnd.twentyMoves => '20 lances só com damas',
      DamasEnd.fiveMoves => '5 lances no final de damas',
      null => null,
    };
    return ResultPanel(
      palette: kDamasPalette,
      emoji: emoji,
      title: title,
      message: message,
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
    final p = context.watch<DamasProvider>();
    final white = p.player1Side == DamasSide.white;
    final symbol1 = white ? '⚪' : '⚫';
    final symbol2 = white ? '⚫' : '⚪';
    final symbol = p.currentPlayer == 1 ? symbol1 : symbol2;
    final name = p.currentPlayer == 1 ? p.name1 : p.name2;
    var turn = p.isComputerTurn || p.aiThinking
        ? '🤖 Pensando...'
        : 'Vez de $symbol $name';
    if (p.mustCapture.isNotEmpty) turn += ' • Captura obrigatória!';

    return Column(
      children: [
        ScoreBoard(
          name1: p.name1,
          name2: p.name2,
          symbol1: symbol1,
          symbol2: symbol2,
          score1: p.wins1,
          score2: p.wins2,
          draws: p.draws,
          activePlayer: p.phase == DamasPhase.playing ? p.currentPlayer : null,
          accent: kDamasPalette.accent,
        ),
        if (p.phase == DamasPhase.playing)
          Text(
            turn,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kDamasPalette.dark,
            ),
          ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: DamasBoardView()),
          ),
        ),
      ],
    );
  }
}
