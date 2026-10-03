// lib/widgets/game_shell.dart

import 'package:flutter/material.dart';

/// Abre um jogo com tema próprio e um Navigator interno.
///
/// O "voltar" do sistema volta uma tela dentro do jogo; na primeira tela do
/// jogo, sai para o menu.
class GameShell extends StatefulWidget {
  const GameShell({
    super.key,
    required this.theme,
    required this.home,
    this.wrapProvider,
  });

  final ThemeData theme;
  final WidgetBuilder home;

  /// Envolve o jogo no provider dele, por exemplo
  /// `(child) => ChangeNotifierProvider(create: (_) => TicTacToeProvider(), child: child)`.
  /// Nulo para jogos que criam o provider na própria tela.
  final Widget Function(Widget child)? wrapProvider;

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final game = Theme(
      data: widget.theme,
      child: NavigatorPopHandler<Object?>(
        onPopWithResult: (_) => _navigatorKey.currentState!.maybePop(),
        child: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (_) => MaterialPageRoute(builder: widget.home),
        ),
      ),
    );
    return widget.wrapProvider?.call(game) ?? game;
  }
}
