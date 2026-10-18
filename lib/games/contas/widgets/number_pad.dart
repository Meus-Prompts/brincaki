// lib/games/contas/widgets/number_pad.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/game_palette.dart';

/// Campo da resposta e teclado numérico com apagar e confirmar.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.typed,
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
  });

  final String typed;
  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    Widget digit(int d) => _Key(
          key: Key('tecla-$d'),
          onTap: () => onDigit(d),
          child: Text('$d'),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 160,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kContasPalette.light, width: 3),
            ),
            child: Text(
              typed,
              style: GoogleFonts.fredoka(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: kContasPalette.dark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              children: [
                for (final row in const [
                  [1, 2, 3],
                  [4, 5, 6],
                  [7, 8, 9],
                ])
                  _row([for (final d in row) digit(d)]),
                _row([
                  _Key(
                    key: const Key('tecla-apagar'),
                    onTap: onDelete,
                    child: const Icon(Icons.backspace_outlined, color: Color(0xFFB91C1C)),
                  ),
                  digit(0),
                  _Key(
                    key: const Key('tecla-ok'),
                    onTap: typed.isEmpty ? null : onSubmit,
                    filled: true,
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> keys) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: keys[i]),
            ],
          ],
        ),
      );
}

class _Key extends StatelessWidget {
  const _Key({super.key, required this.onTap, required this.child, this.filled = false});

  final VoidCallback? onTap;
  final Widget child;

  /// Botão cheio na cor do jogo (o confirmar).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = filled
        ? (enabled ? kContasPalette.accent : kContasPalette.light.withValues(alpha: 0.4))
        : Colors.white;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          child: Center(
            child: DefaultTextStyle(
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: kContasPalette.dark,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
