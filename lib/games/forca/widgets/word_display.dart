import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WordDisplay extends StatelessWidget {
  /// Palavra completa (maiúsculo, sem acento).
  final String word;

  /// Conjunto de letras corretamente adivinhadas.
  final Set<String> correctLetters;

  const WordDisplay({
    super.key,
    required this.word,
    required this.correctLetters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: word.split('').map((letter) {
          final revealed = correctLetters.contains(letter);
          return _LetterSlot(letter: letter, revealed: revealed);
        }).toList(),
      ),
    );
  }
}

class _LetterSlot extends StatelessWidget {
  final String letter;
  final bool revealed;

  const _LetterSlot({required this.letter, required this.revealed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              revealed ? letter : ' ',
              key: ValueKey(revealed),
              style: GoogleFonts.fredoka(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
