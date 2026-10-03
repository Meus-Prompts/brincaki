// lib/games/cacapalavras/widgets/word_list.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
        color: found ? const Color(0xFFEDE9FE) : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFC4B5FD)),
      ),
      child: Text(
        word,
        style: GoogleFonts.fredoka(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: found ? const Color(0xFFA78BFA) : const Color(0xFF5B21B6),
          decoration: found ? TextDecoration.lineThrough : null,
          decorationThickness: 2,
        ),
      ),
    );
  }
}
