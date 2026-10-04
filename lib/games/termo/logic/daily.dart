// lib/games/termo/logic/daily.dart

import 'dart:math';

import '../data/word_bank.dart';

final _epoch = DateTime.utc(2026, 1, 1);

/// Palavra do dia: a mesma em todos os celulares na mesma data, sem internet.
String dailyAnswer(WordBank bank, DateTime today) {
  final order = [...bank.answers]..shuffle(Random(20260101));
  final day = DateTime.utc(today.year, today.month, today.day);
  final index = day.difference(_epoch).inDays;
  return order[index % order.length];
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
