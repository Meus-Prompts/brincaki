// lib/games/silabas/widgets/syllable_blocks.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/game_palette.dart';

const Color _kWrongColor = Color(0xFFDC2626);

/// As sílabas da palavra como blocos (etapas 2, 3 e palavra resolvida).
class SyllableBlocks extends StatelessWidget {
  const SyllableBlocks({
    super.key,
    required this.palette,
    required this.syllables,
    this.highlighted,
    this.wrong = const {},
    this.onTap,
  });

  final GamePalette palette;
  final List<String> syllables;

  /// Índice da sílaba tônica destacada (cor cheia, texto branco).
  final int? highlighted;

  /// Sílabas tocadas por engano: vermelhas e sem toque.
  final Set<int> wrong;

  /// Sem [onTap], os blocos não respondem a toques.
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [for (var i = 0; i < syllables.length; i++) _block(i)],
    );
  }

  Widget _block(int i) {
    final isHighlighted = i == highlighted;
    final isWrong = wrong.contains(i);
    final Color background = isHighlighted ? palette.accent : Colors.white;
    final Color foreground = isHighlighted
        ? Colors.white
        : (isWrong ? _kWrongColor : palette.dark);
    final Color border = isWrong ? _kWrongColor : palette.accent;
    final tappable = onTap != null && !isWrong;
    return GestureDetector(
      key: Key('silaba-$i'),
      behavior: HitTestBehavior.opaque,
      onTap: tappable ? () => onTap!(i) : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2),
        ),
        child: Text(
          syllables[i],
          style: GoogleFonts.fredoka(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
