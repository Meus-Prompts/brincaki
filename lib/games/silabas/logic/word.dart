// lib/games/silabas/logic/word.dart
import '../models/game_state.dart';

/// Palavra separada em sílabas, com a sílaba tônica marcada.
class SilabasWord {
  /// Sílabas em minúsculas.
  final List<String> syllables;

  /// Índice da sílaba tônica em [syllables].
  final int stressIndex;

  const SilabasWord(this.syllables, this.stressIndex);

  String get text => syllables.join();

  StressClass get stressClass {
    switch (syllables.length - 1 - stressIndex) {
      case 0:
        return StressClass.oxitona;
      case 1:
        return StressClass.paroxitona;
      default:
        return StressClass.proparoxitona;
    }
  }

  /// Posições de corte: índice da letra antes da qual o corte fica em [text].
  Set<int> get cutPositions {
    final cuts = <int>{};
    var total = 0;
    for (var i = 0; i < syllables.length - 1; i++) {
      total += syllables[i].length;
      cuts.add(total);
    }
    return cuts;
  }
}

/// Lê uma palavra codificada como `PÁS-sa-ro` (tônica em maiúsculas).
SilabasWord parseWord(String encoded) {
  final parts = encoded.split('-');
  if (parts.length < 2) {
    throw FormatException(
      'A palavra precisa de ao menos duas sílabas',
      encoded,
    );
  }
  if (parts.any((p) => p.isEmpty)) {
    throw FormatException('Sílaba vazia', encoded);
  }
  final stressed = <int>[
    for (var i = 0; i < parts.length; i++)
      if (parts[i] == parts[i].toUpperCase() &&
          parts[i] != parts[i].toLowerCase())
        i,
  ];
  if (stressed.length != 1) {
    throw FormatException('Deve haver exatamente uma sílaba tônica', encoded);
  }
  if (parts.length - 1 - stressed.first > 2) {
    throw FormatException('A tônica deve estar entre as três últimas', encoded);
  }
  return SilabasWord(
    List.unmodifiable(parts.map((p) => p.toLowerCase())),
    stressed.first,
  );
}

String stressClassLabel(StressClass c) {
  switch (c) {
    case StressClass.oxitona:
      return 'Oxítona';
    case StressClass.paroxitona:
      return 'Paroxítona';
    case StressClass.proparoxitona:
      return 'Proparoxítona';
  }
}

String stressClassHint(StressClass c) {
  switch (c) {
    case StressClass.oxitona:
      return 'a última é a mais forte';
    case StressClass.paroxitona:
      return 'a penúltima é a mais forte';
    case StressClass.proparoxitona:
      return 'a antepenúltima é a mais forte';
  }
}
