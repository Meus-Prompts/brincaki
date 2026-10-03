// lib/games/2048/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../logic/board_logic.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/score_box.dart';

const _brown = Color(0xFF776E65);
const _buttonColor = Color(0xFF8F7A66);

class Game2048Screen extends StatelessWidget {
  const Game2048Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _onKey(context, event),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAF8EF),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _brown),
            tooltip: 'Voltar ao menu',
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
          title: Text(
            '2048',
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _brown,
            ),
          ),
        ),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _Header(),
                SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [BoardWidget(), _ResultOverlay()],
                      ),
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

ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
      backgroundColor: _buttonColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
    );

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Game2048Provider>();
    return Row(
      children: [
        ScoreBox(label: 'Pontos', value: p.score),
        const SizedBox(width: 8),
        ScoreBox(label: 'Recorde', value: p.best),
        const Spacer(),
        ElevatedButton(
          onPressed: p.newGame,
          style: _buttonStyle(),
          child: const Text('Novo jogo'),
        ),
      ],
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Game2048Provider>();
    if (p.phase == Game2048Phase.playing) return const SizedBox.shrink();

    final won = p.phase == Game2048Phase.won;

    return Container(
      decoration: BoxDecoration(
        color: (won ? const Color(0xFFEDC22E) : const Color(0xFFEEE4DA))
            .withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            won ? 'Você chegou ao 2048!' : 'Fim de jogo',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: won ? Colors.white : _brown,
            ),
          ),
          if (!won) ...[
            const SizedBox(height: 4),
            Text(
              '${p.score} pontos',
              style: GoogleFonts.fredoka(fontSize: 18, color: _brown),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (won)
                ElevatedButton(
                  onPressed: p.continuePlaying,
                  style: _buttonStyle(),
                  child: const Text('Continuar'),
                ),
              ElevatedButton(
                onPressed: p.newGame,
                style: _buttonStyle(),
                child: Text(won ? 'Novo jogo' : 'Jogar de novo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
