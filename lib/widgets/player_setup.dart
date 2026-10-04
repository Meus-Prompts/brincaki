// lib/widgets/player_setup.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PlayMode { solo, twoPlayers }

class PlayerSetupResult {
  const PlayerSetupResult({
    required this.mode,
    required this.player1,
    required this.player2,
    this.levelIndex,
  });

  final PlayMode mode;
  final String player1;

  /// "Jogador 2" em dois jogadores; no solo, o nome do adversário (ou vazio).
  final String player2;

  /// Índice em `levels`, só no modo solo quando há níveis.
  final int? levelIndex;
}

/// Tela inicial dos jogos com modo solo e de dois jogadores.
class PlayerSetup extends StatefulWidget {
  const PlayerSetup({
    super.key,
    required this.title,
    required this.emoji,
    required this.accent,
    required this.soloLabel,
    required this.symbols,
    required this.onStart,
    this.levels,
    this.soloOpponentName,
  });

  final String title;
  final String emoji;
  final Color accent;
  final String soloLabel;
  final (String, String) symbols;
  final ValueChanged<PlayerSetupResult> onStart;
  final List<String>? levels;
  final String? soloOpponentName;

  @override
  State<PlayerSetup> createState() => _PlayerSetupState();
}

class _PlayerSetupState extends State<PlayerSetup> {
  PlayMode _mode = PlayMode.solo;
  int _level = 0;
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    final solo = _mode == PlayMode.solo;
    final levels = widget.levels;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(widget.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: widget.accent,
            ),
          ),
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
            symbol: widget.symbols.$1,
            label: solo ? 'Seu nome' : 'Nome do Jogador 1',
          ),
          if (!solo) ...[
            const SizedBox(height: 12),
            _NameField(
              key: const Key('name2'),
              controller: _name2,
              symbol: widget.symbols.$2,
              label: 'Nome do Jogador 2',
            ),
          ],
          if (solo && levels != null) ...[
            const SizedBox(height: 20),
            Text(
              'Nível',
              style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (var i = 0; i < levels.length; i++)
                  ButtonSegment(value: i, label: Text(levels[i])),
              ],
              selected: {_level},
              onSelectionChanged: (s) => setState(() => _level = s.first),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Jogar!',
                style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
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
