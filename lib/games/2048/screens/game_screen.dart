// lib/games/2048/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../../../widgets/game_scaffold.dart';
import '../../../widgets/result_panel.dart';
import '../logic/board_logic.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/score_box.dart';

class Game2048Screen extends StatelessWidget {
  const Game2048Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Game2048Provider>();
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _onKey(context, event),
      child: GameScaffold(
        palette: k2048Palette,
        title: '2048',
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _Header(),
              SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AspectRatio(aspectRatio: 1, child: BoardWidget()),
                ),
              ),
            ],
          ),
        ),
        result: _result(p),
      ),
    );
  }

  Widget? _result(Game2048Provider p) {
    return switch (p.phase) {
      Game2048Phase.playing => null,
      Game2048Phase.won => ResultPanel(
          palette: k2048Palette,
          emoji: '🎉',
          title: 'Você chegou ao 2048!',
          actions: [
            ResultAction('Continuar', p.continuePlaying),
            ResultAction('Novo jogo', p.newGame, primary: false),
          ],
        ),
      Game2048Phase.lost => ResultPanel(
          palette: k2048Palette,
          emoji: '😵',
          title: 'Fim de jogo',
          message: 'Pontuação: ${p.score}',
          actions: [ResultAction('Novo jogo', p.newGame)],
        ),
    };
  }

  KeyEventResult _onKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => Direction.up,
      LogicalKeyboardKey.arrowDown => Direction.down,
      LogicalKeyboardKey.arrowLeft => Direction.left,
      LogicalKeyboardKey.arrowRight => Direction.right,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    context.read<Game2048Provider>().move(direction);
    return KeyEventResult.handled;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Game2048Provider>();
    return Row(
      children: [
        // As caixas encolhem (em vez de empurrar o botão para fora) em telas
        // estreitas, com fonte grande ou com recordes de muitos dígitos.
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ScoreBox(label: 'Pontos', value: p.score),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ScoreBox(label: 'Recorde', value: p.best),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          key: const Key('header-new-game'),
          onPressed: p.newGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: k2048Palette.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: const Text('Novo jogo'),
        ),
      ],
    );
  }
}
