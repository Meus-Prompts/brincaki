// lib/widgets/setup_header.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_palette.dart';

/// Emoji grande e nome do jogo no topo das telas de início.
class SetupHeader extends StatelessWidget {
  const SetupHeader({
    super.key,
    required this.palette,
    required this.emoji,
    required this.title,
  });

  final GamePalette palette;
  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: palette.accent,
          ),
        ),
      ],
    );
  }
}

/// Botão "Jogar!" das telas de início.
class StartButton extends StatelessWidget {
  const StartButton({super.key, required this.palette, required this.onPressed});

  final GamePalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          'Jogar!',
          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
