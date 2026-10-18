// test/games/silabas/word_test.dart
import 'package:brincaki/games/silabas/logic/word.dart';
import 'package:brincaki/games/silabas/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseWord', () {
    test('proparoxítona: PÁS-sa-ro', () {
      final w = parseWord('PÁS-sa-ro');
      expect(w.syllables, ['pás', 'sa', 'ro']);
      expect(w.stressIndex, 0);
      expect(w.text, 'pássaro');
      expect(w.stressClass, StressClass.proparoxitona);
      expect(w.cutPositions, {3, 5});
    });

    test('paroxítona: ja-NE-la', () {
      final w = parseWord('ja-NE-la');
      expect(w.stressIndex, 1);
      expect(w.stressClass, StressClass.paroxitona);
      expect(w.cutPositions, {2, 4});
    });

    test('oxítona: ja-ca-RÉ', () {
      final w = parseWord('ja-ca-RÉ');
      expect(w.stressIndex, 2);
      expect(w.stressClass, StressClass.oxitona);
      expect(w.text, 'jacaré');
    });

    test('oxítona com til: co-ra-ÇÃO', () {
      final w = parseWord('co-ra-ÇÃO');
      expect(w.text, 'coração');
      expect(w.stressClass, StressClass.oxitona);
      expect(w.cutPositions, {2, 4});
    });

    test('lança FormatException para entradas inválidas', () {
      for (final bad in [
        'sapato',
        'sa-pa-to',
        'SA-PA-to',
        'E-xer-ci-to',
        'sa--to',
      ]) {
        expect(() => parseWord(bad), throwsFormatException, reason: bad);
      }
    });
  });

  test('rótulos das classes', () {
    expect(stressClassLabel(StressClass.oxitona), 'Oxítona');
    expect(stressClassLabel(StressClass.paroxitona), 'Paroxítona');
    expect(stressClassLabel(StressClass.proparoxitona), 'Proparoxítona');
  });

  test('dicas das classes', () {
    expect(stressClassHint(StressClass.oxitona), 'a última é a mais forte');
    expect(
      stressClassHint(StressClass.paroxitona),
      'a penúltima é a mais forte',
    );
    expect(
      stressClassHint(StressClass.proparoxitona),
      'a antepenúltima é a mais forte',
    );
  });
}
