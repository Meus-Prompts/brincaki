// lib/games/sudoku/widgets/number_pad.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../providers/game_provider.dart';

/// Teclado de 1 a 9; cada tecla mostra quantos daquele número ainda faltam e
/// some quando o número já está completo.
class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SudokuProvider>();
    const palette = kSudokuPalette;

    return Row(
      children: List.generate(9, (index) {
        final number = index + 1;
        final remaining = provider.getRemainingCount(number);
        final isSelected = provider.numberFirstMode && provider.selectedNumber == number;
        final foreground = isSelected ? Colors.white : palette.dark;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              height: 52,
              child: remaining == 0
                  ? const SizedBox.shrink()
                  : ElevatedButton(
                      key: Key('pad-$number'),
                      onPressed: () => provider.selectNumber(number),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? palette.accent : Colors.white,
                        foregroundColor: foreground,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: palette.accent.withValues(alpha: isSelected ? 1 : 0.5),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$number',
                            style: GoogleFonts.fredoka(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                              color: foreground,
                            ),
                          ),
                          Text(
                            '$remaining',
                            style: GoogleFonts.fredoka(
                              fontSize: 11,
                              height: 1.0,
                              color: foreground.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }
}
