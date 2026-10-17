// lib/widgets/result_panel.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_palette.dart';

class ResultAction {
  const ResultAction(this.label, this.onPressed, {this.primary = true});

  final String label;
  final VoidCallback onPressed;

  /// Botão cheio na cor do jogo; senão, só com contorno.
  final bool primary;
}

/// Fim de partida: cartão no rodapé que deixa ver o tabuleiro final.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.palette,
    required this.emoji,
    required this.title,
    this.message,
    required this.actions,
  });

  final GamePalette palette;
  final String emoji;
  final String title;
  final String? message;
  final List<ResultAction> actions;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, 40 * (1 - t)),
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: palette.dark,
                    ),
                  ),
                ),
              ],
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontSize: 16, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [for (final action in actions) _button(action)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(ResultAction action) {
    final label = Text(
      action.label,
      style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
    );
    if (action.primary) {
      return ElevatedButton(
        onPressed: action.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: Colors.white,
        ),
        child: label,
      );
    }
    return OutlinedButton(
      onPressed: action.onPressed,
      style: OutlinedButton.styleFrom(foregroundColor: palette.dark),
      child: label,
    );
  }
}
