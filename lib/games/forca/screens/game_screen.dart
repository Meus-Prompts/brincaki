// lib/games/forca/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/hangman_painter.dart';
import '../widgets/word_display.dart';
import '../widgets/letter_keyboard.dart';

class ForcaScreen extends StatelessWidget {
  const ForcaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D4ED8)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer<ForcaProvider>(
          builder: (_, p, _) => Text(
            'Jogo da Forca  •  Nível ${p.level}',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D4ED8),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const _GameBody(),
            const _ResultOverlay(),
          ],
        ),
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ForcaProvider>();
    final correctLetters = p.letterStates.entries
        .where((e) => e.value == LetterState.correct)
        .map((e) => e.key)
        .toSet();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Boneco
          Center(
            child: HangmanWidget(wrongCount: p.wrongCount),
          ),
          const SizedBox(height: 8),
          // Contador de erros
          Text(
            'Erros: ${p.wrongCount} / 6',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              color: p.wrongCount >= 4
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          // Palavra
          WordDisplay(
            word: p.currentWord,
            correctLetters: correctLetters,
          ),
          const SizedBox(height: 24),
          // Teclado
          LetterKeyboard(
            letterStates: p.letterStates,
            onLetterTap: p.guessLetter,
            disabled: p.phase != ForcaPhase.playing,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ForcaProvider>();
    if (p.phase == ForcaPhase.playing) return const SizedBox.shrink();

    final won = p.phase == ForcaPhase.won;

    return AnimatedOpacity(
      opacity: p.phase != ForcaPhase.playing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 350),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  won ? '🎉' : '💀',
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 8),
                Text(
                  won ? 'Parabéns!' : 'Que pena...',
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: won
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
                if (!won) ...[
                  const SizedBox(height: 8),
                  Text(
                    'A palavra era:',
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    p.currentWord,
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
                if (won && p.level < 7) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Avançando para o nível ${p.level + 1}!',
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: won ? p.nextWord : p.retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: won
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    won
                        ? (p.level < 7 ? 'Próxima Palavra →' : 'Jogar Novamente')
                        : 'Tentar Novamente',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
