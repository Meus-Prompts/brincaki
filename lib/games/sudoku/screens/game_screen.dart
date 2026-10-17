// lib/games/sudoku/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../../../widgets/game_scaffold.dart';
import '../../../widgets/result_panel.dart';
import '../../../widgets/solo_setup.dart';
import '../models/difficulty.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/game_controls.dart';
import '../widgets/game_timer.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_grid.dart';

class SudokuScreen extends StatelessWidget {
  const SudokuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SudokuProvider>();
    final inSetup = p.phase == SudokuPhase.setup;

    return GameScaffold(
      palette: kSudokuPalette,
      title: inSetup ? 'Sudoku' : 'Sudoku • ${p.difficulty.name}',
      actions: inSetup
          ? null
          : const [Padding(padding: EdgeInsets.only(right: 16), child: GameTimer())],
      confirmExit: p.phase == SudokuPhase.playing,
      body: inSetup
          ? SoloSetup(
              palette: kSudokuPalette,
              emoji: '🔢',
              title: 'Sudoku',
              levelLabel: 'Dificuldade',
              levels: [for (final d in Difficulty.values) d.name],
              initialLevel: p.difficulty.index,
              onStart: (i) => p.start(Difficulty.values[i]),
            )
          : const _GameBody(),
      result: p.phase == SudokuPhase.solved
          ? ResultPanel(
              palette: kSudokuPalette,
              emoji: '🏆',
              title: 'Parabéns!',
              message: 'Tempo: ${p.formattedTime}',
              actions: [
                ResultAction('Jogar de novo', p.newGame),
                ResultAction('Mudar dificuldade', p.exitToSetup, primary: false),
              ],
            )
          : null,
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context) {
    final playing = context.select<SudokuProvider, bool>((p) => p.isPlaying);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        children: [
          // O tabuleiro ocupa o maior quadrado que couber.
          const Expanded(child: Center(child: SudokuGrid())),
          if (playing) ...const [
            SizedBox(height: 12),
            NumberPad(),
            SizedBox(height: 8),
            GameControls(),
          ],
        ],
      ),
    );
  }
}
