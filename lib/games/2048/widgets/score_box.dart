// lib/games/2048/widgets/score_box.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoreBox extends StatelessWidget {
  const ScoreBox({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEEE4DA),
            ),
          ),
          Text(
            '$value',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
