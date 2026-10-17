// test/widgets/game_palette_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/widgets/game_palette.dart';

void main() {
  final palettes = {
    'Caça-Palavras': kCacaPalavrasPalette,
    'Sudoku': kSudokuPalette,
    '2048': k2048Palette,
    'Velha': kVelhaPalette,
    'Forca': kForcaPalette,
    'Memória': kMemoriaPalette,
    'Termo': kTermoPalette,
    'Lig 4': kLig4Palette,
  };

  test('cada jogo tem uma cor própria', () {
    final accents = palettes.values.map((p) => p.accent).toSet();
    expect(accents, hasLength(palettes.length));
  });

  for (final MapEntry(key: name, value: palette) in palettes.entries) {
    testWidgets('$name: tema claro com o fundo e a cor da paleta', (tester) async {
      final theme = palette.theme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, palette.background);
      expect(theme.textTheme.bodyMedium!.fontFamily, contains('Fredoka'));
    });

    test('$name: texto escuro legível no fundo (contraste ≥ 4.5)', () {
      double luminance(Color c) => c.computeLuminance();
      final light = luminance(palette.background);
      final dark = luminance(palette.dark);
      expect((light + 0.05) / (dark + 0.05), greaterThanOrEqualTo(4.5));
    });
  }
}
