// lib/games/lig4/widgets/board_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/board.dart';
import '../providers/game_provider.dart';

const kLig4Blue = Color(0xFF2563EB);
const kLig4Red = Color(0xFFEF4444);
const kLig4Yellow = Color(0xFFFACC15);

class BoardView extends StatelessWidget {
  const BoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Lig4Provider>();
    final winning = p.winningCells?.toSet() ?? const <(int, int)>{};

    return AspectRatio(
      aspectRatio: kCols / kRows,
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kLig4Blue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            for (var c = 0; c < kCols; c++)
              Expanded(
                child: GestureDetector(
                  key: Key('col-$c'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => p.play(c),
                  child: Column(
                    children: [
                      for (var r = 0; r < kRows; r++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: _Hole(
                              value: p.board[r][c],
                              winning: winning.contains((r, c)),
                              falling: p.lastMove == (r, c),
                              dropRows: r + 1,
                              moveCount: p.moveCount,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hole extends StatelessWidget {
  const _Hole({
    required this.value,
    required this.winning,
    required this.falling,
    required this.dropRows,
    required this.moveCount,
  });

  final int value;
  final bool winning;
  final bool falling;
  final int dropRows;
  final int moveCount;

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      // SizedBox.expand: sem filho, o DecoratedBox ficaria com largura zero.
      return const SizedBox.expand(
        child: DecoratedBox(
          decoration:
              BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
        ),
      );
    }
    Widget piece = SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: value == 1 ? kLig4Red : kLig4Yellow,
          shape: BoxShape.circle,
          border: winning ? Border.all(color: Colors.white, width: 3) : null,
        ),
      ),
    );
    if (winning) piece = _Pulse(child: piece);
    if (!falling) return piece;
    // Cai de cima da coluna até a posição dela.
    return TweenAnimationBuilder<double>(
      key: ValueKey('drop-$moveCount'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
      builder: (context, t, child) => FractionalTranslation(
        translation: Offset(0, -dropRows * (1 - t)),
        child: child,
      ),
      child: piece,
    );
  }
}

/// Pulsa algumas vezes (nunca para sempre: testes usam pumpAndSettle).
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    lowerBound: 1,
    upperBound: 1.12,
  )..repeat(reverse: true, count: 6);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _controller, child: widget.child);
  }
}
