// lib/games/tictactoe/widgets/result_overlay.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class ResultOverlay extends StatelessWidget {
  const ResultOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TicTacToeProvider>();

    final String emoji;
    final String message;

    if (p.winner == null) {
      emoji = '🤝';
      message = 'Empate!';
    } else if (p.winner == 1) {
      emoji = '🏆';
      message = '❌ ${p.player1Name} venceu!';
    } else {
      emoji = '🏆';
      message = '⭕ ${p.player2Name} venceu!';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFBBF24), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fredoka(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFBE185D),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.read<TicTacToeProvider>().playAgain(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Jogar novamente',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.read<TicTacToeProvider>().exitGame(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBE185D),
                    side: const BorderSide(color: Color(0xFFEC4899)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sair',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
