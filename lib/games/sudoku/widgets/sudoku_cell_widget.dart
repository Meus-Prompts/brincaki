// lib/games/sudoku/widgets/sudoku_cell_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/game_palette.dart';
import '../models/sudoku_cell.dart';

/// Vermelho dos números em conflito.
const kSudokuError = Color(0xFFDC2626);

/// Cinza-escuro dos números que já vêm no tabuleiro.
const kSudokuFixed = Color(0xFF1F2937);

class SudokuCellWidget extends StatelessWidget {
  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.isSelected,
    required this.isHighlighted,
    required this.isSameNumber,
    required this.onTap,
  });

  final SudokuCell cell;
  final bool isSelected;
  final bool isHighlighted;
  final bool isSameNumber;
  final VoidCallback onTap;

  Color get backgroundColor {
    const palette = kSudokuPalette;
    if (isSelected) return palette.accent.withValues(alpha: 0.45);
    if (cell.isError) return kSudokuError.withValues(alpha: 0.12);
    if (isSameNumber && !cell.isEmpty) return palette.accent.withValues(alpha: 0.25);
    if (isHighlighted) return palette.background;
    return Colors.white;
  }

  Color get textColor {
    if (cell.isError) return kSudokuError;
    if (cell.isFixed) return kSudokuFixed;
    return kSudokuPalette.dark;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        child: Center(
          child: cell.isEmpty
              ? null
              : FittedBox(
                  child: Text(
                    cell.value.toString(),
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: cell.isFixed ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
