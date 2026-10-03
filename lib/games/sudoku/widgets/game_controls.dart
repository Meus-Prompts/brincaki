import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

class GameControls extends StatelessWidget {
  const GameControls({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: provider.numberFirstMode ? Icons.grid_on : Icons.dialpad,
          label: provider.numberFirstMode ? 'Nº Primeiro' : 'Célula',
          onPressed: provider.isComplete ? null : () => provider.toggleInputMode(),
          isActive: provider.numberFirstMode,
        ),
        _ControlButton(
          icon: Icons.backspace_outlined,
          label: 'Limpar',
          onPressed: provider.isComplete ? null : () => provider.clearCell(),
        ),
        _ControlButton(
          icon: Icons.refresh,
          label: 'Novo Jogo',
          onPressed: () => _showNewGameDialog(context, provider),
        ),
      ],
    );
  }

  void _showNewGameDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Novo Jogo', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Deseja iniciar um novo jogo? O progresso atual será perdido.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.newGame();
            },
            child: const Text('Novo Jogo'),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: isActive
              ? BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            iconSize: 28,
            color: isActive
                ? theme.colorScheme.primary
                : (onPressed != null ? theme.colorScheme.primary : Colors.grey),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive
                ? theme.colorScheme.primary
                : (onPressed != null ? Colors.white70 : Colors.grey),
          ),
        ),
      ],
    );
  }
}
