// lib/games/xadrez/widgets/chess_piece.dart

import 'package:flutter/material.dart';

// Deslocamento do glifo a partir de U+2654 (branco) ou U+265A (preto).
const _offsets = {6: 0, 5: 1, 4: 2, 3: 3, 2: 4, 1: 5};

/// Peça de xadrez: `value` positivo é das brancas, negativo das pretas.
class ChessPiece extends StatelessWidget {
  const ChessPiece({super.key, required this.value, required this.size});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final offset = _offsets[value.abs()]!;
    final filled = String.fromCharCode(0x265A + offset);
    final outline = String.fromCharCode(0x2654 + offset);
    final white = value > 0;
    TextStyle style(Color color) => TextStyle(
      fontFamily: 'ChessSymbols',
      fontSize: size,
      height: 1,
      color: color,
    );
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              filled,
              style: style(white ? Colors.white : const Color(0xFF1A1A1A)),
            ),
            if (white) Text(outline, style: style(const Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }
}
