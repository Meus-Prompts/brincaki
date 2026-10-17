// lib/games/tictactoe/widgets/board_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/board.dart';
import '../providers/game_provider.dart';

/// Símbolo de cada jogador: 1 é ❌ e 2 é ⭕.
String symbolOf(int player) => switch (player) {
  1 => '❌',
  2 => '⭕',
  _ => '',
};

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TicTacToeProvider>();

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (var row = 0; row < kSize; row++) ...[
              if (row > 0) const SizedBox(height: 10),
              Expanded(
                child: Row(
                  children: [
                    for (var col = 0; col < kSize; col++) ...[
                      if (col > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _BoardCell(
                          key: Key('cell-$row-$col'),
                          value: p.board[row][col],
                          isWinning: p.winningCells?.contains((row, col)) ?? false,
                          onTap: () => p.play(row, col),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  final int value;
  final bool isWinning;
  final VoidCallback onTap;

  const _BoardCell({super.key, required this.value, required this.isWinning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isWinning ? const Color(0xFFBBF7D0) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isWinning ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
            width: isWinning ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: AnimatedScale(
            scale: value == 0 ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(symbolOf(value), style: const TextStyle(fontSize: 40)),
            ),
          ),
        ),
      ),
    );
  }
}
