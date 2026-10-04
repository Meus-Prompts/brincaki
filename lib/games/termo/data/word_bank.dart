// lib/games/termo/data/word_bank.dart

import 'dart:convert';

import 'package:flutter/services.dart';

/// Palavras aceitas (com a forma acentuada para mostrar) e respostas possíveis.
class WordBank {
  WordBank({required this._valid, required List<String> answers})
      : answers = List.unmodifiable(answers);

  final Map<String, String> _valid;
  final List<String> answers;

  int get validCount => _valid.length;

  bool isValid(String normal) => _valid.containsKey(normal);

  /// Forma com acento, por exemplo 'AVIAO' → 'AVIÃO'.
  String display(String normal) => _valid[normal] ?? normal;

  static Future<WordBank> load(AssetBundle bundle) async {
    // bundle.load + utf8 em vez de loadString: arquivos grandes iriam para
    // um isolate, o que trava em testes de widget.
    Future<List<String>> lines(String path) async {
      final data = await bundle.load(path);
      final text = utf8.decode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      return const LineSplitter().convert(text).where((l) => l.isNotEmpty).toList();
    }

    final valid = <String, String>{};
    for (final line in await lines('assets/termo/validas.txt')) {
      final parts = line.split(';');
      if (parts.length == 2) valid[parts[0]] = parts[1];
    }
    return WordBank(valid: valid, answers: await lines('assets/termo/respostas.txt'));
  }
}
