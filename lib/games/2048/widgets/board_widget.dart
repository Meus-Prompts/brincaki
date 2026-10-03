// lib/games/2048/widgets/board_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/board_logic.dart';
import '../providers/game_provider.dart';
import 'tile_widget.dart';

class BoardWidget extends StatefulWidget {
  const BoardWidget({super.key});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  /// Distância total do arrasto atual.
  Offset _dragged = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Game2048Provider>();

    return GestureDetector(
      key: const Key('board2048'),
      onPanStart: (_) => _dragged = Offset.zero,
      onPanUpdate: (details) => _dragged += details.delta,
      onPanEnd: (details) {
        // Swipe rápido pela velocidade; arrasto lento pela distância.
        final direction =
            directionFromVelocity(details.velocity.pixelsPerSecond) ??
                directionFromDistance(_dragged);
        if (direction != null) p.move(direction);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFBBADA0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            for (var r = 0; r < Game2048Provider.size; r++)
              Expanded(
                child: Row(
                  children: [
                    for (var c = 0; c < Game2048Provider.size; c++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: TileWidget(
                            value: p.board[r][c],
                            isNew: p.newTile == (r, c),
                            isMerged: p.mergedTiles.contains((r, c)),
                            moveCount: p.moveCount,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
