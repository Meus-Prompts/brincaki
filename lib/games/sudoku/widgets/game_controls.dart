// lib/games/sudoku/widgets/game_controls.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../providers/game_provider.dart';

/// Botões abaixo do teclado: modo de entrada, apagar, dica e novo jogo.
class GameControls extends StatelessWidget {
  const GameControls({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SudokuProvider>();
    final hints = provider.hintsRemaining;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: provider.numberFirstMode ? Icons.dialpad : Icons.grid_on,
          label: provider.numberFirstMode ? 'Número' : 'Casa',
          onPressed: provider.toggleInputMode,
          isActive: provider.numberFirstMode,
        ),
        _ControlButton(
          icon: Icons.backspace_outlined,
          label: 'Apagar',
          onPressed: provider.clearCell,
        ),
        _ControlButton(
          icon: Icons.lightbulb_outline,
          label: 'Dica ($hints)',
          onPressed: hints > 0 ? provider.useHint : null,
        ),
        _ControlButton(
          icon: Icons.refresh,
          label: 'Novo jogo',
          onPressed: () => _confirmNewGame(context, provider),
        ),
      ],
    );
  }

  Future<void> _confirmNewGame(BuildContext context, SudokuProvider provider) async {
    const palette = kSudokuPalette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Novo jogo?', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
        content: Text(
          'O progresso desta partida será perdido.',
          style: GoogleFonts.fredoka(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Continuar jogando', style: GoogleFonts.fredoka()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: Colors.white,
            ),
            child: Text('Novo jogo', style: GoogleFonts.fredoka()),
          ),
        ],
      ),
    );
    if (confirmed ?? false) provider.newGame();
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    const palette = kSudokuPalette;
    final color = onPressed == null ? Colors.grey : palette.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: label,
          icon: Icon(icon),
          iconSize: 26,
          color: isActive ? Colors.white : palette.accent,
          disabledColor: Colors.grey,
          style: IconButton.styleFrom(
            backgroundColor: isActive ? palette.accent : Colors.white,
            side: BorderSide(color: palette.accent.withValues(alpha: 0.4)),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
