// lib/widgets/game_palette.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores de um jogo: as mesmas no cartão do menu e na tela do jogo.
class GamePalette {
  const GamePalette({
    required this.accent,
    required this.light,
    required this.dark,
    required this.background,
  });

  /// Botões, placar e destaques.
  final Color accent;

  /// Fim do gradiente do cartão no menu.
  final Color light;

  /// Título e textos.
  final Color dark;

  /// Fundo da tela do jogo.
  final Color background;

  ThemeData get theme => ThemeData(
        colorSchemeSeed: accent,
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        textTheme: GoogleFonts.fredokaTextTheme(),
      );
}

const kCacaPalavrasPalette = GamePalette(
  accent: Color(0xFFF59E0B),
  light: Color(0xFFFBBF24),
  dark: Color(0xFFB45309),
  background: Color(0xFFFFFBEB),
);

const kSudokuPalette = GamePalette(
  accent: Color(0xFF10B981),
  light: Color(0xFF34D399),
  dark: Color(0xFF047857),
  background: Color(0xFFECFDF5),
);

const k2048Palette = GamePalette(
  accent: Color(0xFFF97316),
  light: Color(0xFFFB923C),
  dark: Color(0xFFC2410C),
  background: Color(0xFFFFF7ED),
);

const kVelhaPalette = GamePalette(
  accent: Color(0xFFEC4899),
  light: Color(0xFFF472B6),
  dark: Color(0xFFBE185D),
  background: Color(0xFFFFF1F2),
);

const kForcaPalette = GamePalette(
  accent: Color(0xFF3B82F6),
  light: Color(0xFF60A5FA),
  dark: Color(0xFF1D4ED8),
  background: Color(0xFFF0F9FF),
);

const kMemoriaPalette = GamePalette(
  accent: Color(0xFF8B5CF6),
  light: Color(0xFFA78BFA),
  dark: Color(0xFF5B21B6),
  background: Color(0xFFF5F3FF),
);

const kTermoPalette = GamePalette(
  accent: Color(0xFF14B8A6),
  light: Color(0xFF2DD4BF),
  dark: Color(0xFF0F766E),
  background: Color(0xFFF0FDFA),
);

const kLig4Palette = GamePalette(
  accent: Color(0xFFEF4444),
  light: Color(0xFFF87171),
  dark: Color(0xFFB91C1C),
  background: Color(0xFFFEF2F2),
);

const kContasPalette = GamePalette(
  accent: Color(0xFF65A30D),
  light: Color(0xFF84CC16),
  dark: Color(0xFF3F6212),
  background: Color(0xFFF7FEE7),
);

const kDamasPalette = GamePalette(
  accent: Color(0xFFA16207),
  light: Color(0xFFCA8A04),
  dark: Color(0xFF713F12),
  background: Color(0xFFFEFCE8),
);

const kXadrezPalette = GamePalette(
  accent: Color(0xFF4F46E5),
  light: Color(0xFF818CF8),
  dark: Color(0xFF3730A3),
  background: Color(0xFFEEF2FF),
);
