// lib/games/contas/widgets/choice_grid.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/game_palette.dart';

/// As 4 opções de resposta em grade 2×2. Um toque já responde.
class ChoiceGrid extends StatelessWidget {
  const ChoiceGrid({super.key, required this.choices, required this.onChoose});

  final List<int> choices;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    Widget option(int value) => Material(
          key: Key('opcao-$value'),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onChoose(value),
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 72,
              child: Center(
                child: Text(
                  '$value',
                  style: GoogleFonts.fredoka(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: kContasPalette.dark,
                  ),
                ),
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          children: [
            for (var row = 0; row < choices.length; row += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: option(choices[row])),
                    const SizedBox(width: 12),
                    Expanded(child: option(choices[row + 1])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
