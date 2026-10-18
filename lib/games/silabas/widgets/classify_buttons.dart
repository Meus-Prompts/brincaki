// lib/games/silabas/widgets/classify_buttons.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/game_palette.dart';
import '../logic/word.dart';
import '../models/game_state.dart';

const Color _kWrongColor = Color(0xFFDC2626);
const Color _kCorrectColor = Color(0xFF16A34A);

/// Os três botões de classificação: oxítona, paroxítona e proparoxítona.
class ClassifyButtons extends StatelessWidget {
  const ClassifyButtons({
    super.key,
    required this.palette,
    this.wrong = const {},
    this.correct,
    this.onChoose,
  });

  final GamePalette palette;

  /// Classes já tentadas por engano: vermelhas e desabilitadas.
  final Set<StressClass> wrong;

  /// Classe certa, em verde.
  final StressClass? correct;

  /// Sem [onChoose], os botões ficam desabilitados.
  final ValueChanged<StressClass>? onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final c in StressClass.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _button(c),
          ),
      ],
    );
  }

  Widget _button(StressClass c) {
    final isWrong = wrong.contains(c);
    final isCorrect = correct == c;
    final Color background = isCorrect
        ? _kCorrectColor
        : (isWrong ? _kWrongColor.withValues(alpha: 0.12) : Colors.white);
    final Color foreground = isCorrect
        ? Colors.white
        : (isWrong ? _kWrongColor : palette.dark);
    final Color border = isCorrect
        ? _kCorrectColor
        : (isWrong ? _kWrongColor : palette.accent);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: Key('classe-${c.name}'),
        onPressed: onChoose == null || isWrong ? null : () => onChoose!(c),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background,
          disabledForegroundColor: foreground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: border, width: 2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stressClassLabel(c),
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              stressClassHint(c),
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
