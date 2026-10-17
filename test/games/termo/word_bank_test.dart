// test/games/termo/word_bank_test.dart

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/logic/normalize.dart';

/// Bundle de teste com arquivos em memória. Devolve os bytes como uma "vista"
/// no meio de um buffer maior, como o Flutter faz às vezes.
class _MemoryBundle extends CachingAssetBundle {
  _MemoryBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw StateError('não achei $key');
    final bytes = utf8.encode(text);
    final padded = Uint8List(bytes.length + 8)..setRange(4, 4 + bytes.length, bytes);
    return ByteData.sublistView(padded, 4, 4 + bytes.length);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordBank em memória', () {
    final bank = WordBank(
      valid: {'AVIAO': 'AVIÃO', 'CARRO': 'CARRO'},
      answers: ['CARRO'],
    );

    test('isValid usa a forma sem acento', () {
      expect(bank.isValid('AVIAO'), isTrue);
      expect(bank.isValid('ZZZZZ'), isFalse);
      expect(bank.isValid('AVIÃO'), isFalse);
    });

    test('display devolve a forma acentuada ou a própria palavra', () {
      expect(bank.display('AVIAO'), 'AVIÃO');
      expect(bank.display('ZZZZZ'), 'ZZZZZ');
    });

    test('validCount e answers', () {
      expect(bank.validCount, 2);
      expect(bank.answers, ['CARRO']);
    });

    test('answers não pode ser alterada', () {
      expect(() => bank.answers.add('PEDRA'), throwsUnsupportedError);
    });

    test('mudar a lista original não muda o banco', () {
      final answers = ['CARRO'];
      final b = WordBank(valid: const {'CARRO': 'CARRO'}, answers: answers);
      answers.add('PEDRA');
      expect(b.answers, ['CARRO']);
    });
  });

  group('WordBank.load com bundle de teste', () {
    test('lê as duas listas, com acentos em UTF-8', () async {
      final bank = await WordBank.load(_MemoryBundle({
        'assets/termo/validas.txt': 'AVIAO;AVIÃO\nCARRO;CARRO\nACUCA;AÇÚCA\n',
        'assets/termo/respostas.txt': 'CARRO\nAVIAO\n',
      }));
      expect(bank.validCount, 3);
      expect(bank.display('AVIAO'), 'AVIÃO');
      expect(bank.display('ACUCA'), 'AÇÚCA');
      expect(bank.answers, ['CARRO', 'AVIAO']);
    });

    test('ignora linhas vazias e linhas mal formadas', () async {
      final bank = await WordBank.load(_MemoryBundle({
        'assets/termo/validas.txt': '\nAVIAO;AVIÃO\n\nSEMPONTO\nA;B;C\nCARRO;CARRO',
        'assets/termo/respostas.txt': '\n\nCARRO\n\n',
      }));
      expect(bank.validCount, 2);
      expect(bank.isValid('SEMPONTO'), isFalse);
      expect(bank.isValid('A'), isFalse);
      expect(bank.answers, ['CARRO']);
    });

    test('aceita quebras de linha do Windows', () async {
      final bank = await WordBank.load(_MemoryBundle({
        'assets/termo/validas.txt': 'CARRO;CARRO\r\nPEDRA;PEDRA\r\n',
        'assets/termo/respostas.txt': 'CARRO\r\nPEDRA\r\n',
      }));
      expect(bank.isValid('PEDRA'), isTrue);
      expect(bank.answers, ['CARRO', 'PEDRA']);
    });

    test('arquivo faltando dá erro', () async {
      await expectLater(
        WordBank.load(_MemoryBundle({'assets/termo/validas.txt': 'CARRO;CARRO'})),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('listas reais do app', () {
    late WordBank bank;

    setUpAll(() async {
      bank = await WordBank.load(rootBundle);
    });

    test('são válidas', () {
      final five = RegExp(r'^[A-Z]{5}$');
      expect(bank.answers.length, greaterThanOrEqualTo(500));
      expect(bank.validCount, greaterThanOrEqualTo(3000));
      expect(bank.answers.toSet().length, bank.answers.length,
          reason: 'resposta repetida');
      for (final answer in bank.answers) {
        expect(answer, matches(five));
        expect(bank.isValid(answer), isTrue, reason: answer);
        final shown = bank.display(answer);
        expect(shown.length, 5, reason: shown);
        expect(normalizeWord(shown), answer, reason: shown);
      }
    });

    test('plurais e femininos comuns são aceitos como tentativa', () {
      for (final word in ['GATOS', 'MESAS', 'RATOS', 'OUTRA', 'CASAS', 'BOLAS']) {
        expect(bank.isValid(word), isTrue, reason: word);
      }
    });

    test('respostas não incluem palavras impróprias para a família', () {
      for (final word in ['NEGRO', 'NEGRA', 'INDIO', 'BURRO', 'BESTA', 'PERUA', 'ESSES']) {
        expect(bank.answers, isNot(contains(word)), reason: word);
      }
    });
  });
}
