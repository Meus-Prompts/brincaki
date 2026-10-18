// test/games/silabas/word_list_test.dart
import 'package:brincaki/games/silabas/data/word_list.dart';
import 'package:brincaki/games/silabas/logic/word.dart';
import 'package:brincaki/games/silabas/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _letras = 'abcdefghijklmnopqrstuvwxyzáéíóúâêôãõàç';
const _acentos = 'áéíóúâêôãõà';
const _agudoCircunflexo = 'áéíóúâêô';
const _vogais = 'aeiouáéíóúâêôãõà';

/// Todas as palavras codificadas, com o nível.
List<MapEntry<int, String>> _todas() => [
  for (final e in kSilabasWordsByLevel.entries)
    for (final w in e.value) MapEntry(e.key, w),
];

/// Palavras que já passam pelo `parseWord`.
List<MapEntry<int, SilabasWord>> _lidas() => [
  for (final e in _todas())
    if (_tentaLer(e.value) != null) MapEntry(e.key, _tentaLer(e.value)!),
];

SilabasWord? _tentaLer(String encoded) {
  try {
    return parseWord(encoded);
  } on FormatException {
    return null;
  }
}

String _silabaTonica(SilabasWord w) => w.syllables[w.stressIndex];

bool _temDitongoCrescenteNoFim(SilabasWord w) {
  final ultima = w.syllables.length - 1;
  if (w.stressIndex == ultima) return false;
  final s = w.syllables[ultima];
  for (var k = 0; k < s.length - 1; k++) {
    if ((s[k] == 'i' || s[k] == 'u') && _vogais.contains(s[k + 1])) {
      final mudo =
          s[k] == 'u' &&
          k > 0 &&
          (s[k - 1] == 'q' || s[k - 1] == 'g') &&
          (s[k + 1] == 'e' || s[k + 1] == 'i');
      if (!mudo) return true;
    }
  }
  if (s.length == 1 && _vogais.contains(s)) {
    final anterior = w.syllables[ultima - 1];
    final anteriorAtona = w.stressIndex != ultima - 1;
    if (anteriorAtona && (anterior.endsWith('i') || anterior.endsWith('u'))) {
      return true;
    }
  }
  return false;
}

void main() {
  group('kSilabasWordsByLevel', () {
    test('tem os níveis 0, 1 e 2', () {
      expect(kSilabasWordsByLevel.keys.toSet(), {0, 1, 2});
    });

    test('toda palavra é lida pelo parseWord e está em NFC', () {
      final ruins = [
        for (final e in _todas())
          if (_tentaLer(e.value) == null ||
              e.value.runes.any((r) => r >= 0x300 && r <= 0x36F))
            e.value,
      ];
      expect(ruins, isEmpty, reason: 'Palavras inválidas: $ruins');
    });

    test('só usa letras permitidas', () {
      final ruins = [
        for (final e in _lidas())
          if (e.value.text.split('').any((c) => !_letras.contains(c)))
            e.value.text,
      ];
      expect(ruins, isEmpty, reason: 'Letras fora do alfabeto: $ruins');
    });

    test('número de sílabas e de letras de cada nível', () {
      const limites = {
        0: [2, 3],
        1: [2, 4],
        2: [3, 5],
      };
      final ruins = [
        for (final e in _lidas())
          if (e.value.syllables.length < limites[e.key]![0] ||
              e.value.syllables.length > limites[e.key]![1] ||
              e.value.text.length > 10)
            '${e.key}: ${e.value.text}',
      ];
      expect(ruins, isEmpty, reason: 'Fora dos limites: $ruins');
    });

    test('nenhuma palavra se repete', () {
      final vistas = <String>{};
      final repetidas = <String>[];
      for (final e in _lidas()) {
        if (!vistas.add(e.value.text)) repetidas.add(e.value.text);
      }
      expect(repetidas, isEmpty, reason: 'Repetidas: $repetidas');
    });

    test('cada nível tem 40 palavras e 8 de cada classificação', () {
      final problemas = <String>[];
      for (final nivel in kSilabasWordsByLevel.keys) {
        final lidas = [
          for (final e in _lidas())
            if (e.key == nivel) e.value,
        ];
        if (lidas.length < 40) {
          problemas.add('nível $nivel tem ${lidas.length} palavras');
        }
        for (final c in StressClass.values) {
          final n = lidas.where((w) => w.stressClass == c).length;
          if (n < 8) problemas.add('nível $nivel tem $n de ${c.name}');
        }
      }
      expect(problemas, isEmpty, reason: problemas.join('; '));
    });

    test('acento gráfico só na tônica', () {
      final ruins = <String>[];
      for (final e in _lidas()) {
        final w = e.value;
        var foraDaTonica = false;
        for (var i = 0; i < w.syllables.length; i++) {
          if (i == w.stressIndex) continue;
          if (w.syllables[i].split('').any(_acentos.contains)) {
            foraDaTonica = true;
          }
        }
        final agudos = w.text
            .split('')
            .where(_agudoCircunflexo.contains)
            .length;
        if (foraDaTonica || agudos > 1) ruins.add(w.text);
      }
      expect(ruins, isEmpty, reason: 'Acento fora da tônica: $ruins');
    });

    test('proparoxítona sempre tem acento', () {
      final ruins = [
        for (final e in _lidas())
          if (e.value.stressClass == StressClass.proparoxitona &&
              !_silabaTonica(e.value).split('').any(_agudoCircunflexo.contains))
            e.value.text,
      ];
      expect(ruins, isEmpty, reason: 'Proparoxítonas sem acento: $ruins');
    });

    test('oxítona terminada em a, e, o tem acento', () {
      const finais = ['a', 'e', 'o', 'as', 'es', 'os', 'em', 'ens'];
      final ruins = [
        for (final e in _lidas())
          if (e.value.stressClass == StressClass.oxitona &&
              e.value.syllables.length >= 2 &&
              finais.any(e.value.text.endsWith) &&
              !_silabaTonica(e.value).split('').any(_acentos.contains))
            e.value.text,
      ];
      expect(ruins, isEmpty, reason: 'Oxítonas sem acento: $ruins');
    });

    test('sem ditongo crescente átono no fim', () {
      final ruins = [
        for (final e in _lidas())
          if (_temDitongoCrescenteNoFim(e.value)) e.value.text,
      ];
      expect(ruins, isEmpty, reason: 'Ditongo crescente no fim: $ruins');
    });
  });

  group('regra do ditongo crescente', () {
    test('recusa his-TÓ-ria, LÍN-gua e ri-a átonos', () {
      expect(_temDitongoCrescenteNoFim(parseWord('his-TÓ-ria')), isTrue);
      expect(_temDitongoCrescenteNoFim(parseWord('LÍN-gua')), isTrue);
      expect(_temDitongoCrescenteNoFim(parseWord('his-TÓ-ri-a')), isTrue);
    });

    test('aceita que, gue e hiato depois da tônica', () {
      expect(_temDitongoCrescenteNoFim(parseWord('TAN-que')), isFalse);
      expect(_temDitongoCrescenteNoFim(parseWord('fo-GUE-te')), isFalse);
      expect(_temDitongoCrescenteNoFim(parseWord('po-e-SI-a')), isFalse);
      expect(_temDitongoCrescenteNoFim(parseWord('sa-Ú-de')), isFalse);
    });
  });
}
