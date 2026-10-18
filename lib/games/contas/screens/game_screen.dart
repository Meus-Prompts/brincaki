// lib/games/contas/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../../../widgets/game_scaffold.dart';
import '../../../widgets/level_picker.dart';
import '../../../widgets/result_panel.dart';
import '../../../widgets/setup_header.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/choice_grid.dart';
import '../widgets/number_pad.dart';
import '../widgets/status_bar.dart';

const _operationNames = {
  Operation.addition: 'Adição',
  Operation.subtraction: 'Subtração',
  Operation.multiplication: 'Multiplicação',
  Operation.division: 'Divisão',
};

const _operationLabels = ['+ Adição', '− Subtração', '× Multiplicação', '÷ Divisão'];

/// Frase de cada nível, na ordem dos níveis 1, 2 e 3.
const _levelHints = {
  Operation.addition: ['Somas até 100', 'Somas até 1000', 'Três números até 1000'],
  Operation.subtraction: ['Números até 100', 'Números até 1000', 'Três números até 1000'],
  Operation.multiplication: ['Tabuada do 1 ao 5', 'Tabuada do 6 ao 10', 'Tabuada do 1 ao 10'],
  Operation.division: ['Dividir por 1 a 5', 'Dividir por 6 a 10', 'Dividir por 1 a 10'],
};

class ContasScreen extends StatelessWidget {
  const ContasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContasProvider>();
    final inSetup = p.phase == ContasPhase.setup;
    final inRound = p.phase == ContasPhase.playing || p.phase == ContasPhase.mistake;

    return GameScaffold(
      palette: kContasPalette,
      title: inSetup ? 'Contas' : 'Contas • ${_operationNames[p.operation]} ${p.level}',
      confirmExit: inRound,
      actions: [
        if (inRound)
          IconButton(
            icon: Icon(Icons.pause_rounded, color: kContasPalette.dark),
            tooltip: 'Parar',
            onPressed: p.stop,
          ),
      ],
      body: inSetup ? const _Setup() : const _GameBody(),
      result: p.phase == ContasPhase.finished ? const _Result() : null,
    );
  }
}

class _Setup extends StatelessWidget {
  const _Setup();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContasProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SetupHeader(palette: kContasPalette, emoji: '🧮', title: 'Contas'),
          const SizedBox(height: 20),
          LevelPicker(
            palette: kContasPalette,
            label: 'Operação',
            levels: _operationLabels,
            selected: p.operation.index,
            onChanged: (i) => p.select(operation: Operation.values[i]),
          ),
          const SizedBox(height: 16),
          LevelPicker(
            palette: kContasPalette,
            label: 'Nível',
            levels: const ['1', '2', '3'],
            selected: p.level - 1,
            onChanged: (i) => p.select(level: i + 1),
          ),
          const SizedBox(height: 4),
          Text(
            _levelHints[p.operation]![p.level - 1],
            style: GoogleFonts.fredoka(fontSize: 14, color: kContasPalette.accent),
          ),
          const SizedBox(height: 16),
          LevelPicker(
            palette: kContasPalette,
            label: 'Responder com',
            levels: const ['⌨️ Teclado', '🔘 Opções'],
            selected: p.answerMode.index,
            onChanged: (i) => p.select(mode: AnswerMode.values[i]),
          ),
          const SizedBox(height: 20),
          Text(
            '🏆 Recorde: ${p.currentRecord}',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEA580C),
            ),
          ),
          const SizedBox(height: 16),
          StartButton(palette: kContasPalette, onPressed: p.start),
        ],
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContasProvider>();
    final problem = p.problem!;

    return SingleChildScrollView(
      child: Column(
        children: [
          StatusBar(
            lives: p.lives,
            maxLives: ContasProvider.maxLives,
            streak: p.streak,
            score: p.score,
            multiplier: p.multiplier,
            maxMultiplier: ContasProvider.maxMultiplier,
            streakStep: ContasProvider.streakStep,
          ),
          SizedBox(
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${problem.text} = ${p.answerRevealed ? problem.answer : '?'}',
                      style: GoogleFonts.fredoka(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: kContasPalette.dark,
                      ),
                    ),
                  ),
                ),
                if (p.correctCount > 0)
                  Positioned(
                    top: 0,
                    child: _HitToast(key: ValueKey(p.correctCount)),
                  ),
              ],
            ),
          ),
          if (p.phase == ContasPhase.playing)
            p.answerMode == AnswerMode.keyboard
                ? NumberPad(
                    typed: p.typed,
                    onDigit: p.typeDigit,
                    onDelete: p.deleteDigit,
                    onSubmit: p.submit,
                  )
                : ChoiceGrid(choices: p.choices, onChoose: p.choose),
          if (p.phase == ContasPhase.mistake) const _Mistake(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Aviso de acerto que sobe e some: "+20" e, a cada 5 seguidas, a
/// comemoração.
class _HitToast extends StatefulWidget {
  const _HitToast({super.key});

  @override
  State<_HitToast> createState() => _HitToastState();
}

class _HitToastState extends State<_HitToast> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final p = context.read<ContasProvider>();
    final raised = p.streak ~/ ContasProvider.streakStep < ContasProvider.maxMultiplier;
    final milestone = p.isMilestone
        ? '${p.streak} seguidas! 🔥${raised ? ' Agora ×${p.multiplier}' : ''}'
        : null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: milestone == null ? 700 : 1400),
      onEnd: () => setState(() => _visible = false),
      builder: (context, t, child) => Opacity(
        opacity: (t < 0.7 ? 1.0 : (1 - t) / 0.3).clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, -8 * t), child: child),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+${p.lastPoints}',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kContasPalette.accent,
            ),
          ),
          if (milestone != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                milestone,
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Depois de um erro: a resposta certa e o "Continuar".
class _Mistake extends StatelessWidget {
  const _Mistake();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContasProvider>();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Quase!',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF991B1B),
            ),
          ),
          Text(
            'A resposta certa é ${p.problem!.answer}',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(fontSize: 18, color: const Color(0xFF991B1B)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: p.continueAfterMistake,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Continuar',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
    final p = context.watch<ContasProvider>();

    return ResultPanel(
      palette: kContasPalette,
      emoji: p.isNewRecord ? '🏆' : '🎯',
      title: p.isNewRecord ? 'Novo recorde!' : 'Fim de jogo!',
      message: '⭐ ${p.score} pontos · Recorde: ${p.currentRecord}\n'
          '🔥 Maior sequência: ${p.bestStreak}',
      actions: [
        ResultAction('Jogar de novo', p.playAgain),
        ResultAction('Mudar nível', p.exitToSetup, primary: false),
      ],
    );
  }
}
