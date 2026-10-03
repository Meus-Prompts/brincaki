// lib/games/cacapalavras/screens/home_screen.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/letter_grid.dart';
import '../widgets/word_list.dart';

const _purple = Color(0xFF5B21B6);
const _background = Color(0xFFF5F3FF);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.random});

  /// Só para testes: deixa a grade previsível.
  final Random? random;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WordSearchProvider(random: random),
      child: const _WordSearchView(),
    );
  }
}

class _WordSearchView extends StatelessWidget {
  const _WordSearchView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _purple),
          tooltip: 'Voltar ao menu',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Consumer<WordSearchProvider>(
          builder: (context, p, child) => Text(
            'Caça-Palavras • Nível ${p.level} — ${p.config.theme}',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _purple,
            ),
          ),
        ),
      ),
      body: const SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(child: Center(child: LetterGrid())),
                  SizedBox(height: 16),
                  WordList(),
                ],
              ),
            ),
            _ResultOverlay(),
          ],
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<WordSearchProvider>();
    if (p.phase != WordSearchPhase.won) return const SizedBox.shrink();

    final last = p.isLastLevel;

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(last ? '🏆' : '🎉', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  last
                      ? 'Você completou todos os níveis!'
                      : 'Nível ${p.level} completo!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: p.nextLevel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    last ? 'Jogar de novo' : 'Próximo nível',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
