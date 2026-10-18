// lib/widgets/phone_frame.dart

import 'package:flutter/material.dart';

/// No navegador, numa tela larga, mostra o app numa coluna do tamanho de um
/// celular, no meio da página. Em telas estreitas não muda nada.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.child,
    this.enabled = true,
    this.maxWidth = 480,
  });

  final Widget child;
  final bool enabled;
  final double maxWidth;

  static const _outside = Color(0xFFFDE68A);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (!enabled || media.size.width <= maxWidth) return child;
    return ColoredBox(
      color: _outside,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(
            // Os jogos que medem a tela passam a ver só a coluna.
            data: media.copyWith(size: Size(maxWidth, media.size.height)),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
