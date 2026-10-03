// lib/games/cacapalavras/services/grid_generator.dart

import 'dart:math';

import '../models/game_state.dart';

class GeneratedGrid {
  const GeneratedGrid({required this.letters, required this.words});

  final List<List<String>> letters;
  final List<PlacedWord> words;
}

/// Monta uma grade [size]×[size] com [wordCount] palavras sorteadas de
/// [candidates]. Duas palavras compartilham no máximo uma célula, e só se a
/// letra for a mesma.
GeneratedGrid generateGrid({
  required List<String> candidates,
  required int wordCount,
  required int size,
  required List<Direction> directions,
  required Random random,
}) {
  for (var attempt = 0; attempt < 10; attempt++) {
    final grid = _tryGenerate(candidates, wordCount, size, directions, random);
    if (grid != null) return grid;
  }
  throw StateError('Não foi possível montar a grade com $wordCount palavras');
}

GeneratedGrid? _tryGenerate(
  List<String> candidates,
  int wordCount,
  int size,
  List<Direction> directions,
  Random random,
) {
  final pool = [...candidates]..shuffle(random);
  // Palavras longas primeiro: são as mais difíceis de encaixar.
  final queue = pool.take(wordCount).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final reserve = pool.skip(wordCount).toList();

  final grid = List.generate(size, (_) => List<String?>.filled(size, null));
  final placed = <PlacedWord>[];

  while (placed.length < wordCount) {
    if (queue.isEmpty) {
      if (reserve.isEmpty) return null;
      queue.add(reserve.removeAt(0));
    }
    final word = queue.removeAt(0);
    final placement = _place(grid, word, directions, random);
    if (placement != null) placed.add(placement);
  }

  // O preenchimento aleatório pode formar uma segunda cópia de uma palavra,
  // que a criança veria mas o jogo não aceitaria. Sorteia de novo nesse caso.
  for (var fill = 0; fill < 20; fill++) {
    final letters = [
      for (final row in grid)
        [
          for (final l in row)
            l ?? String.fromCharCode(65 + random.nextInt(26)),
        ],
    ];
    if (placed.every((w) => _occurrences(letters, w.word) == 1)) {
      return GeneratedGrid(letters: letters, words: placed);
    }
  }
  return null;
}

/// Quantos trechos retos distintos da grade formam [word], em qualquer das 8
/// direções (um palíndromo lido nos dois sentidos conta uma vez).
int _occurrences(List<List<String>> letters, String word) {
  final size = letters.length;
  final found = <String>{};
  for (final d in Direction.values) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final endRow = r + d.dr * (word.length - 1);
        final endCol = c + d.dc * (word.length - 1);
        if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) {
          continue;
        }
        var matches = true;
        for (var k = 0; k < word.length; k++) {
          if (letters[r + d.dr * k][c + d.dc * k] != word[k]) {
            matches = false;
            break;
          }
        }
        if (!matches) continue;
        // Mesma reta nos dois sentidos: identifica pelas pontas ordenadas.
        final ends = [(r, c), (endRow, endCol)]
          ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
        found.add('${ends.first}-${ends.last}');
      }
    }
  }
  return found.length;
}

PlacedWord? _place(
  List<List<String?>> grid,
  String word,
  List<Direction> directions,
  Random random,
) {
  final size = grid.length;
  final options = [
    for (final d in directions)
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++) (d, r, c),
  ]..shuffle(random);

  for (final (dir, row, col) in options) {
    final endRow = row + dir.dr * (word.length - 1);
    final endCol = col + dir.dc * (word.length - 1);
    if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) continue;

    final cells = [
      for (var k = 0; k < word.length; k++)
        (row + dir.dr * k, col + dir.dc * k),
    ];

    var overlaps = 0;
    var fits = true;
    for (var k = 0; k < word.length; k++) {
      final existing = grid[cells[k].$1][cells[k].$2];
      if (existing == null) continue;
      overlaps++;
      if (existing != word[k] || overlaps > 1) {
        fits = false;
        break;
      }
    }
    if (!fits) continue;

    for (var k = 0; k < word.length; k++) {
      grid[cells[k].$1][cells[k].$2] = word[k];
    }
    return PlacedWord(word: word, direction: dir, cells: cells);
  }
  return null;
}
