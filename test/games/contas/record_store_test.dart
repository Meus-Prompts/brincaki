// test/games/contas/record_store_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brincaki/games/contas/data/record_store.dart';
import 'package:brincaki/games/contas/models/game_state.dart';

void main() {
  final store = SharedPrefsRecordStore();

  group('recorde', () {
    test('sem nada salvo vale 0', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await store.loadRecord(Operation.addition, 1), 0);
    });

    test('salva por operação e nível', () async {
      SharedPreferences.setMockInitialValues({});
      await store.saveRecord(Operation.multiplication, 2, 230);
      expect(await store.loadRecord(Operation.multiplication, 2), 230);
      expect(await store.loadRecord(Operation.multiplication, 1), 0);
      expect(await store.loadRecord(Operation.addition, 2), 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('contas_record_multiplication_2'), 230);
    });

    test('valor de outro tipo ou negativo vale 0', () async {
      for (final value in <Object>['muito', -10, true]) {
        SharedPreferences.setMockInitialValues(
            {'contas_record_addition_1': value});
        expect(await store.loadRecord(Operation.addition, 1), 0,
            reason: '$value');
      }
    });
  });

  group('última escolha', () {
    test('sem nada salvo é null', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await store.loadLastChoice(), isNull);
    });

    test('salva e lê a mesma escolha', () async {
      SharedPreferences.setMockInitialValues({});
      await store.saveLastChoice(
          const LastChoice(Operation.division, 3, AnswerMode.choices));
      final choice = await store.loadLastChoice();
      expect(choice?.operation, Operation.division);
      expect(choice?.level, 3);
      expect(choice?.mode, AnswerMode.choices);
    });

    test('valor estragado é null', () async {
      for (final value in <Object>[
        'x|2|keyboard',
        'addition|7|keyboard',
        'addition|0|keyboard',
        'addition|2',
        'addition|abc|keyboard',
        'addition|2|voz',
        42,
      ]) {
        SharedPreferences.setMockInitialValues({'contas_last': value});
        expect(await store.loadLastChoice(), isNull, reason: '$value');
      }
    });
  });
}
