// lib/games/tictactoe/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../../../widgets/game_scaffold.dart';
import '../../../widgets/player_setup.dart';
import '../../../widgets/result_panel.dart';
import '../../../widgets/score_board.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';

const _title = 'Jogo da Velha';
const _levels = ['Fácil', 'Médio', 'Difícil'];

class TicTacToeScreen extends StatelessWidget {
  const TicTacToeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TicTacToeProvider>();
    final setup = p.phase == GamePhase.setup;
    final title = !setup && p.mode == PlayMode.solo
        ? '$_title • ${_levels[p.aiLevel.index]}'
        : _title;

    return GameScaffold(
      palette: kVelhaPalette,
      title: title,
      body: setup
          ? PlayerSetup(
              title: _title,
              emoji: '❌⭕',
              palette: kVelhaPalette,
              soloLabel: 'Contra o computador',
              symbols: ('❌', '⭕'),
              levels: _levels,
              soloOpponentName: 'Computador',
              onStart: p.start,
            )
          : const _GameBody(),
      result: p.phase == GamePhase.finished ? const _Result() : null,
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TicTacToeProvider>();
    final name = p.currentPlayer == 1 ? p.name1 : p.name2;
    final turn = p.isComputerTurn || p.aiThinking
        ? '🤖 Pensando...'
        : 'Vez de ${symbolOf(p.currentPlayer)} $name';

    return Column(
      children: [
        ScoreBoard(
          name1: p.name1,
          name2: p.name2,
          symbol1: symbolOf(1),
          symbol2: symbolOf(2),
          score1: p.wins1,
          score2: p.wins2,
          draws: p.draws,
          activePlayer: p.phase == GamePhase.playing ? p.currentPlayer : null,
          accent: kVelhaPalette.accent,
        ),
        if (p.phase == GamePhase.playing)
          Text(
            turn,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kVelhaPalette.dark,
            ),
          ),
        const Expanded(child: Center(child: BoardWidget())),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TicTacToeProvider>();
    final (emoji, title) = switch (p.winner) {
      null => ('🤝', 'Empate!'),
      TicTacToeProvider.computer when p.mode == PlayMode.solo => ('🤖', 'O computador venceu!'),
      1 => ('🏆', '${p.name1} venceu!'),
      _ => ('🏆', '${p.name2} venceu!'),
    };

    return ResultPanel(
      palette: kVelhaPalette,
      emoji: emoji,
      title: title,
      actions: [
        ResultAction('Jogar de novo', p.playAgain),
        ResultAction('Trocar jogadores', p.exitToSetup, primary: false),
      ],
    );
  }
}
