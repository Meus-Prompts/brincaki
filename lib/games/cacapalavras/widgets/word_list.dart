// lib/games/cacapalavras/widgets/word_list.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../providers/game_provider.dart';

class WordList extends StatelessWidget {
  const WordList({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<WordSearchProvider>();
    final words = p.words.map((w) => w.word).toList()..sort();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final word in words)
          _WordChip(word: word, found: p.found.contains(word)),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.found});

  final String word;
  final bool found;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: found ? const Color(0xFFFEF3C7) : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: kCacaPalavrasPalette.light),
      ),
      child: Text(
        word,
        style: GoogleFonts.fredoka(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: found ? const Color(0xFFD97706) : kCacaPalavrasPalette.dark,
          decoration: found ? TextDecoration.lineThrough : null,
          decorationThickness: 2,
        ),
      ),
    );
  }
}
