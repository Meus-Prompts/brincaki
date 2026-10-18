// lib/games/damas/widgets/board_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../providers/game_provider.dart';

const kDamasLight = Color(0xFFF3E3C3);
const kDamasDark = Color(0xFF9A6B3F);
const _selectedTint = Color(0xFF65A30D);
const _lastMoveTint = Color(0xFFE0B04A);

class DamasBoardView extends StatelessWidget {
  const DamasBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DamasProvider>();
    final cells = p.game.position.cells;
    final last = p.lastMove?.path.toSet() ?? const <int>{};
    final path = p.partialPath.toSet();
    final targets = p.targets;
    final must = p.mustCapture;
    final captured = p.capturedSoFar;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: kDamasPalette.dark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            for (var r = 0; r < 8; r++)
              Expanded(
                child: Row(
                  children: [
                    for (var c = 0; c < 8; c++)
                      Expanded(
                        child: _buildSquare(
                          p,
                          p.flipped ? 63 - (r * 8 + c) : r * 8 + c,
                          cells,
                          last,
                          path,
                          targets,
                          must,
                          captured,
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

  Widget _buildSquare(
    DamasProvider p,
    int index,
    List<int> cells,
    Set<int> last,
    Set<int> path,
    Set<int> targets,
    Set<int> must,
    Set<int> captured,
  ) {
    final dark = ((index ~/ 8) + (index % 8)).isOdd;
    Color color = dark ? kDamasDark : kDamasLight;
    if (last.contains(index)) {
      color = Color.alphaBlend(_lastMoveTint.withValues(alpha: 0.55), color);
    }
    if (path.contains(index)) {
      color = Color.alphaBlend(_selectedTint.withValues(alpha: 0.6), color);
    }
    final value = cells[index];
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
              Padding(
                padding: const EdgeInsets.all(3),
                child: _maybeFaded(
                  captured.contains(index),
                  _Piece(
                    white: value > 0,
                    king: value.abs() == 2,
                    highlight: must.contains(index),
                  ),
                ),
              ),
            if (targets.contains(index) && value == 0)
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
          ],
        ),
      ),
    );
  }
}

Widget _maybeFaded(bool faded, Widget child) =>
    faded ? Opacity(opacity: 0.4, child: child) : child;

class _Piece extends StatelessWidget {
  const _Piece({
    required this.white,
    required this.king,
    required this.highlight,
  });

  final bool white;
  final bool king;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    Widget piece = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: white ? const Color(0xFFFFF8E7) : const Color(0xFF2B2B2B),
        border: Border.all(
          color: white ? const Color(0xFFB8A27A) : const Color(0xFF111111),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: king
          ? Padding(
              padding: const EdgeInsets.all(5),
              child: FittedBox(
                child: Icon(
                  Icons.workspace_premium,
                  color: white ? kDamasPalette.accent : const Color(0xFFFACC15),
                ),
              ),
            )
          : null,
    );
    if (highlight) {
      piece = _Pulse(
        child: DecoratedBox(
          key: const Key('must-capture'),
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kDamasPalette.accent, width: 3),
          ),
          child: piece,
        ),
      );
    }
    return piece;
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
    duration: const Duration(milliseconds: 400),
    lowerBound: 1,
    upperBound: 1.1,
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
