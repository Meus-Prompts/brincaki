// test/games/damas/board_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/damas/logic/board.dart';
import 'package:brincaki/games/damas/models/game_state.dart';

/// Índice da casa na linha [r] e coluna [c].
int sq(int r, int c) => r * 8 + c;

/// Monta uma posição só com as peças dadas (índice → valor).
DamasPosition pos(Map<int, int> pieces, DamasSide turn) {
  final cells = List.filled(64, 0);
  pieces.forEach((i, v) => cells[i] = v);
  return DamasPosition(cells, turn);
}

void main() {
  test('posição inicial tem 12 de cada lado e 7 lances para as brancas', () {
    final p = DamasPosition.initial();
    expect(p.turn, DamasSide.white);
    expect(p.cells.where((v) => v == 1), hasLength(12));
    expect(p.cells.where((v) => v == -1), hasLength(12));
    for (var i = 0; i < 64; i++) {
      final r = i ~/ 8, c = i % 8;
      if (p.cells[i] != 0) expect((r + c).isOdd, isTrue);
      if (p.cells[i] == -1) expect(r, lessThan(3));
      if (p.cells[i] == 1) expect(r, greaterThan(4));
    }
    final moves = legalMoves(p);
    expect(moves, hasLength(7));
    expect(moves.every((m) => !m.isCapture), isTrue);
  });

  test('pedra só anda para a frente', () {
    final white = legalMoves(pos({sq(4, 3): 1}, DamasSide.white));
    expect(white.map((m) => m.to).toSet(), {sq(3, 2), sq(3, 4)});
    final black = legalMoves(pos({sq(3, 4): -1}, DamasSide.black));
    expect(black.map((m) => m.to).toSet(), {sq(4, 3), sq(4, 5)});
  });

  test('pedra captura para trás', () {
    final moves = legalMoves(pos({sq(4, 3): 1, sq(5, 4): -1}, DamasSide.white));
    expect(moves, [DamasMove([sq(4, 3), sq(6, 5)], [sq(5, 4)])]);
    expect(moves.single.captured, [sq(5, 4)]);
  });

  test('captura é obrigatória', () {
    final moves = legalMoves(pos({sq(5, 2): 1, sq(4, 3): -1}, DamasSide.white));
    expect(moves, hasLength(1));
    expect(moves.single.isCapture, isTrue);
    expect(moves.single.to, sq(3, 4));
  });

  test('captura em sequência é um lance só', () {
    final moves = legalMoves(
        pos({sq(6, 1): 1, sq(5, 2): -1, sq(3, 4): -1}, DamasSide.white));
    expect(moves, hasLength(1));
    expect(moves.single.path, [sq(6, 1), sq(4, 3), sq(2, 5)]);
    expect(moves.single.captured, [sq(5, 2), sq(3, 4)]);
    expect(moves.single.from, sq(6, 1));
    expect(moves.single.to, sq(2, 5));
  });

  test('lei da maioria escolhe a sequência que come mais', () {
    final moves = legalMoves(pos(
        {sq(6, 3): 1, sq(5, 2): -1, sq(5, 4): -1, sq(3, 6): -1},
        DamasSide.white));
    expect(moves, hasLength(1));
    expect(moves.single.path, [sq(6, 3), sq(4, 5), sq(2, 7)]);
  });

  test('empate no número de capturas deixa escolher', () {
    final moves = legalMoves(
        pos({sq(6, 3): 1, sq(5, 2): -1, sq(5, 4): -1}, DamasSide.white));
    expect(moves.map((m) => m.to).toSet(), {sq(4, 1), sq(4, 5)});
    expect(moves.every((m) => m.captured.length == 1), isTrue);
  });

  test('dama anda várias casas', () {
    final moves = legalMoves(pos({sq(7, 0): 2}, DamasSide.white));
    expect(moves.map((m) => m.to).toSet(),
        {for (var k = 1; k < 8; k++) sq(7 - k, k)});
    final back = legalMoves(pos({sq(0, 7): -2}, DamasSide.black));
    expect(back, hasLength(7));
  });

  test('dama captura a distância e pousa em qualquer casa depois', () {
    final moves = legalMoves(pos({sq(7, 0): 2, sq(4, 3): -1}, DamasSide.white));
    expect(moves.map((m) => m.to).toSet(),
        {sq(3, 4), sq(2, 5), sq(1, 6), sq(0, 7)});
    expect(moves.every((m) => m.captured.single == sq(4, 3)), isTrue);
  });

  test('dama não pula duas peças seguidas nem as próprias', () {
    expect(
        legalMoves(pos({sq(7, 0): 2, sq(4, 3): -1, sq(3, 4): -1},
                DamasSide.white))
            .any((m) => m.isCapture),
        isFalse);
    expect(
        legalMoves(pos({sq(7, 0): 2, sq(6, 1): 1, sq(4, 3): -1},
                DamasSide.white))
            .any((m) => m.isCapture),
        isFalse);
  });

  test('lei da maioria vale para onde a dama pousa', () {
    final moves = legalMoves(pos(
        {sq(7, 0): 2, sq(4, 3): -1, sq(3, 6): -1}, DamasSide.white));
    expect(moves, hasLength(1));
    expect(moves.single.path, [sq(7, 0), sq(2, 5), sq(4, 7)]);
    expect(moves.single.captured, [sq(4, 3), sq(3, 6)]);
  });

  test('não pula a mesma peça duas vezes', () {
    // Quatro pretas em volta de (4,3): a pedra dá a volta e para na origem.
    final moves = legalMoves(pos({
      sq(6, 3): 1,
      sq(5, 2): -1,
      sq(3, 2): -1,
      sq(3, 4): -1,
      sq(5, 4): -1,
    }, DamasSide.white));
    expect(moves, hasLength(2));
    for (final m in moves) {
      expect(m.captured, hasLength(4));
      expect(m.captured.toSet(), hasLength(4));
      expect(m.to, sq(6, 3));
    }
  });

  test('peça capturada continua bloqueando até o fim do lance', () {
    // Se a peça em (5,4) saísse na hora, a dama voltaria por ela e comeria (2,1).
    final moves = legalMoves(pos(
        {sq(3, 2): 2, sq(5, 4): -1, sq(2, 1): -1}, DamasSide.white));
    expect(moves, isNotEmpty);
    expect(moves.every((m) => m.captured.length == 1), isTrue);
  });

  test('pedra que passa pela última fileira capturando não vira dama', () {
    final p = pos({sq(2, 1): 1, sq(1, 2): -1, sq(1, 4): -1}, DamasSide.white);
    final moves = legalMoves(p);
    expect(moves, hasLength(1));
    expect(moves.single.path, [sq(2, 1), sq(0, 3), sq(2, 5)]);
    final next = applyMove(p, moves.single);
    expect(next.cells[sq(2, 5)], 1);
  });

  test('pedra que termina na última fileira vira dama', () {
    final white = pos({sq(1, 2): 1}, DamasSide.white);
    final w = applyMove(white, DamasMove([sq(1, 2), sq(0, 1)], const []));
    expect(w.cells[sq(0, 1)], 2);
    final black = pos({sq(5, 2): -1, sq(6, 3): 1}, DamasSide.black);
    final capture = legalMoves(black).single;
    expect(capture.to, sq(7, 4));
    expect(applyMove(black, capture).cells[sq(7, 4)], -2);
  });

  test('applyMove troca a vez e tira as capturadas', () {
    final p = pos({sq(6, 1): 1, sq(5, 2): -1, sq(3, 4): -1}, DamasSide.white);
    final next = applyMove(p, legalMoves(p).single);
    expect(next.turn, DamasSide.black);
    expect(next.cells[sq(6, 1)], 0);
    expect(next.cells[sq(5, 2)], 0);
    expect(next.cells[sq(3, 4)], 0);
    expect(next.cells[sq(2, 5)], 1);
    expect(p.cells[sq(6, 1)], 1, reason: 'não mexe na posição original');
    expect(next.key, isNot(p.key));
  });

  test('key muda com a vez e lance compara pelo caminho', () {
    final a = pos({sq(4, 3): 1}, DamasSide.white);
    final b = pos({sq(4, 3): 1}, DamasSide.black);
    expect(a.key, isNot(b.key));
    expect(a.key, pos({sq(4, 3): 1}, DamasSide.white).key);
    const m1 = DamasMove([1, 2], []);
    const m2 = DamasMove([1, 2], [5]);
    expect(m1, m2);
    expect(m1.hashCode, m2.hashCode);
    expect(m1 == const DamasMove([1, 3], []), isFalse);
  });

  test('ajudantes de peça e lado', () {
    expect(isMan(1) && isMan(-1), isTrue);
    expect(isMan(2) || isMan(0), isFalse);
    expect(isKing(2) && isKing(-2), isTrue);
    expect(isKing(1) || isKing(0), isFalse);
    expect(sideOf(1), DamasSide.white);
    expect(sideOf(-2), DamasSide.black);
    expect(sideOf(0), isNull);
    expect(DamasSide.white.opponent, DamasSide.black);
    expect(DamasSide.black.opponent, DamasSide.white);
  });
}
