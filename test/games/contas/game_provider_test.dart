// test/games/contas/game_provider_test.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/contas/data/record_store.dart';
import 'package:brincaki/games/contas/models/game_state.dart';
import 'package:brincaki/games/contas/providers/game_provider.dart';

import 'fake_record_store.dart';

/// Sem a pausa contra toque duplo, para responder várias contas seguidas.
ContasProvider newProvider({FakeRecordStore? store, int seed = 1}) =>
    ContasProvider(
      store: store ?? FakeRecordStore(),
      random: Random(seed),
      inputDelay: Duration.zero,
    );

/// Responde certo pelo teclado (ou pelas opções, no modo opções).
void answerRight(ContasProvider p) {
  final answer = p.problem!.answer;
  if (p.answerMode == AnswerMode.choices) {
    p.choose(answer);
    return;
  }
  for (final digit in '$answer'.split('')) {
    p.typeDigit(int.parse(digit));
  }
  p.submit();
}

void answerWrong(ContasProvider p) {
  final wrong = p.problem!.answer + 1;
  if (p.answerMode == AnswerMode.choices) {
    p.choose(p.choices.firstWhere((c) => c != p.problem!.answer));
    return;
  }
  for (final digit in '$wrong'.split('')) {
    p.typeDigit(int.parse(digit));
  }
  p.submit();
}

