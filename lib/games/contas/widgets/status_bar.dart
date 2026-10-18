// lib/games/contas/widgets/status_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/game_palette.dart';

/// Vidas, sequência de acertos, pontos e quanto falta para o próximo
/// multiplicador.
class StatusBar extends StatelessWidget {
  const StatusBar({
    super.key,
    required this.lives,
    required this.maxLives,
    required this.streak,
    required this.score,
    required this.multiplier,
    required this.maxMultiplier,
    required this.streakStep,
  });

  final int lives;
  final int maxLives;
  final int streak;
  final int score;
  final int multiplier;
  final int maxMultiplier;
  final int streakStep;

  @override
  Widget build(BuildContext context) {
    final atMax = multiplier >= maxMultiplier;
    final missing = streakStep - streak % streakStep;
    final style = GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < maxLives; i++)
                Icon(
                  i < lives ? Icons.favorite : Icons.favorite_border,
                  key: Key('vida-$i'),
                  color: const Color(0xFFEF4444),
                  size: 24,
                ),
              const Spacer(),
              Text('🔥 $streak', style: style.copyWith(color: const Color(0xFFEA580C))),
              const SizedBox(width: 16),
              Text('⭐ $score', style: style.copyWith(color: kContasPalette.dark)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: atMax ? 1.0 : (streak % streakStep) / streakStep,
              minHeight: 8,
              color: kContasPalette.light,
              backgroundColor: const Color(0xFFECFCCB),
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              atMax
                  ? '×$multiplier pontos'
                  : '×$multiplier pontos · faltam $missing para ×${multiplier + 1}',
              style: GoogleFonts.fredoka(fontSize: 12, color: kContasPalette.accent),
            ),
          ),
        ],
      ),
    );
  }
}
