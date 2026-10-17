// lib/games/lig4/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../../../widgets/player_setup.dart';
import '../../../widgets/score_board.dart';
import '../logic/ai.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/board_view.dart';

const _background = Color(0xFFFEF2F2);
const _dark = Color(0xFFB91C1C);
const _levels = ['Fácil', 'Médio', 'Difícil'];

class Lig4Screen extends StatelessWidget {
  const Lig4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Lig4Provider>();
    final title = p.phase != Lig4Phase.setup && p.mode == PlayMode.solo
        ? 'Lig 4 • ${_levels[AiLevel.values.indexOf(p.aiLevel)]}'
        : 'Lig 4';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          tooltip: 'Voltar ao menu',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _dark,
          ),
        ),
      ),
      body: SafeArea(
        child: p.phase == Lig4Phase.setup
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
      ),
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
          accent: kLig4Red,
        ),
        if (p.phase == Lig4Phase.playing)
          Text(
            turn,
            style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600, color: _dark),
          ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: BoardView()),
          ),
        ),
        if (p.phase == Lig4Phase.finished) const _ResultPanel(),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Lig4Provider>();
    final text = switch (p.winner) {
      null => '🤝 Empate!',
      Lig4Provider.computer when p.mode == PlayMode.solo => '🤖 O computador venceu!',
      1 => '🏆 ${p.name1} venceu!',
      _ => '🏆 ${p.name2} venceu!',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLig4Red.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: _dark),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: p.playAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kLig4Red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Jogar de novo', style: GoogleFonts.fredoka(fontSize: 16)),
              ),
              OutlinedButton(
                onPressed: p.exitToSetup,
                child: Text('Trocar jogadores', style: GoogleFonts.fredoka(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
