// lib/games/xadrez/screens/game_screen.dart

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

String _levelLabel(AiLevel level) => switch (level) {
  AiLevel.easy => 'Fácil',
  AiLevel.medium => 'Médio',
  AiLevel.hard => 'Difícil',
};

class XadrezScreen extends StatelessWidget {
  const XadrezScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<XadrezProvider>();
    final title = p.phase != XadrezPhase.setup && p.mode == PlayMode.solo
        ? 'Xadrez • ${_levelLabel(p.aiLevel)}'
        : 'Xadrez';

    return GameScaffold(
      palette: kXadrezPalette,
      title: title,
      confirmExit: p.phase == XadrezPhase.playing,
      body: p.phase == XadrezPhase.setup
          ? PlayerSetup(
              title: 'Xadrez',
              emoji: '♟️',
              palette: kXadrezPalette,
              soloLabel: 'Contra o computador',
              symbols: ('⚪', '⚫'),
              levels: _levels,
              sides: ('Brancas', 'Pretas'),
              soloOpponentName: 'Computador',
              onStart: p.start,
            )
          : const _GameView(),
      result: p.phase == XadrezPhase.finished ? _result(p) : null,
    );
  }

  Widget _result(XadrezProvider p) {
    final (emoji, title) = switch (p.winnerPlayer) {
      null => ('🤝', 'Empate!'),
      2 when p.mode == PlayMode.solo => ('🤖', 'O computador venceu!'),
      1 => ('🏆', '${p.name1} venceu!'),
      _ => ('🏆', '${p.name2} venceu!'),
    };
    final message = switch (p.game.end) {
      XadrezEnd.checkmate => 'Xeque-mate!',
      XadrezEnd.stalemate => 'Afogamento',
      XadrezEnd.insufficientMaterial => 'Só sobraram peças que não dão mate',
      XadrezEnd.fiftyMoves => '50 lances sem captura nem peão',
      XadrezEnd.repetition => 'A mesma posição 3 vezes',
      null => null,
    };
    return ResultPanel(
      palette: kXadrezPalette,
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
    final p = context.watch<XadrezProvider>();
    final white = p.player1Side == ChessSide.white;
    final symbol1 = white ? '⚪' : '⚫';
    final symbol2 = white ? '⚫' : '⚪';
    final symbol = p.currentPlayer == 1 ? symbol1 : symbol2;
    final name = p.currentPlayer == 1 ? p.name1 : p.name2;
    var turn = p.isComputerTurn || p.aiThinking
        ? '🤖 Pensando...'
        : 'Vez de $symbol $name';
    if (p.checkSquare != null) turn += ' • Xeque!';

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
          activePlayer: p.phase == XadrezPhase.playing ? p.currentPlayer : null,
          accent: kXadrezPalette.accent,
        ),
        if (p.phase == XadrezPhase.playing)
          Text(
            turn,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kXadrezPalette.dark,
            ),
          ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: XadrezBoardView()),
          ),
        ),
      ],
    );
  }
}
