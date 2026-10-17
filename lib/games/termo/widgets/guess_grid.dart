// lib/games/termo/widgets/guess_grid.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../logic/evaluate.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

const kTermoGreen = Color(0xFF22C55E);
const kTermoYellow = Color(0xFFEAB308);
const kTermoGrey = Color(0xFF6B7280);

Color resultColor(LetterResult r) => switch (r) {
      LetterResult.correct => kTermoGreen,
      LetterResult.present => kTermoYellow,
      LetterResult.absent => kTermoGrey,
    };

class GuessGrid extends StatelessWidget {
  const GuessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TermoProvider>();
    return AspectRatio(
      aspectRatio: TermoProvider.wordLength / TermoProvider.maxGuesses,
      child: Column(
        children: [
          for (var row = 0; row < TermoProvider.maxGuesses; row++)
            Expanded(child: _row(p, row)),
        ],
      ),
    );
  }

  Widget _row(TermoProvider p, int row) {
    if (row < p.guesses.length) {
      final guess = p.guesses[row];
      final shown = p.shown(guess);
      final results = p.resultsFor(guess);
      return Row(
        children: [
          for (var i = 0; i < TermoProvider.wordLength; i++)
            Expanded(
              child: _RevealTile(
                key: ValueKey('r$row-$i-$guess'),
                letter: shown[i],
                color: resultColor(results[i]),
                delay: Duration(milliseconds: 120 * i),
              ),
            ),
        ],
      );
    }
    final isCurrent = row == p.guesses.length && p.phase == TermoPhase.playing;
    final letters = isCurrent ? p.current : '';
    final tiles = Row(
      children: [
        for (var i = 0; i < TermoProvider.wordLength; i++)
          Expanded(
            child: _Tile(
              letter: i < letters.length ? letters[i] : '',
              filled: i < letters.length,
            ),
          ),
      ],
    );
    if (!isCurrent || p.shakeCount == 0) return tiles;
    return TweenAnimationBuilder<double>(
      key: ValueKey('shake-${p.shakeCount}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(sin(t * pi * 6) * 8 * (1 - t), 0),
        child: child,
      ),
      child: tiles,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.letter, required this.filled});

  final String letter;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: _Letter(letter: letter, color: const Color(0xFF0F172A)),
      ),
    );
  }
}

/// Letra de uma tentativa enviada: gira e aparece com a cor do resultado.
class _RevealTile extends StatefulWidget {
  const _RevealTile({
    super.key,
    required this.letter,
    required this.color,
    required this.delay,
  });

  final String letter;
  final Color color;
  final Duration delay;

  @override
  State<_RevealTile> createState() => _RevealTileState();
}

class _RevealTileState extends State<_RevealTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  Timer? _start;

  @override
  void initState() {
    super.initState();
    _start = Timer(widget.delay, _controller.forward);
  }

  @override
  void dispose() {
    _start?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final revealed = t >= 0.5;
        return Padding(
          padding: const EdgeInsets.all(3),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateX(t * pi),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationX(revealed ? pi : 0),
              child: Container(
                decoration: BoxDecoration(
                  color: revealed ? widget.color : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: revealed ? widget.color : const Color(0xFF334155),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: _Letter(
                  letter: widget.letter,
                  color: revealed ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          letter,
          style: GoogleFonts.fredoka(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
