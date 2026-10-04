// lib/games/termo/widgets/termo_keyboard.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import 'guess_grid.dart';

const _rows = [
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
  ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
];

class TermoKeyboard extends StatelessWidget {
  const TermoKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TermoProvider>();
    final colors = p.keyboard;

    return Column(
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                if (row.length == 9 && row.first == 'A') const Spacer(flex: 5),
                for (final label in row)
                  Expanded(
                    flex: label.length > 1 ? 15 : 10,
                    child: _Key(
                      label: label,
                      color: colors[label] == null
                          ? const Color(0xFFE2E8F0)
                          : resultColor(colors[label]!),
                      onTap: () {
                        if (label == 'ENTER') {
                          p.submit();
                        } else if (label == '⌫') {
                          p.backspace();
                        } else {
                          p.type(label);
                        }
                      },
                    ),
                  ),
                if (row.length == 9 && row.first == 'A') const Spacer(flex: 5),
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = color == const Color(0xFFE2E8F0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: Key('key-$label'),
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Center(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: light ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
