// lib/games/forca/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../widgets/game_palette.dart';
import '../../../widgets/game_scaffold.dart';
import '../../../widgets/result_panel.dart';
import '../../../widgets/solo_setup.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/hangman_painter.dart';
import '../widgets/word_display.dart';
import '../widgets/letter_keyboard.dart';

class ForcaScreen extends StatelessWidget {
  const ForcaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ForcaProvider>();
    final inSetup = p.phase == ForcaPhase.setup;
    final finished = p.phase == ForcaPhase.won || p.phase == ForcaPhase.lost;

    return GameScaffold(
      palette: kForcaPalette,
      title: inSetup ? 'Jogo da Forca' : 'Jogo da Forca • Nível ${p.level}',
      body: inSetup
          ? SoloSetup(
              palette: kForcaPalette,
              title: 'Jogo da Forca',
              emoji: '🪢',
              levels: [
                for (var i = 1; i <= ForcaProvider.maxLevel; i++) '$i',
              ],
              initialLevel: p.level - 1,
              onStart: (i) => p.start(i + 1),
            )
          : const _GameBody(),
      result: finished ? const _Result() : null,
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ForcaProvider>();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: HangmanWidget(wrongCount: p.wrongCount),
          ),
          const SizedBox(height: 8),
          Text(
            'Erros: ${p.wrongCount} / ${ForcaProvider.maxErrors}',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              color: p.wrongCount >= 4
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          WordDisplay(
            word: p.currentWord,
            correctLetters: p.correctLetters,
          ),
          const SizedBox(height: 24),
          // Quando a partida acaba, o painel de resultado fica no lugar.
          if (p.phase == ForcaPhase.playing)
            LetterKeyboard(
              letterStates: p.letterStates,
              onLetterTap: p.guessLetter,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ForcaProvider>();
    final changeLevel = ResultAction('Mudar nível', p.exitToSetup, primary: false);

    if (p.phase == ForcaPhase.won) {
      return ResultPanel(
        palette: kForcaPalette,
        emoji: '🎉',
        title: 'Parabéns!',
        message: p.isLastLevel
            ? 'Você está no último nível!'
            : 'Avançando para o nível ${p.level + 1}!',
        actions: [
          ResultAction('Próxima palavra', p.nextWord),
          changeLevel,
        ],
      );
    }
    return ResultPanel(
      palette: kForcaPalette,
      emoji: '😢',
      title: 'Que pena...',
      message: 'A palavra era: ${p.currentWord}',
      actions: [
        ResultAction('Tentar de novo', p.retry),
        changeLevel,
      ],
    );
  }
}
