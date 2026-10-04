// lib/games/termo/data/daily_store.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DailyState {
  const DailyState({required this.date, required this.guesses});

  /// Data no formato yyyy-MM-dd.
  final String date;
  final List<String> guesses;

  Map<String, Object> toJson() => {'date': date, 'guesses': guesses};

  static DailyState? fromJson(Object? json) {
    if (json is! Map) return null;
    final date = json['date'];
    final guesses = json['guesses'];
    if (date is! String || guesses is! List) return null;
    return DailyState(
      date: date,
      guesses: [for (final g in guesses) if (g is String) g],
    );
  }
}

abstract class DailyStore {
  Future<DailyState?> load();
  Future<void> save(DailyState state);
}

class SharedPrefsDailyStore implements DailyStore {
  static const _key = 'termo_daily';

  @override
  Future<DailyState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return DailyState.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(DailyState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
