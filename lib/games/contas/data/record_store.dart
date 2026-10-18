// lib/games/contas/data/record_store.dart

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';

/// Operação, nível e forma de responder da última rodada.
class LastChoice {
  const LastChoice(this.operation, this.level, this.mode);

  final Operation operation;
  final int level;
  final AnswerMode mode;
}

abstract class RecordStore {
  Future<int> loadRecord(Operation op, int level);
  Future<void> saveRecord(Operation op, int level, int value);
  Future<LastChoice?> loadLastChoice();
  Future<void> saveLastChoice(LastChoice choice);
}

class SharedPrefsRecordStore implements RecordStore {
  static const _lastKey = 'contas_last';

  static String _recordKey(Operation op, int level) =>
      'contas_record_${op.name}_$level';

  /// Valor ausente, de outro tipo ou negativo vale 0.
  @override
  Future<int> loadRecord(Operation op, int level) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get(_recordKey(op, level));
    return value is int && value > 0 ? value : 0;
  }

  @override
  Future<void> saveRecord(Operation op, int level, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_recordKey(op, level), value);
  }

  /// Salvo como 'multiplication|2|keyboard'. Qualquer coisa diferente dá
  /// `null`.
  @override
  Future<LastChoice?> loadLastChoice() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.get(_lastKey);
    if (raw is! String) return null;
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    final op = Operation.values.asNameMap()[parts[0]];
    final level = int.tryParse(parts[1]);
    final mode = AnswerMode.values.asNameMap()[parts[2]];
    if (op == null || mode == null || level == null) return null;
    if (level < 1 || level > 3) return null;
    return LastChoice(op, level, mode);
  }

  @override
  Future<void> saveLastChoice(LastChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastKey,
      '${choice.operation.name}|${choice.level}|${choice.mode.name}',
    );
  }
}
