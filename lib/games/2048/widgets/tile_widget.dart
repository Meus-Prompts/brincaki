// lib/games/2048/widgets/tile_widget.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _tileColors = <int, Color>{
  2: Color(0xFFEEE4DA),
  4: Color(0xFFEDE0C8),
  8: Color(0xFFF2B179),
  16: Color(0xFFF59563),
  32: Color(0xFFF67C5F),
  64: Color(0xFFF65E3B),
  128: Color(0xFFEDCF72),
  256: Color(0xFFEDCC61),
  512: Color(0xFFEDC850),
  1024: Color(0xFFEDC53F),
  2048: Color(0xFFEDC22E),
};

Color tileColor(int value) {
  if (value == 0) return const Color(0xFFCDC1B4);
  return _tileColors[value] ?? const Color(0xFF3C3A32);
}

class TileWidget extends StatelessWidget {
  const TileWidget({
    super.key,
    required this.value,
    required this.isNew,
    required this.isMerged,
    required this.moveCount,
  });

  final int value;
  final bool isNew;
  final bool isMerged;

  /// Muda a cada jogada, para reiniciar a animação da peça.
  final int moveCount;

  @override
  Widget build(BuildContext context) {
    final face = _TileFace(value: value);
    if (value == 0 || (!isNew && !isMerged)) return face;

    return TweenAnimationBuilder<double>(
      key: ValueKey('$moveCount-${isNew ? 'new' : 'merged'}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 150),
      builder: (context, t, child) => Transform.scale(
        scale: isNew ? t : 1 + 0.15 * sin(pi * t),
        child: child,
      ),
      child: face,
    );
  }
}

class _TileFace extends StatelessWidget {
  const _TileFace({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final digits = value.toString().length;
        final fontSize = side * (digits <= 2 ? 0.45 : (digits == 3 ? 0.36 : 0.28));

        return Container(
          decoration: BoxDecoration(
            color: tileColor(value),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: value == 0
              ? null
              : Text(
                  '$value',
                  style: GoogleFonts.fredoka(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: value <= 4 ? const Color(0xFF776E65) : Colors.white,
                  ),
                ),
        );
      },
    );
  }
}