void main() {
  group('início', () {
    test('começa na escolha com adição, nível 1 e teclado', () {
      final p = newProvider();
      expect(p.phase, ContasPhase.setup);
      expect(p.operation, Operation.addition);
      expect(p.level, 1);
      expect(p.answerMode, AnswerMode.keyboard);
      expect(p.problem, isNull);
    });

    test('start começa a rodada com a escolha feita', () {
      final p = newProvider()
        ..select(operation: Operation.multiplication, level: 2)
        ..start();
      expect(p.phase, ContasPhase.playing);
      expect(p.lives, ContasProvider.maxLives);
      expect(p.score, 0);
      expect(p.streak, 0);
      expect(p.problem!.operation, Operation.multiplication);
      expect(p.problem!.operands.any((n) => n >= 6), isTrue);
      expect(p.choices, isEmpty);
    });

    test('select muda só o que foi passado', () {
      final p = newProvider()..select(mode: AnswerMode.choices);
      expect(p.answerMode, AnswerMode.choices);
      expect(p.operation, Operation.addition);
      p.select(level: 3);
      expect(p.level, 3);
      expect(p.answerMode, AnswerMode.choices);
    });

    test('select ignora nível fora de 1 a 3', () {
      final p = newProvider()..select(level: 4);
      expect(p.level, 1);
      p.select(level: 0);
      expect(p.level, 1);
    });

    test('start salva a última escolha', () async {
      final store = FakeRecordStore();
      newProvider(store: store)
        ..select(operation: Operation.division, level: 3, mode: AnswerMode.choices)
        ..start();
      await pumpEventQueue();
      expect(store.last?.operation, Operation.division);
      expect(store.last?.level, 3);
      expect(store.last?.mode, AnswerMode.choices);
    });
  });

  group('pontos e sequência', () {
    test('5 acertos seguidos valem 10 cada', () {
      final p = newProvider()..start();
      for (var i = 0; i < 5; i++) {
        answerRight(p);
      }
      expect(p.score, 50);
      expect(p.streak, 5);
      expect(p.lastPoints, 10);
      expect(p.multiplier, 2);
      expect(p.correctCount, 5);
    });

    test('do 6º ao 10º acerto valem 20', () {
      final p = newProvider()..start();
      for (var i = 0; i < 6; i++) {
        answerRight(p);
      }
      expect(p.lastPoints, 20);
      expect(p.score, 70);
    });

    test('o multiplicador para em ×5', () {
      final p = newProvider()..start();
      for (var i = 0; i < 25; i++) {
        answerRight(p);
      }
      expect(p.multiplier, 5);
      answerRight(p);
      expect(p.lastPoints, 50);
      for (var i = 0; i < 10; i++) {
        answerRight(p);
      }
      expect(p.multiplier, 5);
      expect(p.lastPoints, 50);
    });

    test('comemoração a cada 5 seguidas', () {
      final p = newProvider()..start();
      for (var i = 0; i < 4; i++) {
        answerRight(p);
      }
      expect(p.isMilestone, isFalse);
      answerRight(p);
      expect(p.isMilestone, isTrue);
      answerRight(p);
      expect(p.isMilestone, isFalse);
    });

    test('acerto troca a conta e limpa o que foi digitado', () {
      final p = newProvider()..start();
      final first = p.problem;
      answerRight(p);
      expect(p.problem, isNot(first));
      expect(p.typed, '');
    });
  });

  group('erros e vidas', () {
    test('erro tira uma vida, zera a sequência e mostra a resposta', () {
      final p = newProvider()..start();
      answerRight(p);
      answerRight(p);
      final problem = p.problem;
      answerWrong(p);
      expect(p.phase, ContasPhase.mistake);
      expect(p.lives, 2);
      expect(p.streak, 0);
      expect(p.multiplier, 1);
      expect(p.problem, problem);
      expect(p.score, 20);
    });

    test('continuar depois do erro traz outra conta', () {
      final p = newProvider()..start();
      final problem = p.problem;
      answerWrong(p);
      p.continueAfterMistake();
      expect(p.phase, ContasPhase.playing);
      expect(p.problem, isNot(problem));
      expect(p.typed, '');
    });

    test('a maior sequência fica guardada', () {
      final p = newProvider()..start();
      for (var i = 0; i < 4; i++) {
        answerRight(p);
      }
      answerWrong(p);
      p.continueAfterMistake();
      answerRight(p);
      expect(p.streak, 1);
      expect(p.bestStreak, 4);
    });

    test('no 3º erro a rodada acaba', () {
      final p = newProvider()..start();
      for (var i = 0; i < 2; i++) {
        answerWrong(p);
        p.continueAfterMistake();
      }
      answerWrong(p);
      expect(p.phase, ContasPhase.finished);
      expect(p.lives, 0);
      expect(p.endedByMistake, isTrue);
    });
  });

  group('recorde', () {
    Future<ContasProvider> finishWith(FakeRecordStore store, int hits) async {
      final p = newProvider(store: store);
      await pumpEventQueue();
      p.start();
      for (var i = 0; i < hits; i++) {
        answerRight(p);
      }
      p.stop();
      await pumpEventQueue();
      return p;
    }

    test('passar do recorde salva e marca recorde novo', () async {
      final store = FakeRecordStore();
      final p = await finishWith(store, 3);
      expect(p.isNewRecord, isTrue);
      expect(store.saves, ['addition_1=30']);
      expect(p.record(Operation.addition, 1), 30);
      expect(p.currentRecord, 30);
    });

    test('empatar com o recorde não é recorde novo', () async {
      final store = FakeRecordStore(records: {'addition_1': 30});
      final p = await finishWith(store, 3);
      expect(p.isNewRecord, isFalse);
      expect(store.saves, isEmpty);
    });

    test('rodada sem pontos não é recorde novo', () async {
      final store = FakeRecordStore();
      final p = await finishWith(store, 0);
      expect(p.isNewRecord, isFalse);
      expect(store.saves, isEmpty);
    });

    test('parar termina sem ser por erro', () async {
      final p = await finishWith(FakeRecordStore(), 2);
      expect(p.phase, ContasPhase.finished);
      expect(p.endedByMistake, isFalse);
      expect(p.score, 20);
    });

    test('parar também funciona depois de um erro', () {
      final p = newProvider()..start();
      answerWrong(p);
      p.stop();
      expect(p.phase, ContasPhase.finished);
      expect(p.endedByMistake, isFalse);
    });

    test('o 3º erro também salva o recorde', () async {
      final store = FakeRecordStore();
      final p = newProvider(store: store)..start();
      answerRight(p);
      for (var i = 0; i < 3; i++) {
        answerWrong(p);
        p.continueAfterMistake();
      }
      await pumpEventQueue();
      expect(store.saves, ['addition_1=10']);
    });

    test('recorde é separado por operação e nível', () async {
      final store = FakeRecordStore(
          records: {'multiplication_2': 230, 'addition_1': 40});
      final p = newProvider(store: store);
      await pumpEventQueue();
      expect(p.record(Operation.multiplication, 2), 230);
      expect(p.record(Operation.multiplication, 1), 0);
      expect(p.currentRecord, 40);
      p.select(operation: Operation.multiplication, level: 2);
      expect(p.currentRecord, 230);
    });
  });

  group('resposta à vista', () {
    test('só depois de errar', () {
      final p = newProvider()..start();
      expect(p.answerRevealed, isFalse);
      answerWrong(p);
      expect(p.answerRevealed, isTrue);
      p.continueAfterMistake();
      expect(p.answerRevealed, isFalse);
    });

    test('continua à vista ao parar depois de um erro', () {
      final p = newProvider()..start();
      answerWrong(p);
      p.stop();
      expect(p.answerRevealed, isTrue);
    });

    test('parar sem erro pendente não mostra a resposta', () {
      final p = newProvider()..start();
      p.stop();
      expect(p.answerRevealed, isFalse);
    });

    test('no 3º erro a resposta fica à vista', () {
      final p = newProvider()..start();
      for (var i = 0; i < 3; i++) {
        answerWrong(p);
        p.continueAfterMistake();
      }
      expect(p.answerRevealed, isTrue);
      p.playAgain();
      expect(p.answerRevealed, isFalse);
    });
  });

  group('teclado', () {
    test('aceita até 4 dígitos', () {
      final p = newProvider()..start();
      for (final d in [1, 2, 3, 4, 5]) {
        p.typeDigit(d);
      }
      expect(p.typed, '1234');
    });

    test('zero à esquerda é ignorado', () {
      final p = newProvider()..start();
      p.typeDigit(0);
      expect(p.typed, '0');
      p.typeDigit(0);
      expect(p.typed, '0');
      p.typeDigit(5);
      expect(p.typed, '5');
    });

    test('dígito fora de 0 a 9 é ignorado', () {
      final p = newProvider()..start();
      p.typeDigit(10);
      p.typeDigit(-1);
      expect(p.typed, '');
    });

    test('apagar tira o último dígito', () {
      final p = newProvider()..start();
      p.typeDigit(4);
      p.typeDigit(2);
      p.deleteDigit();
      expect(p.typed, '4');
      p.deleteDigit();
      p.deleteDigit();
      expect(p.typed, '');
    });

    test('confirmar vazio não faz nada', () {
      final p = newProvider()..start();
      final problem = p.problem;
      p.submit();
      expect(p.phase, ContasPhase.playing);
      expect(p.problem, problem);
      expect(p.lives, 3);
    });
  });

  group('opções', () {
    test('4 opções com a resposta certa', () {
      final p = newProvider()
        ..select(mode: AnswerMode.choices)
        ..start();
      expect(p.choices, hasLength(4));
      expect(p.choices, contains(p.problem!.answer));
    });

    test('acertar e errar pelas opções', () {
      final p = newProvider()
        ..select(mode: AnswerMode.choices)
        ..start();
      answerRight(p);
      expect(p.score, 10);
      expect(p.choices, contains(p.problem!.answer));
      answerWrong(p);
      expect(p.phase, ContasPhase.mistake);
    });

    test('valor que não está nas opções é ignorado', () {
      final p = newProvider()
        ..select(mode: AnswerMode.choices)
        ..start();
      p.choose(-5);
      expect(p.phase, ContasPhase.playing);
      expect(p.lives, 3);
    });
  });

  group('guardas de fase', () {
    test('nada de jogo funciona na escolha', () {
      final p = newProvider();
      p.typeDigit(3);
      p.deleteDigit();
      p.submit();
      p.choose(3);
      p.continueAfterMistake();
      p.stop();
      p.playAgain();
      p.exitToSetup();
      expect(p.phase, ContasPhase.setup);
      expect(p.typed, '');
    });

    test('depois do erro, teclado e opções não mudam nada', () {
      final p = newProvider()..start();
      answerWrong(p);
      p.typeDigit(3);
      p.deleteDigit();
      p.submit();
      p.choose(p.problem!.answer);
      expect(p.lives, 2);
      expect(p.score, 0);
      expect(p.phase, ContasPhase.mistake);
    });

    test('no fim, nada muda os pontos', () {
      final p = newProvider()..start();
      answerRight(p);
      p.stop();
      final problem = p.problem;
      p.typeDigit(1);
      p.submit();
      p.choose(problem!.answer);
      p.continueAfterMistake();
      p.stop();
      p.select(level: 3);
      p.start();
      expect(p.score, 10);
      expect(p.phase, ContasPhase.finished);
      expect(p.level, 1);
    });

    test('opções no modo teclado e teclado no modo opções são ignorados', () {
      final p = newProvider()..start();
      p.choose(p.problem!.answer);
      expect(p.score, 0);

      final q = newProvider()
        ..select(mode: AnswerMode.choices)
        ..start();
      q.typeDigit(1);
      q.submit();
      expect(q.typed, '');
      expect(q.phase, ContasPhase.playing);
    });

    test('select e start durante a rodada são ignorados', () {
      final p = newProvider()..start();
      final problem = p.problem;
      p.select(operation: Operation.division);
      p.start();
      expect(p.operation, Operation.addition);
      expect(p.problem, problem);
    });

    test('jogar de novo só no fim', () {
      final p = newProvider()..start();
      answerRight(p);
      p.playAgain();
      expect(p.score, 10);
    });
  });

  group('fim da rodada', () {
    test('jogar de novo zera tudo e mantém a escolha', () {
      final p = newProvider()
        ..select(operation: Operation.subtraction, level: 2)
        ..start();
      answerRight(p);
      answerWrong(p);
      p.stop();
      p.playAgain();
      expect(p.phase, ContasPhase.playing);
      expect(p.score, 0);
      expect(p.lives, 3);
      expect(p.streak, 0);
      expect(p.bestStreak, 0);
      expect(p.isNewRecord, isFalse);
      expect(p.operation, Operation.subtraction);
      expect(p.level, 2);
    });

    test('mudar nível volta para a escolha', () {
      final p = newProvider()..start();
      p.stop();
      p.exitToSetup();
      expect(p.phase, ContasPhase.setup);
      expect(p.problem, isNull);
    });
  });

  group('carregamento', () {
    test('a última escolha salva vira a seleção', () async {
      final p = newProvider(
        store: FakeRecordStore(
            last: const LastChoice(Operation.division, 2, AnswerMode.choices)),
      );
      var notified = 0;
      p.addListener(() => notified++);
      await pumpEventQueue();
      expect(p.operation, Operation.division);
      expect(p.level, 2);
      expect(p.answerMode, AnswerMode.choices);
      expect(notified, greaterThan(0));
    });

    test('se a criança já escolheu, a última escolha não sobrescreve', () async {
      final gate = Completer<void>();
      final p = newProvider(
        store: FakeRecordStore(
          gate: gate,
          last: const LastChoice(Operation.division, 2, AnswerMode.choices),
          records: {'subtraction_1': 50},
        ),
      );
      p.select(operation: Operation.subtraction);
      gate.complete();
      await pumpEventQueue();
      expect(p.operation, Operation.subtraction);
      expect(p.answerMode, AnswerMode.keyboard);
      expect(p.currentRecord, 50);
    });

    test('carregamento depois de começar não muda a rodada', () async {
      final gate = Completer<void>();
      final p = newProvider(
        store: FakeRecordStore(
          gate: gate,
          last: const LastChoice(Operation.division, 2, AnswerMode.choices),
        ),
      );
      p.start();
      gate.complete();
      await pumpEventQueue();
      expect(p.operation, Operation.addition);
      expect(p.phase, ContasPhase.playing);
    });

    test('recorde que chega depois não apaga um recorde maior da rodada',
        () async {
      final gate = Completer<void>();
      final p = newProvider(
        store: FakeRecordStore(gate: gate, records: {'addition_1': 10}),
      );
      p.start();
      for (var i = 0; i < 3; i++) {
        answerRight(p);
      }
      p.stop();
      gate.complete();
      await pumpEventQueue();
      expect(p.currentRecord, 30);
    });

    test('dispose antes de carregar não notifica', () async {
      final gate = Completer<void>();
      final p = newProvider(
        store: FakeRecordStore(
          gate: gate,
          records: {'addition_1': 10},
          last: const LastChoice(Operation.division, 2, AnswerMode.choices),
        ),
      );
      p.dispose();
      gate.complete();
      await pumpEventQueue();
    });

    test('leitura que falha deixa tudo zerado', () async {
      final p = newProvider(store: FakeRecordStore(failLoad: true));
      await pumpEventQueue();
      expect(p.currentRecord, 0);
      expect(p.operation, Operation.addition);
    });

    test('escrita que falha não quebra a rodada', () async {
      final p = newProvider(store: FakeRecordStore(failSave: true));
      await pumpEventQueue();
      p.start();
      answerRight(p);
      p.stop();
      await pumpEventQueue();
      expect(p.phase, ContasPhase.finished);
      expect(p.isNewRecord, isTrue);
      expect(p.currentRecord, 10);
    });
  });

  group('toque duplo', () {
    ContasProvider withDelay() => ContasProvider(
          store: FakeRecordStore(),
          random: Random(1),
          inputDelay: const Duration(milliseconds: 300),
        )
          ..select(mode: AnswerMode.choices)
          ..start();

    testWidgets('a opção tocada logo depois de acertar é ignorada',
        (tester) async {
      final p = withDelay();
      answerRight(p);
      expect(p.score, 10);
      final next = p.problem;
      p.choose(p.choices.firstWhere((c) => c != next!.answer));
      expect(p.lives, 3);
      expect(p.phase, ContasPhase.playing);
      await tester.pump(const Duration(milliseconds: 300));
      answerRight(p);
      expect(p.score, 20);
      p.dispose();
    });

    testWidgets('"Continuar" logo depois de errar é ignorado', (tester) async {
      final p = withDelay();
      answerWrong(p);
      p.continueAfterMistake();
      expect(p.phase, ContasPhase.mistake);
      await tester.pump(const Duration(milliseconds: 300));
      p.continueAfterMistake();
      expect(p.phase, ContasPhase.playing);
      // E a opção tocada logo depois do "Continuar" também.
      p.choose(p.problem!.answer);
      expect(p.score, 0);
      await tester.pump(const Duration(milliseconds: 300));
      p.dispose();
    });

    testWidgets('dispose com a pausa ativa não deixa timer', (tester) async {
      final p = withDelay();
      answerRight(p);
      p.dispose();
    });
  });

  group('recorde salvo antes de carregar', () {
    test('rodada menor não sobrescreve o recorde que ainda não chegou',
        () async {
      final gate = Completer<void>();
      final store = FakeRecordStore(gate: gate, records: {'addition_1': 500});
      final p = newProvider(store: store)..start();
      for (var i = 0; i < 3; i++) {
        answerRight(p);
      }
      p.stop();
      await pumpEventQueue();
      expect(store.saves, isEmpty);
      gate.complete();
      await pumpEventQueue();
      expect(store.records['addition_1'], 500);
      expect(p.currentRecord, 500);
    });

    test('rodada maior é salva quando o carregamento termina', () async {
      final gate = Completer<void>();
      final store = FakeRecordStore(gate: gate, records: {'addition_1': 10});
      final p = newProvider(store: store)..start();
      for (var i = 0; i < 3; i++) {
        answerRight(p);
      }
      p.stop();
      gate.complete();
      await pumpEventQueue();
      expect(store.saves, ['addition_1=30']);
      expect(p.currentRecord, 30);
    });

    test('se a leitura falhou, nada é salvo por cima', () async {
      final store = FakeRecordStore(failLoad: true, records: {'addition_1': 500});
      final p = newProvider(store: store);
      await pumpEventQueue();
      p.start();
      answerRight(p);
      p.stop();
      await pumpEventQueue();
      expect(store.saves, isEmpty);
    });
  });
}
