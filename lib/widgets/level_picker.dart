// lib/widgets/level_picker.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_palette.dart';

/// Escolha de nível ou dificuldade, igual em todas as telas de início.
class LevelPicker extends StatelessWidget {
  const LevelPicker({
    super.key,
    required this.palette,
    required this.label,
    required this.levels,
    required this.selected,
    required this.onChanged,
  });

  final GamePalette palette;

  /// "Nível" ou "Dificuldade".
  final String label;
  final List<String> levels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: palette.dark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < levels.length; i++)
              ChoiceChip(
                label: Text(
                  levels[i],
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: i == selected ? Colors.white : palette.dark,
                  ),
                ),
                selected: i == selected,
                showCheckmark: false,
                selectedColor: palette.accent,
                backgroundColor: Colors.white,
                side: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
                onSelected: (_) => onChanged(i),
              ),
          ],
        ),
      ],
    );
  }
}
