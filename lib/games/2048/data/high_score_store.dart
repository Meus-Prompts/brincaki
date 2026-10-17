// lib/games/2048/data/high_score_store.dart

import 'package:shared_preferences/shared_preferences.dart';

abstract class HighScoreStore {
  Future<int> load();
  Future<void> save(int value);
}

class SharedPrefsHighScoreStore implements HighScoreStore {
  static const _key = 'game2048_best';

  /// Valor ausente, de outro tipo ou negativo vale 0.
  @override
  Future<int> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get(_key);
    return value is int && value > 0 ? value : 0;
  }

  @override
  Future<void> save(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
  }
}
