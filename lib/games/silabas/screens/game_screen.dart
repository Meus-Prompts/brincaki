// lib/games/silabas/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../../../widgets/game_scaffold.dart';
import '../../../widgets/result_panel.dart';
import '../../../widgets/solo_setup.dart';
import '../logic/word.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/classify_buttons.dart';
import '../widgets/split_word.dart';
import '../widgets/syllable_blocks.dart';

const Color _kWrongColor = Color(0xFFDC2626);

class SilabasScreen extends StatelessWidget {
  const SilabasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SilabasProvider>();
    final inSetup = p.phase == SilabasPhase.setup;

    return GameScaffold(
      palette: kSilabasPalette,
      title: inSetup
          ? 'Sílabas'
          : 'Sílabas • ${SilabasProvider.levelNames[p.level]}',
      confirmExit: p.phase == SilabasPhase.playing,
      body: inSetup
          ? SoloSetup(
              palette: kSilabasPalette,
              title: 'Sílabas',
              emoji: '🔤',
              levels: SilabasProvider.levelNames,
              initialLevel: p.level,
              onStart: p.start,
            )
          : const _GameBody(),
      result: p.phase == SilabasPhase.finished ? const _Result() : null,
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SilabasProvider>();
    final word = p.word!;
    final solved =
        p.step == SilabasStep.solved || p.phase == SilabasPhase.finished;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusBar(
            text: 'Palavra ${p.index + 1} de ${p.wordCount}',
            score: p.score,
          ),
          const SizedBox(height: 16),
          if (!solved) ...[
            Text(
              _instruction(p.step),
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: kSilabasPalette.dark,
              ),
            ),
            const SizedBox(height: 16),
            _stepWord(p, word),
            for (final message in _messages(p)) ...[
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kWrongColor,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _stepAction(p),
          ] else
            _SolvedCard(word: word, points: p.wordPoints),
          if (solved && p.phase == SilabasPhase.playing) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: p.nextWord,
              style: ElevatedButton.styleFrom(
                backgroundColor: kSilabasPalette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                p.isLastWord ? 'Ver resultado' : 'Próxima palavra',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _instruction(SilabasStep step) {
    switch (step) {
      case SilabasStep.split:
        return 'Toque entre as letras para separar as sílabas';
      case SilabasStep.stress:
        return 'Qual é a sílaba mais forte?';
      case SilabasStep.classify:
      case SilabasStep.solved:
        return 'Como ela se chama?';
    }
  }

  static List<String> _messages(SilabasProvider p) {
    switch (p.step) {
      case SilabasStep.split:
        return [
          if (p.wrongCuts.isNotEmpty)
            'Os cortes em vermelho estão no lugar errado',
          if (p.missingHint != null) 'A palavra tem ${p.missingHint} sílabas',
        ];
      case SilabasStep.stress:
        return [
          if (p.wrongStress.isNotEmpty)
            'Essa não é a mais forte. Tente de novo!',
        ];
      case SilabasStep.classify:
        return [
          if (p.wrongClasses.isNotEmpty)
            'Quase! Conte as sílabas de trás para frente.',
        ];
      case SilabasStep.solved:
        return const [];
    }
  }

  static Widget _stepWord(SilabasProvider p, SilabasWord word) {
    switch (p.step) {
      case SilabasStep.split:
        return SplitWord(
          palette: kSilabasPalette,
          text: word.text,
          cuts: p.cuts,
          wrongCuts: p.wrongCuts,
          onToggle: p.toggleCut,
        );
      case SilabasStep.stress:
        return SyllableBlocks(
          palette: kSilabasPalette,
          syllables: word.syllables,
          wrong: p.wrongStress,
          onTap: p.chooseStress,
        );
      case SilabasStep.classify:
      case SilabasStep.solved:
        return SyllableBlocks(
          palette: kSilabasPalette,
          syllables: word.syllables,
          highlighted: word.stressIndex,
        );
    }
  }

  static Widget _stepAction(SilabasProvider p) {
    switch (p.step) {
      case SilabasStep.split:
        return ElevatedButton(
          onPressed: p.cuts.isEmpty ? null : p.checkSplit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kSilabasPalette.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            'Conferir',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case SilabasStep.classify:
        return ClassifyButtons(
          palette: kSilabasPalette,
          wrong: p.wrongClasses,
          onChoose: p.chooseClass,
        );
      case SilabasStep.stress:
      case SilabasStep.solved:
        return const SizedBox.shrink();
    }
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.text, required this.score});

  final String text;
  final int score;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.fredoka(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: kSilabasPalette.dark,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: style),
        Text('⭐ $score', style: style),
      ],
    );
  }
}

class _SolvedCard extends StatelessWidget {
  const _SolvedCard({required this.word, required this.points});

  final SilabasWord word;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kSilabasPalette.accent.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          SyllableBlocks(
            palette: kSilabasPalette,
            syllables: word.syllables,
            highlighted: word.stressIndex,
          ),
          const SizedBox(height: 12),
          Text(
            stressClassLabel(word.stressClass),
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kSilabasPalette.dark,
            ),
          ),
          Text(
            '+$points',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SilabasProvider>();
    final stars = p.stars;
    final title = stars == 3
        ? 'Mandou muito!'
        : (stars == 2 ? 'Muito bem!' : 'Boa tentativa!');
    return ResultPanel(
      palette: kSilabasPalette,
      emoji: '🏆',
      title: title,
      message: '${p.score} pontos de 300\n${'⭐' * stars}',
      actions: [
        ResultAction('Jogar de novo', p.playAgain),
        ResultAction('Mudar nível', p.exitToSetup, primary: false),
      ],
    );
  }
}
