// lib/widgets/score_board.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Placar de dois jogadores com empates no centro.
class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.name1,
    required this.name2,
    required this.symbol1,
    required this.symbol2,
    required this.score1,
    required this.score2,
    required this.draws,
    this.activePlayer,
    required this.accent,
  });

  final String name1;
  final String name2;
  final String symbol1;
  final String symbol2;
  final int score1;
  final int score2;
  final int draws;
  final int? activePlayer;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PlayerScore(
              name: name1,
              symbol: symbol1,
              score: score1,
              active: activePlayer == 1,
              accent: accent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                const Text('🤝', style: TextStyle(fontSize: 18)),
                Text(
                  '$draws',
                  style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Empates',
                  style: GoogleFonts.fredoka(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: _PlayerScore(
              name: name2,
              symbol: symbol2,
              score: score2,
              active: activePlayer == 2,
              accent: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  const _PlayerScore({
    required this.name,
    required this.symbol,
    required this.score,
    required this.active,
    required this.accent,
  });

  final String name;
  final String symbol;
  final int score;
  final bool active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(symbol, style: const TextStyle(fontSize: 22)),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            '$score',
            style: GoogleFonts.fredoka(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
