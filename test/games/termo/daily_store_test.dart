// test/games/termo/daily_store_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brincaki/games/termo/data/daily_store.dart';

void main() {
  group('DailyState', () {
    test('toJson e fromJson ida e volta', () {
      const state = DailyState(date: '2026-10-04', guesses: ['PORTA', 'CARRO']);
      final back = DailyState.fromJson(state.toJson())!;
      expect(back.date, '2026-10-04');
      expect(back.guesses, ['PORTA', 'CARRO']);
    });

    test('fromJson rejeita o que não é mapa', () {
      expect(DailyState.fromJson('oi'), isNull);
      expect(DailyState.fromJson(null), isNull);
      expect(DailyState.fromJson([1, 2]), isNull);
    });

    test('fromJson rejeita campos faltando ou de outro tipo', () {
      expect(DailyState.fromJson({'date': 1}), isNull);
      expect(DailyState.fromJson({'date': '2026-10-04'}), isNull);
      expect(DailyState.fromJson({'guesses': <String>[]}), isNull);
      expect(DailyState.fromJson({'date': '2026-10-04', 'guesses': 'PORTA'}), isNull);
    });

    test('fromJson descarta tentativas que não são texto', () {
      final s = DailyState.fromJson({
        'date': '2026-10-04',
        'guesses': ['PORTA', 3, null, 'CARRO'],
      });
      expect(s!.guesses, ['PORTA', 'CARRO']);
    });
  });

  group('SharedPrefsDailyStore', () {
    test('sem nada salvo carrega null', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SharedPrefsDailyStore().load(), isNull);
    });

    test('salvar e carregar devolve o mesmo dia', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPrefsDailyStore();
      await store.save(const DailyState(date: '2026-10-04', guesses: ['PORTA']));
      final loaded = await store.load();
      expect(loaded!.date, '2026-10-04');
      expect(loaded.guesses, ['PORTA']);
    });

    test('salvar de novo substitui o dia anterior', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPrefsDailyStore();
      await store.save(const DailyState(date: '2026-10-04', guesses: ['PORTA']));
      await store.save(const DailyState(date: '2026-10-05', guesses: []));
      final loaded = await store.load();
      expect(loaded!.date, '2026-10-05');
      expect(loaded.guesses, isEmpty);
    });

    test('carrega o JSON gravado por versões anteriores', () async {
      SharedPreferences.setMockInitialValues({
        'termo_daily': '{"date":"2026-10-04","guesses":["CARRO","PEDRA"]}',
      });
      final loaded = await SharedPrefsDailyStore().load();
      expect(loaded!.guesses, ['CARRO', 'PEDRA']);
    });

    test('JSON corrompido carrega null', () async {
      SharedPreferences.setMockInitialValues({'termo_daily': '{"date": "2026-'});
      expect(await SharedPrefsDailyStore().load(), isNull);
    });

    test('JSON válido com formato errado carrega null', () async {
      SharedPreferences.setMockInitialValues({'termo_daily': '[1, 2, 3]'});
      expect(await SharedPrefsDailyStore().load(), isNull);
    });

    test('valor de outro tipo na chave carrega null', () async {
      SharedPreferences.setMockInitialValues({'termo_daily': 42});
      expect(await SharedPrefsDailyStore().load(), isNull);
    });
  });
}
