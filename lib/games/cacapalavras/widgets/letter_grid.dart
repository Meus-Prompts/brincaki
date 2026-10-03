// lib/games/cacapalavras/widgets/letter_grid.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

/// Cores das palavras encontradas, na ordem da lista de palavras.
const kFoundColors = [
  Color(0xFFA7F3D0),
  Color(0xFFBFDBFE),
  Color(0xFFFBCFE8),
  Color(0xFFFED7AA),
  Color(0xFFDDD6FE),
  Color(0xFFBBF7D0),
  Color(0xFFFECACA),
  Color(0xFFA5F3FC),
];

const _selectionColor = Color(0xFFFDE047);

class LetterGrid extends StatelessWidget {
  const LetterGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<WordSearchProvider>();
    final size = p.config.size;
    final selected = p.selectedCells.toSet();

    final foundColors = <(int, int), Color>{};
    for (var i = 0; i < p.words.length; i++) {
      final w = p.words[i];
      if (!p.found.contains(w.word)) continue;
      for (final cell in w.cells) {
        foundColors[cell] = kFoundColors[i % kFoundColors.length];
      }
    }

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / size;

          (int, int) toCell(Offset position) => (
                (position.dy / cellSize).floor().clamp(0, size - 1),
                (position.dx / cellSize).floor().clamp(0, size - 1),
              );

          return GestureDetector(
            // Começa a seleção onde o dedo encostou, não onde o arrasto foi
            // reconhecido.
            dragStartBehavior: DragStartBehavior.down,
            onPanStart: (d) {
              final (r, c) = toCell(d.localPosition);
              p.startSelection(r, c);
            },
            onPanUpdate: (d) {
              final (r, c) = toCell(d.localPosition);
              p.updateSelection(r, c);
            },
            onPanEnd: (_) => p.endSelection(),
            onPanCancel: p.endSelection,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var r = 0; r < size; r++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var c = 0; c < size; c++)
                            Expanded(
                              child: _LetterCell(
                                letter: p.grid[r][c],
                                fontSize: cellSize * 0.55,
                                background: selected.contains((r, c))
                                    ? _selectionColor
                                    : foundColors[(r, c)],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.letter,
    required this.fontSize,
    required this.background,
  });

  final String letter;
  final double fontSize;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.fredoka(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3B0764),
        ),
      ),
    );
  }
}
