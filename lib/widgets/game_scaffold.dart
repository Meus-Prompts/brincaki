// lib/widgets/game_scaffold.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_palette.dart';

/// Estrutura comum das telas de jogo: AppBar com "voltar ao menu", corpo e,
/// quando a partida acaba, o painel de resultado no rodapé.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.palette,
    required this.title,
    required this.body,
    this.actions,
    this.result,
    this.confirmExit = false,
  });

  final GamePalette palette;
  final String title;
  final Widget body;
  final List<Widget>? actions;

  /// Normalmente um `ResultPanel`; fica abaixo do corpo.
  final Widget? result;

  /// Pergunta antes de sair, para não perder uma partida em andamento.
  final bool confirmExit;

  Future<void> _leave(BuildContext context) async {
    if (confirmExit && !await _confirm(context)) return;
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  Future<bool> _confirm(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sair do jogo?', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
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
            child: Text('Sair', style: GoogleFonts.fredoka()),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !confirmExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context);
      },
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: palette.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: palette.dark),
            tooltip: 'Voltar ao menu',
            onPressed: () => _leave(context),
          ),
          title: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: palette.dark,
            ),
          ),
          actions: actions,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: body),
              ?result,
            ],
          ),
        ),
      ),
    );
  }
}
