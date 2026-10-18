// test/games/xadrez/position_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/xadrez/logic/position.dart';
import 'package:brincaki/games/xadrez/models/game_state.dart';

const kKiwipete =
    'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1';
const kPosicao3 = '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1';
const kPosicao4 =
    'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1';

/// Acha o lance legal com a notação UCI dada.
ChessMove lance(ChessPosition p, String uci) =>
    p.legalMoves().firstWhere((m) => m.uci == uci);

/// Joga os lances UCI em sequência a partir de [p].
ChessPosition jogar(ChessPosition p, List<String> lances) {
  var atual = p;
  for (final l in lances) {
    atual = atual.play(lance(atual, l));
  }
  return atual;
}

void main() {
  group('casas', () {
    test('squareOf e nameOf seguem linha 0 = oitava fileira', () {
      expect(squareOf('a8'), 0);
      expect(squareOf('h1'), 63);
      expect(squareOf('e4'), 36);
      expect(nameOf(36), 'e4');
      for (var i = 0; i < 64; i++) {
        expect(squareOf(nameOf(i)), i);
      }
    });
  });

  group('lances', () {
    test('posição inicial tem 20 lances', () {
      final p = ChessPosition.initial();
      expect(p.turn, ChessSide.white);
      expect(p.castling, 15);
      expect(p.enPassant, isNull);
      expect(p.halfmoveClock, 0);
      expect(p.legalMoves(), hasLength(20));
      expect(p.inCheck, isFalse);
      expect(p.kingSquare(ChessSide.white), squareOf('e1'));
      expect(p.kingSquare(ChessSide.black), squareOf('e8'));
    });

    test('células são imutáveis por fora', () {
      final p = ChessPosition.initial();
      expect(() => p.cells[0] = 0, throwsUnsupportedError);
    });

    test('ChessMove compara origem, destino e promoção e gera uci', () {
      expect(const ChessMove(52, 36), const ChessMove(52, 36, captured: 1));
      expect(
        const ChessMove(52, 36).hashCode,
        const ChessMove(52, 36, isCastle: true).hashCode,
      );
      expect(
        const ChessMove(8, 0, promotion: kQueen) ==
            const ChessMove(8, 0, promotion: kRook),
        isFalse,
      );
      expect(const ChessMove(52, 36).uci, 'e2e4');
      expect(const ChessMove(12, 4, promotion: kQueen).uci, 'e7e8q');
      expect(const ChessMove(12, 4, promotion: kKnight).uci, 'e7e8n');
      expect(const ChessMove(52, 36).toString(), contains('e2e4'));
    });

    test('perft da posição inicial', () {
      final p = ChessPosition.initial();
      expect([for (var d = 1; d <= 3; d++) perft(p, d)], [20, 400, 8902]);
      expect(perft(p, 0), 1);
    });

    test('perft da Kiwipete', () {
      final p = ChessPosition.fromFen(kKiwipete);
      expect([for (var d = 1; d <= 2; d++) perft(p, d)], [48, 2039]);
    });

    test('perft da posição 3', () {
      final p = ChessPosition.fromFen(kPosicao3);
      expect([for (var d = 1; d <= 3; d++) perft(p, d)], [14, 191, 2812]);
    });

    test('perft da posição 4', () {
      final p = ChessPosition.fromFen(kPosicao4);
      expect([for (var d = 1; d <= 3; d++) perft(p, d)], [6, 264, 9467]);
    });

    test('roque não passa por casa atacada', () {
      // Bispo preto em c4 ataca f1: sem roque pequeno; o grande é livre.
      final p = ChessPosition.fromFen('r3k2r/8/8/8/2b5/8/8/R3K2R w KQkq - 0 1');
      final ucis = p.legalMoves().map((m) => m.uci).toSet();
      expect(ucis.contains('e1g1'), isFalse);
      expect(ucis.contains('e1c1'), isTrue);
      final roque = lance(p, 'e1c1');
      expect(roque.isCastle, isTrue);
      final depois = p.play(roque);
      expect(depois.cells[squareOf('c1')], kKing);
      expect(depois.cells[squareOf('d1')], kRook);
      expect(depois.cells[squareOf('a1')], 0);
      expect(depois.castling, 4 | 8);

      // Rei em xeque não roca.
      final xeque = ChessPosition.fromFen(
        'r3k2r/8/8/8/8/8/4r3/R3K2R w KQkq - 0 1',
      );
      expect(xeque.inCheck, isTrue);
      expect(xeque.legalMoves().where((m) => m.isCastle), isEmpty);

      // Destino atacado também impede (g1 atacado pelo cavalo em h3).
      final destino = ChessPosition.fromFen(
        'r3k2r/8/8/8/8/7n/8/R3K2R w KQkq - 0 1',
      );
      final u2 = destino.legalMoves().map((m) => m.uci).toSet();
      expect(u2.contains('e1g1'), isFalse);
      expect(u2.contains('e1c1'), isTrue);

      // Casa b1 atacada não impede o roque grande, mas ocupada impede.
      final b1 = ChessPosition.fromFen('r3k2r/8/8/8/8/8/8/RN2K2R w KQkq - 0 1');
      expect(b1.legalMoves().map((m) => m.uci).contains('e1c1'), isFalse);
    });

    test('roque das pretas move a torre', () {
      final p = ChessPosition.fromFen('r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1');
      final pequeno = p.play(lance(p, 'e8g8'));
      expect(pequeno.cells[squareOf('f8')], -kRook);
      expect(pequeno.cells[squareOf('g8')], -kKing);
      expect(pequeno.castling, 1 | 2);
      final grande = p.play(lance(p, 'e8c8'));
      expect(grande.cells[squareOf('d8')], -kRook);
      expect(grande.cells[squareOf('c8')], -kKing);
    });

    test('mexer ou perder a torre tira o direito de roque', () {
      final p = ChessPosition.fromFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      expect(p.play(lance(p, 'h1h2')).castling, 2 | 4 | 8);
      expect(p.play(lance(p, 'a1a2')).castling, 1 | 4 | 8);
      expect(p.play(lance(p, 'e1e2')).castling, 4 | 8);
      // Torre de a1 captura a torre de a8: as duas perdem o direito.
      expect(p.play(lance(p, 'a1a8')).castling, 1 | 4);
      expect(p.play(lance(p, 'h1h8')).castling, 2 | 8);
    });

    test('en passant só no lance seguinte', () {
      final p = ChessPosition.fromFen(
        'rnbqkbnr/ppp1pppp/8/4P3/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 2',
      );
      final depois = p.play(lance(p, 'f7f5'));
      expect(depois.enPassant, squareOf('f6'));
      final ep = lance(depois, 'e5f6');
      expect(ep.isEnPassant, isTrue);
      final capturou = depois.play(ep);
      expect(capturou.cells[squareOf('f5')], 0);
      expect(capturou.cells[squareOf('f6')], kPawn);
      expect(capturou.halfmoveClock, 0);

      // Se as brancas fazem outro lance, o en passant some.
      final outro = jogar(depois, ['a2a3', 'a7a6']);
      expect(outro.enPassant, isNull);
      expect(outro.legalMoves().map((m) => m.uci).contains('e5f6'), isFalse);
    });

    test('promoção gera as quatro peças', () {
      final p = ChessPosition.fromFen('8/4P3/8/8/8/8/k7/4K3 w - - 0 1');
      final promos = p.legalMoves().where((m) => m.from == squareOf('e7'));
      expect(promos.map((m) => m.promotion).toList(), [
        kQueen,
        kRook,
        kBishop,
        kKnight,
      ]);
      final depois = p.play(lance(p, 'e7e8n'));
      expect(depois.cells[squareOf('e8')], kKnight);

      // Pretas promovem capturando.
      final pretas = ChessPosition.fromFen('4k3/8/8/8/8/8/1p6/R3K3 b - - 0 1');
      final cap = lance(pretas, 'b2a1q');
      expect(cap.captured, kRook);
      expect(pretas.play(cap).cells[squareOf('a1')], -kQueen);
    });

    test('lance deixa a vez, o relógio e a contagem certos', () {
      final p = ChessPosition.initial();
      final a = p.play(lance(p, 'g1f3'));
      expect(a.turn, ChessSide.black);
      expect(a.halfmoveClock, 1);
      expect(a.toFen().endsWith(' 1 1'), isTrue);
      final b = a.play(lance(a, 'e7e5'));
      expect(b.halfmoveClock, 0);
      expect(b.enPassant, squareOf('e6'));
      expect(b.toFen().endsWith(' 0 2'), isTrue);
      // Posição original não muda.
      expect(p.cells[squareOf('g1')], kKnight);
    });

    test('peça cravada não sai da frente do rei', () {
      final p = ChessPosition.fromFen('4k3/4r3/8/8/8/8/4B3/4K3 w - - 0 1');
      expect(p.legalMoves().where((m) => m.from == squareOf('e2')), isEmpty);
      expect(p.isAttacked(squareOf('e2'), ChessSide.black), isTrue);
      expect(p.isAttacked(squareOf('d2'), ChessSide.black), isFalse);
    });
  });

  group('fen', () {
    test('fen ida e volta', () {
      for (final fen in [
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        kKiwipete,
        kPosicao3,
        kPosicao4,
        'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
        '8/8/8/8/8/8/8/K6k b - - 37 80',
      ]) {
        expect(ChessPosition.fromFen(fen).toFen(), fen);
      }
      expect(
        ChessPosition.initial().toFen(),
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
    });

    test('fen sem relógios usa 0 e 1', () {
      final p = ChessPosition.fromFen('4k3/8/8/8/8/8/8/4K3 w -');
      expect(p.toFen(), '4k3/8/8/8/8/8/8/4K3 w - - 0 1');
    });
  });

  group('material insuficiente', () {
    bool insuf(String placement) =>
        ChessPosition.fromFen('$placement w - - 0 1').insufficientMaterial;

    test('material insuficiente', () {
      expect(insuf('4k3/8/8/8/8/8/8/4K3'), isTrue); // R x R
      expect(insuf('4k3/8/8/8/8/8/8/2B1K3'), isTrue); // RB x R
      expect(insuf('4k3/8/8/8/8/8/8/1N2K3'), isTrue); // RC x R
      expect(insuf('4kb2/8/8/8/8/8/8/2B1K3'), isTrue); // c1 e f8: escuras
      expect(insuf('2b1k3/8/8/8/8/8/8/2B1K3'), isFalse); // c1 e c8
      expect(insuf('4k3/8/8/8/8/8/4P3/4K3'), isFalse); // RP x R
      expect(insuf('4k3/8/8/8/8/8/8/1NB1K3'), isFalse);
      expect(insuf('4k3/8/8/8/8/8/8/R3K3'), isFalse);
    });
  });

  group('repetição', () {
    test('repetitionKey ignora en passant impossível', () {
      // Depois de 1.e4 nenhum peão preto pode capturar em e3.
      final p = ChessPosition.initial();
      final e4 = p.play(lance(p, 'e2e4'));
      expect(e4.enPassant, squareOf('e3'));
      final semEp = ChessPosition.fromFen(
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
      );
      expect(e4.repetitionKey, semEp.repetitionKey);

      // Com en passant possível a chave muda.
      final com = ChessPosition.fromFen(
        'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
      );
      final sem = ChessPosition.fromFen(
        'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 3',
      );
      expect(com.repetitionKey == sem.repetitionKey, isFalse);

      // Vez e roque contam.
      expect(
        semEp.repetitionKey ==
            ChessPosition.fromFen(
              'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1',
            ).repetitionKey,
        isFalse,
      );
      expect(
        semEp.repetitionKey ==
            ChessPosition.fromFen(
              'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b Kkq - 0 1',
            ).repetitionKey,
        isFalse,
      );
    });

    test('en passant cravado não conta na chave', () {
      // O peão de e4 está cravado na coluna? Aqui: rei preto em a4, torre
      // branca em h4; capturar d3 deixaria a fileira aberta.
      final cravado = ChessPosition.fromFen(
        '8/8/8/8/k2Pp2R/8/8/4K3 b - d3 0 1',
      );
      expect(cravado.legalMoves().where((m) => m.isEnPassant), isEmpty);
      final sem = ChessPosition.fromFen('8/8/8/8/k2Pp2R/8/8/4K3 b - - 0 1');
      expect(cravado.repetitionKey, sem.repetitionKey);
    });
  });
}
