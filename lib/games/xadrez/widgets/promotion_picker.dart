// lib/games/xadrez/widgets/promotion_picker.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/game_palette.dart';
import '../models/game_state.dart';
import 'chess_piece.dart';

/// Escolha da peça da promoção, sobre o tabuleiro.
class PromotionPicker extends StatelessWidget {
  const PromotionPicker({
    super.key,
    required this.side,
    required this.onPick,
    required this.onCancel,
  });

  final ChessSide side;
  final ValueChanged<int> onPick;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final sign = side == ChessSide.white ? 1 : -1;
    return Positioned.fill(
      // Tocar no fundo escuro fecha sem escolher: cancela o lance.
      child: GestureDetector(
        key: const Key('promo-backdrop'),
        behavior: HitTestBehavior.opaque,
        onTap: onCancel,
        child: ColoredBox(
          color: const Color(0xCC000000),
          child: Center(
            // O cartão absorve o toque para não cancelar por engano.
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kXadrezPalette.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Promover para:',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: kXadrezPalette.dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: [
                        for (final t in const [5, 4, 3, 2])
                          InkWell(
                            key: Key('promo-$t'),
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => onPick(t),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kXadrezPalette.light.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ChessPiece(value: t * sign, size: 40),
                            ),
                          ),
                      ],
                    ),
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
