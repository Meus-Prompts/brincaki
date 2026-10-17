// lib/games/termo/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../../../widgets/game_scaffold.dart';
import '../../../widgets/result_panel.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/guess_grid.dart';
import '../widgets/termo_keyboard.dart';

class TermoScreen extends StatefulWidget {
  const TermoScreen({super.key});

  @override
  State<TermoScreen> createState() => _TermoScreenState();
}

class _TermoScreenState extends State<TermoScreen> {
  late final TermoProvider _provider = context.read<TermoProvider>();

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _provider.submit();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _provider.backspace();
      return KeyEventResult.handled;
    }
    final label = event.logicalKey.keyLabel;
    if (label.length == 1) {
      _provider.type(label);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TermoProvider>();
    final ended = !p.loading && p.phase != TermoPhase.playing;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: GameScaffold(
        palette: kTermoPalette,
        title: 'Termo',
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Column(
            children: [
              SegmentedButton<TermoMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: TermoMode.daily, label: Text('Palavra do dia')),
                  ButtonSegment(value: TermoMode.unlimited, label: Text('Ilimitado')),
                ],
                selected: {p.mode},
                onSelectionChanged: (s) => p.setMode(s.first),
              ),
              // Aviso no topo: não cobre o teclado. Some ao digitar de novo.
              SizedBox(
                height: 32,
                child: Center(
                  child: p.lastError == null
                      ? null
                      : Text(
                          p.lastError!,
                          key: ValueKey('erro-${p.shakeCount}'),
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Center(
                  child: p.loading
                      ? Text(
                          'Carregando palavras...',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            color: kTermoPalette.dark,
                          ),
                        )
                      : const GuessGrid(),
                ),
              ),
              // Com a partida terminada, o painel de resultado fica no lugar
              // do teclado.
              if (!p.loading && !ended) ...[
                const SizedBox(height: 8),
                const TermoKeyboard(),
              ],
            ],
          ),
        ),
        result: ended ? _result(p) : null,
      ),
    );
  }

  Widget _result(TermoProvider p) {
    final won = p.phase == TermoPhase.won;
    final daily = p.mode == TermoMode.daily;
    return ResultPanel(
      palette: kTermoPalette,
      emoji: won ? '🎉' : '😢',
      title: won ? 'Acertou em ${p.guesses.length}!' : 'A palavra era: ${p.answerDisplay}',
      message: daily ? 'Volte amanhã para a próxima palavra!' : null,
      actions: [
        if (!daily) ResultAction('Nova palavra', p.newUnlimited),
      ],
    );
  }
}
