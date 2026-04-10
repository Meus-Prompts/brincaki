// lib/games/tictactoe/widgets/score_banner.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

class ScoreBanner extends StatelessWidget {
  const ScoreBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TicTacToeProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
      ),
      child: Row(
        children: [
          _PlayerScore(
            name: p.player1Name,
            symbol: '❌',
            score: p.score1,
            isActive: p.phase == GamePhase.playing && p.currentPlayer == 1,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '🤝',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  '${p.draws}',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E),
                  ),
                ),
                Text(
                  'Empates',
                  style: GoogleFonts.fredoka(
                    fontSize: 11,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          _PlayerScore(
            name: p.player2Name,
            symbol: '⭕',
            score: p.score2,
            isActive: p.phase == GamePhase.playing && p.currentPlayer == 2,
            alignRight: true,
          ),
        ],
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final String name;
  final String symbol;
  final int score;
  final bool isActive;
  final bool alignRight;

  const _PlayerScore({
    required this.name,
    required this.symbol,
    required this.score,
    required this.isActive,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFEC4899).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(symbol, style: const TextStyle(fontSize: 20)),
            Text(
              name,
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFBE185D),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$score',
              style: GoogleFonts.fredoka(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
