// lib/games/tictactoe/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/setup_form.dart';
import '../widgets/score_banner.dart';
import '../widgets/board_widget.dart';
import '../widgets/result_overlay.dart';

class TicTacToeScreen extends StatelessWidget {
  const TicTacToeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TicTacToeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF1F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFBE185D)),
          tooltip: 'Voltar ao menu',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text(
          'Jogo da Velha',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFBE185D),
          ),
        ),
      ),
      body: SafeArea(
        child: p.phase == GamePhase.setup
            ? const SetupForm()
            : _GameView(),
      ),
    );
  }
}

class _GameView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TicTacToeProvider>();

    return Column(
      children: [
        const ScoreBanner(),
        if (p.phase == GamePhase.playing) _TurnIndicator(),
        const Expanded(child: BoardWidget()),
        if (p.phase == GamePhase.result) const ResultOverlay(),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TurnIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TicTacToeProvider>();
    final name = p.currentPlayer == 1 ? p.player1Name : p.player2Name;
    final symbol = p.currentPlayer == 1 ? '❌' : '⭕';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        'Vez de $symbol $name!',
        style: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFBE185D),
        ),
      ),
    );
  }
}
