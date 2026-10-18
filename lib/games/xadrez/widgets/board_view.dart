// lib/games/xadrez/widgets/board_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/position.dart';
import '../providers/game_provider.dart';
import 'chess_piece.dart';
import 'promotion_picker.dart';

const kXadrezLight = Color(0xFFE8EAF6);
const kXadrezDark = Color(0xFF7986CB);
const _selectedTint = Color(0xFF65A30D);
const _lastMoveTint = Color(0xFFFACC15);
const _checkColor = Color(0xFFEF4444);

class XadrezBoardView extends StatelessWidget {
  const XadrezBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<XadrezProvider>();
    final pending = p.pendingPromotion;
    final move = p.lastMove;
    final last = move == null ? const <int>{} : {move.from, move.to};

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF3730A3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final cell = box.maxWidth / 8;
                return Column(
                  children: [
                    for (var r = 0; r < 8; r++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var c = 0; c < 8; c++)
                              Expanded(
                                child: _square(
                                  p,
                                  p.flipped ? 63 - (r * 8 + c) : r * 8 + c,
                                  r,
                                  c,
                                  last,
                                  cell,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (pending != null)
            PromotionPicker(
              side: p.game.position.turn,
              onPick: p.promote,
              onCancel: p.cancelPromotion,
            ),
        ],
      ),
    );
  }

  Widget _square(
    XadrezProvider p,
    int index,
    int row,
    int col,
    Set<int> last,
    double cell,
  ) {
    final dark = ((index ~/ 8) + (index % 8)).isOdd;
    var color = dark ? kXadrezDark : kXadrezLight;
    if (last.contains(index)) {
      color = Color.alphaBlend(_lastMoveTint.withValues(alpha: 0.5), color);
    }
    if (p.selected == index) {
      color = Color.alphaBlend(_selectedTint.withValues(alpha: 0.6), color);
    }
    if (p.checkSquare == index) color = _checkColor;
    final value = p.game.position.cells[index];
    final target = p.targets.contains(index);
    final textColor = dark ? kXadrezLight : kXadrezDark;
    final labelStyle = TextStyle(
      fontSize: (cell * 0.22).clamp(7, 11).toDouble(),
      fontWeight: FontWeight.w700,
      color: textColor,
      height: 1,
    );
    return GestureDetector(
      key: Key('sq-$index'),
      behavior: HitTestBehavior.opaque,
      onTap: () => p.tapSquare(index),
      child: ColoredBox(
        color: color,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (value != 0)
              Center(child: ChessPiece(value: value, size: cell * 0.8)),
            if (target && value == 0)
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.32,
                  heightFactor: 0.32,
                  child: DecoratedBox(
                    key: Key('target-$index'),
                    decoration: BoxDecoration(
                      color: _selectedTint.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            if (target && value != 0)
              DecoratedBox(
                key: Key('capture-$index'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedTint.withValues(alpha: 0.9),
                    width: 3,
                  ),
                ),
              ),
            if (col == 0)
              Positioned(
                left: 2,
                top: 1,
                child: Text(nameOf(index).substring(1), style: labelStyle),
              ),
            if (row == 7)
              Positioned(
                right: 2,
                bottom: 1,
                child: Text(nameOf(index).substring(0, 1), style: labelStyle),
              ),
          ],
        ),
      ),
    );
  }
}
