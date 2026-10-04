// lib/games/memoria/screens/game_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/player_setup.dart';
import '../../../widgets/score_board.dart';
import '../data/levels.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/memory_card_tile.dart';

const _background = Color(0xFFF5F3FF);
const _dark = Color(0xFF5B21B6);

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

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          tooltip: 'Voltar ao menu',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _dark,
          ),
        ),
      ),
      body: SafeArea(
        child: p.phase == MemoryPhase.setup
            ? PlayerSetup(
                title: 'Jogo da Memória',
                emoji: '🧠',
                accent: kMemoryPurple,
                soloLabel: 'Sozinho',
                symbols: ('🐶', '🐱'),
                onStart: p.start,
              )
            : const _GameView(),
      ),
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

    return Stack(
      children: [
        Column(
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
                accent: kMemoryPurple,
              ),
              Text(
                'Vitórias: ${p.wins1} × ${p.wins2}',
                style: GoogleFonts.fredoka(fontSize: 14, color: _dark),
              ),
              // Espaço sempre reservado: a grade não pula quando os
              // tamanhos somem ao virar a primeira carta.
              SizedBox(
                height: 48,
                child: p.phase == MemoryPhase.playing && p.untouched
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
                  style: GoogleFonts.fredoka(fontSize: 18, color: _dark),
                ),
              ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: _CardGrid(),
              ),
            ),
          ],
        ),
        if (p.phase == MemoryPhase.finished) const _ResultOverlay(),
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
        final side = min(
          (constraints.maxWidth - _gap * (grid.cols - 1)) / grid.cols,
          (constraints.maxHeight - _gap * (grid.rows - 1)) / grid.rows,
        );
        return Center(
          key: ValueKey(p.dealId),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < grid.rows; r++)
                Padding(
                  padding: EdgeInsets.only(top: r == 0 ? 0 : _gap),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < grid.cols; c++)
                        Padding(
                          padding: EdgeInsets.only(left: c == 0 ? 0 : _gap),
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

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MemoryProvider>();
    final solo = p.mode == PlayMode.solo;
    final winner = p.winner;
    final emoji = solo ? '🎉' : (winner == null ? '🤝' : '🏆');
    final title = solo
        ? 'Nível ${p.level} completo em ${p.moves} jogadas!'
        : (winner == null
            ? '🤝 Empate!'
            : '🏆 ${winner == 1 ? p.name1 : p.name2} venceu!');

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (solo) Text(emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _dark,
                  ),
                ),
                if (!solo)
                  Text(
                    '${p.pairs1} × ${p.pairs2} pares',
                    style: GoogleFonts.fredoka(fontSize: 16, color: Colors.black54),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: solo ? p.nextLevel : p.playAgain,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMemoryPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        solo
                            ? (p.isLastLevel ? 'Jogar de novo' : 'Próximo nível')
                            : 'Jogar de novo',
                        style: GoogleFonts.fredoka(fontSize: 16),
                      ),
                    ),
                    if (!solo)
                      OutlinedButton(
                        onPressed: p.exitToSetup,
                        child: Text(
                          'Trocar jogadores',
                          style: GoogleFonts.fredoka(fontSize: 16),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
