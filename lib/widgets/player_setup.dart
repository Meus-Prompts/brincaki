// lib/widgets/player_setup.dart

import 'package:flutter/material.dart';

import 'game_palette.dart';
import 'level_picker.dart';
import 'setup_header.dart';

enum PlayMode { solo, twoPlayers }

class PlayerSetupResult {
  const PlayerSetupResult({
    required this.mode,
    required this.player1,
    required this.player2,
    this.levelIndex,
    this.sideIndex,
  });

  final PlayMode mode;
  final String player1;

  /// "Jogador 2" em dois jogadores; no solo, o nome do adversário (ou vazio).
  final String player2;

  /// Índice em `levels`, só no modo solo quando há níveis.
  final int? levelIndex;

  /// 0 = primeira cor de `sides`, 1 = segunda; nulo quando não há `sides`.
  final int? sideIndex;
}

/// Tela inicial dos jogos com modo solo e de dois jogadores.
class PlayerSetup extends StatefulWidget {
  const PlayerSetup({
    super.key,
    required this.title,
    required this.emoji,
    required this.palette,
    required this.soloLabel,
    required this.symbols,
    required this.onStart,
    this.levels,
    this.soloOpponentName,
    this.sides,
  });

  final String title;
  final String emoji;
  final GamePalette palette;
  final String soloLabel;
  final (String, String) symbols;
  final ValueChanged<PlayerSetupResult> onStart;
  final List<String>? levels;
  final String? soloOpponentName;

  /// Rótulos das duas cores (ex.: Brancas/Pretas); mostra a escolha de cor.
  final (String, String)? sides;

  @override
  State<PlayerSetup> createState() => _PlayerSetupState();
}

class _PlayerSetupState extends State<PlayerSetup> {
  PlayMode _mode = PlayMode.solo;
  int _level = 0;
  int _side = 0;
  final _name1 = TextEditingController();
  final _name2 = TextEditingController();

  @override
  void dispose() {
    _name1.dispose();
    _name2.dispose();
    super.dispose();
  }

  String _nameOr(TextEditingController controller, String fallback) {
    final name = controller.text.trim();
    return name.isEmpty ? fallback : name;
  }

  void _start() {
    final solo = _mode == PlayMode.solo;
    widget.onStart(PlayerSetupResult(
      mode: _mode,
      player1: _nameOr(_name1, 'Jogador 1'),
      player2: solo ? (widget.soloOpponentName ?? '') : _nameOr(_name2, 'Jogador 2'),
      levelIndex: solo && widget.levels != null ? _level : null,
      sideIndex: widget.sides == null ? null : _side,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final solo = _mode == PlayMode.solo;
    final levels = widget.levels;
    final sides = widget.sides;
    final swap = _side == 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SetupHeader(palette: widget.palette, emoji: widget.emoji, title: widget.title),
          const SizedBox(height: 24),
          SegmentedButton<PlayMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: PlayMode.solo, label: Text(widget.soloLabel)),
              const ButtonSegment(
                value: PlayMode.twoPlayers,
                label: Text('Dois jogadores'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 20),
          _NameField(
            key: const Key('name1'),
            controller: _name1,
            symbol: swap ? widget.symbols.$2 : widget.symbols.$1,
            label: solo ? 'Seu nome' : 'Nome do Jogador 1',
          ),
          if (!solo) ...[
            const SizedBox(height: 12),
            _NameField(
              key: const Key('name2'),
              controller: _name2,
              symbol: swap ? widget.symbols.$1 : widget.symbols.$2,
              label: 'Nome do Jogador 2',
            ),
          ],
          if (sides != null) ...[
            const SizedBox(height: 20),
            LevelPicker(
              palette: widget.palette,
              label: solo ? 'Sua cor' : 'Cor do Jogador 1',
              levels: [sides.$1, sides.$2],
              selected: _side,
              onChanged: (i) => setState(() => _side = i),
            ),
          ],
          if (solo && levels != null) ...[
            const SizedBox(height: 20),
            LevelPicker(
              palette: widget.palette,
              label: 'Nível',
              levels: levels,
              selected: _level,
              onChanged: (i) => setState(() => _level = i),
            ),
          ],
          const SizedBox(height: 28),
          StartButton(palette: widget.palette, onPressed: _start),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    super.key,
    required this.controller,
    required this.symbol,
    required this.label,
  });

  final TextEditingController controller;
  final String symbol;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 12,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        prefixText: '$symbol  ',
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
