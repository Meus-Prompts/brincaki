// lib/games/forca/widgets/hangman_painter.dart

import 'package:flutter/material.dart';
import 'dart:math' show pi;

/// Widget que exibe a forca e o boneco.
/// [wrongCount] de 0 a 6 controla quantas partes são desenhadas.
/// Cada nova parte é animada suavemente quando [wrongCount] aumenta.
class HangmanWidget extends StatefulWidget {
  final int wrongCount;

  const HangmanWidget({super.key, required this.wrongCount});

  @override
  State<HangmanWidget> createState() => _HangmanWidgetState();
}

class _HangmanWidgetState extends State<HangmanWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _prevWrongCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _prevWrongCount = widget.wrongCount;
  }

  @override
  void didUpdateWidget(HangmanWidget old) {
    super.didUpdateWidget(old);
    if (widget.wrongCount > old.wrongCount) {
      _prevWrongCount = old.wrongCount;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => CustomPaint(
        size: const Size(200, 220),
        painter: _HangmanPainter(
          wrongCount: widget.wrongCount.clamp(0, 6),
          newPartProgress: _animation.value,
          prevWrongCount: _prevWrongCount,
        ),
      ),
    );
  }
}

class _HangmanPainter extends CustomPainter {
  final int wrongCount;
  final double newPartProgress;
  final int prevWrongCount;

  _HangmanPainter({
    required this.wrongCount,
    required this.newPartProgress,
    required this.prevWrongCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bodyPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // --- Forca (sempre visível) ---
    // Base
    canvas.drawLine(
      Offset(10, size.height - 10),
      Offset(size.width - 10, size.height - 10),
      paint,
    );
    // Poste vertical
    canvas.drawLine(
      Offset(50, size.height - 10),
      const Offset(50, 10),
      paint,
    );
    // Viga horizontal
    canvas.drawLine(
      const Offset(50, 10),
      Offset(size.width - 50, 10),
      paint,
    );
    // Corda
    canvas.drawLine(
      Offset(size.width - 50, 10),
      Offset(size.width - 50, 45),
      paint,
    );

    // Posições do boneco
    const cx = 150.0; // centro X do boneco
    const headTop = 45.0;
    const headRadius = 22.0;
    const bodyTop = headTop + headRadius * 2;
    const bodyBottom = bodyTop + 60.0;
    const armY = bodyTop + 15.0;

    // Função que retorna o progresso de uma parte específica
    double progressFor(int partIndex) {
      if (wrongCount == partIndex + 1 && prevWrongCount == partIndex) {
        return newPartProgress; // esta é a nova parte sendo animada
      }
      if (wrongCount > partIndex) return 1.0; // já desenhada completamente
      return 0.0; // ainda não desenhada
    }

    // 1: Cabeça
    final headP = progressFor(0);
    if (headP > 0) {
      final sweepAngle = 2 * pi * headP;
      canvas.drawArc(
        Rect.fromCircle(
          center: const Offset(cx, headTop + headRadius),
          radius: headRadius,
        ),
        -pi / 2,
        sweepAngle,
        false,
        bodyPaint,
      );
    }

    // 2: Corpo
    final bodyP = progressFor(1);
    if (bodyP > 0) {
      canvas.drawLine(
        Offset(cx, bodyTop),
        Offset(cx, bodyTop + (bodyBottom - bodyTop) * bodyP),
        bodyPaint,
      );
    }

    // 3: Braço esquerdo
    final lArmP = progressFor(2);
    if (lArmP > 0) {
      canvas.drawLine(
        Offset(cx, armY),
        Offset(cx - 35 * lArmP, armY + 30 * lArmP),
        bodyPaint,
      );
    }

    // 4: Braço direito
    final rArmP = progressFor(3);
    if (rArmP > 0) {
      canvas.drawLine(
        Offset(cx, armY),
        Offset(cx + 35 * rArmP, armY + 30 * rArmP),
        bodyPaint,
      );
    }

    // 5: Perna esquerda
    final lLegP = progressFor(4);
    if (lLegP > 0) {
      canvas.drawLine(
        Offset(cx, bodyBottom),
        Offset(cx - 30 * lLegP, bodyBottom + 50 * lLegP),
        bodyPaint,
      );
    }

    // 6: Perna direita
    final rLegP = progressFor(5);
    if (rLegP > 0) {
      canvas.drawLine(
        Offset(cx, bodyBottom),
        Offset(cx + 30 * rLegP, bodyBottom + 50 * rLegP),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HangmanPainter old) =>
      old.wrongCount != wrongCount ||
      old.newPartProgress != newPartProgress;
}
