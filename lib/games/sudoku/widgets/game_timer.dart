// lib/games/sudoku/widgets/game_timer.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../providers/game_provider.dart';

/// Cronômetro da partida, no canto da AppBar.
class GameTimer extends StatelessWidget {
  const GameTimer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SudokuProvider>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, color: kSudokuPalette.accent, size: 20),
        const SizedBox(width: 4),
        Text(
          provider.formattedTime,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kSudokuPalette.dark,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
