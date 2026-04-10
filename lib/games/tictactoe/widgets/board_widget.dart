// lib/games/tictactoe/widgets/board_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game_state.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TicTacToeProvider>();
    final bool interactive = p.phase == GamePhase.playing;

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final row = index ~/ 3;
            final col = index % 3;
            final cell = p.board[row][col];
            final isWinning = p.winningCells?.contains((row, col)) ?? false;

            return _BoardCell(
              cell: cell,
              isWinning: isWinning,
              onTap: interactive && cell == Cell.empty
                  ? () => p.makeMove(row, col)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  final Cell cell;
  final bool isWinning;
  final VoidCallback? onTap;

  const _BoardCell({
    required this.cell,
    required this.isWinning,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isWinning
              ? const Color(0xFFBBF7D0)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isWinning
                ? const Color(0xFF22C55E)
                : const Color(0xFFE5E7EB),
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
            scale: cell == Cell.empty ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: Text(
              cell.emoji,
              style: const TextStyle(fontSize: 40),
            ),
          ),
        ),
      ),
    );
  }
}
