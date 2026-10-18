// test/games/contas/fake_record_store.dart

import 'dart:async';

import 'package:brincaki/games/contas/data/record_store.dart';
import 'package:brincaki/games/contas/models/game_state.dart';

/// Loja em memória. [gate] segura as leituras até ser completado e
/// [failLoad]/[failSave] fazem as chamadas lançarem erro.
class FakeRecordStore implements RecordStore {
  FakeRecordStore({
    Map<String, int>? records,
    this.last,
    this.gate,
    this.failLoad = false,
    this.failSave = false,
  }) : records = records ?? {};

  final Map<String, int> records;
  LastChoice? last;
  final Completer<void>? gate;
  final bool failLoad;
  final bool failSave;
  final List<String> saves = [];

  static String key(Operation op, int level) => '${op.name}_$level';

  Future<void> _wait() async {
    if (gate != null) await gate!.future;
    if (failLoad) throw Exception('falhou');
  }

  @override
  Future<int> loadRecord(Operation op, int level) async {
    await _wait();
    return records[key(op, level)] ?? 0;
  }

  @override
  Future<void> saveRecord(Operation op, int level, int value) async {
    if (failSave) throw Exception('falhou');
    records[key(op, level)] = value;
    saves.add('${key(op, level)}=$value');
  }

  @override
  Future<LastChoice?> loadLastChoice() async {
    await _wait();
    return last;
  }

  @override
  Future<void> saveLastChoice(LastChoice choice) async {
    if (failSave) throw Exception('falhou');
    last = choice;
  }
}
