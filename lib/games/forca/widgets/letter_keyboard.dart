// lib/games/forca/widgets/letter_keyboard.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';

const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

class LetterKeyboard extends StatelessWidget {
  final Map<String, LetterState> letterStates;
  final ValueChanged<String> onLetterTap;
  final bool disabled;

  const LetterKeyboard({
    super.key,
    required this.letterStates,
    required this.onLetterTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: _alphabet.split('').map((letter) {
          final state = letterStates[letter] ?? LetterState.unguessed;
          return _LetterButton(
            key: ValueKey('tecla-$letter'),
            letter: letter,
            state: state,
            onTap: disabled ? null : () => onLetterTap(letter),
          );
        }).toList(),
      ),
    );
  }
}

class _LetterButton extends StatelessWidget {
  final String letter;
  final LetterState state;
  final VoidCallback? onTap;

  const _LetterButton({
    super.key,
    required this.letter,
    required this.state,
    this.onTap,
  });

  Color get _backgroundColor {
    return switch (state) {
      LetterState.correct => const Color(0xFF16A34A),
      LetterState.wrong => const Color(0xFFDC2626),
      LetterState.unguessed => const Color(0xFFE2E8F0),
    };
  }

  Color get _textColor {
    return switch (state) {
      LetterState.correct || LetterState.wrong => Colors.white,
      LetterState.unguessed => const Color(0xFF1E293B),
    };
  }

  @override
  Widget build(BuildContext context) {
    final interactive = state == LetterState.unguessed && onTap != null;
    return GestureDetector(
      onTap: interactive ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: interactive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            letter,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ),
      ),
    );
  }
}
