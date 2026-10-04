// lib/games/termo/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/guess_grid.dart';
import '../widgets/termo_keyboard.dart';

const _background = Color(0xFFF0FDFA);
const _dark = Color(0xFF0F766E);

class TermoScreen extends StatefulWidget {
  const TermoScreen({super.key});

  @override
  State<TermoScreen> createState() => _TermoScreenState();
}

class _TermoScreenState extends State<TermoScreen> {
  late final TermoProvider _provider;
  int _shownShake = 0;

  @override
  void initState() {
    super.initState();
    _provider = context.read<TermoProvider>();
    _provider.addListener(_onChange);
  }

  /// Cada erro novo (shakeCount muda) mostra o aviso uma vez.
  void _onChange() {
    if (_provider.shakeCount == _shownShake) return;
    _shownShake = _provider.shakeCount;
    final message = _provider.lastError;
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  void dispose() {
    _provider.removeListener(_onChange);
    super.dispose();
  }

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

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _dark),
            tooltip: 'Voltar ao menu',
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
          title: Text(
            'Termo',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
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
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: p.loading
                        ? Text(
                            'Carregando palavras...',
                            style: GoogleFonts.fredoka(fontSize: 16, color: _dark),
                          )
                        : const GuessGrid(),
                  ),
                ),
                if (!p.loading && p.phase != TermoPhase.playing) const _EndPanel(),
                const SizedBox(height: 8),
                if (!p.loading) const TermoKeyboard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EndPanel extends StatelessWidget {
  const _EndPanel();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TermoProvider>();
    final won = p.phase == TermoPhase.won;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dark.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            won ? '🎉 Acertou em ${p.guesses.length}!' : 'A palavra era: ${p.answerDisplay}',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 6),
          if (p.mode == TermoMode.daily)
            Text(
              'Volte amanhã para a próxima palavra!',
              style: GoogleFonts.fredoka(fontSize: 14, color: Colors.black54),
            )
          else
            ElevatedButton(
              onPressed: p.newUnlimited,
              style: ElevatedButton.styleFrom(
                backgroundColor: _dark,
                foregroundColor: Colors.white,
              ),
              child: Text('Nova palavra', style: GoogleFonts.fredoka(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
