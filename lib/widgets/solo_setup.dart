// lib/widgets/solo_setup.dart

import 'package:flutter/material.dart';

import 'game_palette.dart';
import 'level_picker.dart';
import 'setup_header.dart';

/// Tela inicial dos jogos de um jogador que têm nível ou dificuldade.
class SoloSetup extends StatefulWidget {
  const SoloSetup({
    super.key,
    required this.palette,
    required this.title,
    required this.emoji,
    required this.levels,
    required this.onStart,
    this.levelLabel = 'Nível',
    this.initialLevel = 0,
  });

  final GamePalette palette;
  final String title;
  final String emoji;
  final List<String> levels;

  /// Recebe o índice do nível escolhido em [levels].
  final ValueChanged<int> onStart;
  final String levelLabel;
  final int initialLevel;

  @override
  State<SoloSetup> createState() => _SoloSetupState();
}

class _SoloSetupState extends State<SoloSetup> {
  late int _level = widget.initialLevel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SetupHeader(palette: widget.palette, emoji: widget.emoji, title: widget.title),
          const SizedBox(height: 24),
          LevelPicker(
            palette: widget.palette,
            label: widget.levelLabel,
            levels: widget.levels,
            selected: _level,
            onChanged: (i) => setState(() => _level = i),
          ),
          const SizedBox(height: 28),
          StartButton(palette: widget.palette, onPressed: () => widget.onStart(_level)),
        ],
      ),
    );
  }
}
