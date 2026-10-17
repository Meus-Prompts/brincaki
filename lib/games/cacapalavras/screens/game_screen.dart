// lib/games/cacapalavras/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../../../widgets/game_scaffold.dart';
import '../../../widgets/result_panel.dart';
import '../../../widgets/solo_setup.dart';
import '../data/levels.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/letter_grid.dart';
import '../widgets/word_list.dart';

class CacaPalavrasScreen extends StatelessWidget {
  const CacaPalavrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<WordSearchProvider>();

    if (p.phase == WordSearchPhase.setup) {
      return GameScaffold(
        palette: kCacaPalavrasPalette,
        title: 'Caça-Palavras',
        body: SoloSetup(
          palette: kCacaPalavrasPalette,
          emoji: '🔍',
          title: 'Caça-Palavras',
          levelLabel: 'Nível',
          levels: [
            for (var i = 0; i < kLevels.length; i++)
              '${i + 1} • ${kLevels[i].theme}',
          ],
          initialLevel: p.level - 1,
          onStart: (i) => p.start(i + 1),
        ),
      );
    }

    return GameScaffold(
      palette: kCacaPalavrasPalette,
      title: 'Caça-Palavras • Nível ${p.level} — ${p.config.theme}',
      body: const _GameBody(),
      result: p.phase == WordSearchPhase.won ? _result(p) : null,
    );
  }

  Widget _result(WordSearchProvider p) {
    final last = p.isLastLevel;
    return ResultPanel(
      palette: kCacaPalavrasPalette,
      emoji: last ? '🏆' : '🎉',
      title: last
          ? 'Você completou todos os níveis!'
          : 'Nível ${p.level} completo!',
      actions: [
        ResultAction(last ? 'Jogar de novo' : 'Próximo nível', p.nextLevel),
        ResultAction('Mudar nível', p.exitToSetup, primary: false),
      ],
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(child: Center(child: LetterGrid())),
          SizedBox(height: 16),
          WordList(),
        ],
      ),
    );
  }
}
