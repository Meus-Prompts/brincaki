// test/games/2048/high_score_store_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brincaki/games/2048/data/high_score_store.dart';

void main() {
  group('SharedPrefsHighScoreStore', () {
    test('sem nada salvo carrega 0', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SharedPrefsHighScoreStore().load(), 0);
    });

    test('carrega o valor salvo antes', () async {
      SharedPreferences.setMockInitialValues({'game2048_best': 2048});
      expect(await SharedPrefsHighScoreStore().load(), 2048);
    });

    test('salvar e carregar devolve o mesmo valor', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPrefsHighScoreStore();
      await store.save(1234);
      expect(await store.load(), 1234);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('game2048_best'), 1234);
    });

    test('salvar de novo substitui o valor', () async {
      SharedPreferences.setMockInitialValues({'game2048_best': 50});
      final store = SharedPrefsHighScoreStore();
      await store.save(80);
      expect(await store.load(), 80);
    });

    test('valor de outro tipo na chave carrega 0', () async {
      SharedPreferences.setMockInitialValues({'game2048_best': 'muito'});
      expect(await SharedPrefsHighScoreStore().load(), 0);
    });

    test('valor negativo carrega 0', () async {
      SharedPreferences.setMockInitialValues({'game2048_best': -10});
      expect(await SharedPrefsHighScoreStore().load(), 0);
    });

    test('não mexe em outras chaves', () async {
      SharedPreferences.setMockInitialValues({'outra': 7});
      await SharedPrefsHighScoreStore().save(10);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('outra'), 7);
    });
  });
}
