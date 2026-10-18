// lib/games/silabas/widgets/split_word.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/game_palette.dart';

const Color _kWrongColor = Color(0xFFDC2626);

/// A palavra com um espaço tocável entre cada par de letras vizinhas.
///
/// Os espaços têm 24 px de largura e a altura das letras. Eles ficam por cima
/// da divisa entre duas letras, então as letras podem encolher para a palavra
/// caber na tela sem que o toque fique pequeno.
class SplitWord extends StatelessWidget {
  const SplitWord({
    super.key,
    required this.palette,
    required this.text,
    required this.cuts,
    required this.wrongCuts,
    this.onToggle,
  });

  static const double gapWidth = 24;
  static const double _maxLetterWidth = 40;
  static const double _height = 64;

  final GamePalette palette;
  final String text;

  /// Posições dos cortes ligados (índice da letra depois do corte).
  final Set<int> cuts;

  /// Cortes ligados que estão no lugar errado (ficam vermelhos).
  final Set<int> wrongCuts;
  final ValueChanged<int>? onToggle;

  @override
  Widget build(BuildContext context) {
    final n = text.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth.isFinite
                ? constraints.maxWidth / n
                : _maxLetterWidth)
            .clamp(0.0, _maxLetterWidth);
        return Center(
          child: SizedBox(
            width: cell * n,
            height: _height,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (final letter in text.split(''))
                      SizedBox(
                        width: cell,
                        height: _height,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            letter,
                            style: GoogleFonts.fredoka(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: palette.dark,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                for (var pos = 1; pos < n; pos++)
                  Positioned(
                    left: pos * cell - gapWidth / 2,
                    width: gapWidth,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      key: Key('corte-$pos'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onToggle == null ? null : () => onToggle!(pos),
                      child: Center(child: _bar(pos)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bar(int pos) {
    final Color color;
    final double width;
    if (wrongCuts.contains(pos)) {
      color = _kWrongColor;
      width = 5;
    } else if (cuts.contains(pos)) {
      color = palette.accent;
      width = 5;
    } else {
      color = palette.accent.withValues(alpha: 0.25);
      width = 2;
    }
    return Container(
      width: width,
      height: _height - 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
