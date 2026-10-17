// lib/games/memoria/screens/game_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../../../widgets/game_scaffold.dart';
import '../../../widgets/player_setup.dart';
import '../../../widgets/result_panel.dart';
import '../../../widgets/score_board.dart';
import '../data/levels.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/memory_card_tile.dart';

class MemoryScreen extends StatelessWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MemoryProvider>();
    final title = switch (p.phase) {
      MemoryPhase.setup => 'Jogo da Memória',
      _ when p.mode == PlayMode.solo => 'Memória • Nível ${p.level}',
      _ => 'Memória',
    };

    return GameScaffold(
      palette: kMemoriaPalette,
      title: title,
      body: p.phase == MemoryPhase.setup
          ? PlayerSetup(
              title: 'Jogo da Memória',
              emoji: '🧠',
              palette: kMemoriaPalette,
              soloLabel: 'Sozinho',
              symbols: ('🐶', '🐱'),
              levels: [for (var i = 1; i <= kSoloLevels.length; i++) '$i'],
              onStart: p.start,
            )
          : const _GameView(),
      result: p.phase == MemoryPhase.finished ? _result(p) : null,
    );
  }

  Widget _result(MemoryProvider p) {
    if (p.mode == PlayMode.solo) {
      return ResultPanel(
        palette: kMemoriaPalette,
        emoji: '🎉',
        title: 'Nível ${p.level} completo em ${p.moves} jogadas!',
        actions: [
          ResultAction(p.isLastLevel ? 'Jogar de novo' : 'Próximo nível', p.nextLevel),
          ResultAction('Mudar nível', p.exitToSetup, primary: false),
        ],
      );
    }
    final winner = p.winner;
    return ResultPanel(
      palette: kMemoriaPalette,
      emoji: winner == null ? '🤝' : '🏆',
      title: winner == null ? 'Empate!' : '${winner == 1 ? p.name1 : p.name2} venceu!',
      message: '${p.pairs1} × ${p.pairs2} pares',
      actions: [
        ResultAction('Jogar de novo', p.playAgain),
        ResultAction('Trocar jogadores', p.exitToSetup, primary: false),
      ],
    );
  }
}

class _GameView extends StatefulWidget {
  const _GameView();

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  late final MemoryProvider _provider;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _provider = context.read<MemoryProvider>();
    _provider.addListener(_onChange);
  }

  /// Duas cartas erradas à mostra: desvira depois de um instante.
  void _onChange() {
    if (_provider.waitingToHide && _hideTimer == null) {
      _hideTimer = Timer(const Duration(milliseconds: 900), () {
        _hideTimer = null;
        _provider.hideMismatched();
      });
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onChange);
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MemoryProvider>();
    final duo = p.mode == PlayMode.twoPlayers;

    return Column(
      children: [
        if (duo) ...[
          ScoreBoard(
            name1: p.name1,
            name2: p.name2,
            symbol1: '🐶',
            symbol2: '🐱',
            score1: p.pairs1,
            score2: p.pairs2,
            draws: p.draws,
            activePlayer: p.phase == MemoryPhase.playing ? p.currentPlayer : null,
            accent: kMemoriaPalette.accent,
          ),
          Text(
            'Vitórias: ${p.wins1} × ${p.wins2}',
            style: GoogleFonts.fredoka(fontSize: 14, color: kMemoriaPalette.dark),
          ),
          // Espaço reservado durante a partida: a grade não pula quando os
          // tamanhos somem ao virar a primeira carta. No fim, o espaço vai
          // para a grade, que divide a tela com o painel de resultado.
          if (p.phase == MemoryPhase.playing)
            SizedBox(
              height: 48,
              child: p.untouched
                  ? Wrap(
                      spacing: 8,
                      children: [
                        for (final size in kDuoSizes.keys)
                          ChoiceChip(
                            label: Text(size),
                            selected: p.duoSize == size,
                            onSelected: (_) => p.setDuoSize(size),
                          ),
                      ],
                    )
                  : null,
            ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Jogadas: ${p.moves}',
              style: GoogleFonts.fredoka(fontSize: 18, color: kMemoriaPalette.dark),
            ),
          ),
        const Expanded(
          child: Padding(padding: EdgeInsets.all(12), child: _CardGrid()),
        ),
      ],
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid();

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MemoryProvider>();
    final grid = p.grid;
    final cards = p.cards;

    return LayoutBuilder(
      builder: (context, constraints) {
        double sideFor(double gap) => max(
          0,
          min(
            (constraints.maxWidth - gap * (grid.cols - 1)) / grid.cols,
            (constraints.maxHeight - gap * (grid.rows - 1)) / grid.rows,
          ),
        );
        // Em telas pequenas (grade grande com o resultado aberto), o
        // espaço entre as cartas encolhe para as cartas não sumirem.
        var gap = _gap;
        var side = sideFor(gap);
        if (side < 4 * _gap) {
          gap = _gap / 4;
          side = sideFor(gap);
        }
        return Center(
          key: ValueKey(p.dealId),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < grid.rows; r++)
                Padding(
                  padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < grid.cols; c++)
                        Padding(
                          padding: EdgeInsets.only(left: c == 0 ? 0 : gap),
                          child: SizedBox.square(
                            dimension: side,
                            child: MemoryCardTile(
                              key: Key('card-${r * grid.cols + c}'),
                              card: cards[r * grid.cols + c],
                              onTap: () => p.flip(r * grid.cols + c),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
