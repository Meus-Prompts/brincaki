// test/games/sudoku/sudoku_solver_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/sudoku/services/sudoku_solver.dart';

import 'fixtures.dart';

void main() {
  final solver = SudokuSolver();

  group('solve', () {
    test('resolve o problema clássico e chega na solução conhecida', () {
      final grid = copyGrid(kPuzzle);
      expect(solver.solve(grid), isTrue);
      expect(grid, kSolved);
    });

    test('tabuleiro já completo é resolvido sem mudar nada', () {
      final grid = copyGrid(kSolved);
      expect(solver.solve(grid), isTrue);
      expect(grid, kSolved);
    });

    test('tabuleiro vazio vira uma solução válida', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      expect(solver.solve(grid), isTrue);
      expect(isValidSolution(grid), isTrue);
    });

    test('casa sem nenhum número possível: devolve false e não mexe no tabuleiro', () {
      // A casa (0, 0) vê 1..8 na linha e o 9 na coluna.
      final grid = List.generate(9, (_) => List.filled(9, 0));
      for (var c = 1; c < 9; c++) {
        grid[0][c] = c;
      }
      grid[1][0] = 9;
      final before = copyGrid(grid);

      expect(solver.solve(grid), isFalse);
      expect(grid, before);
    });

    test('número repetido já escrito na linha deixa o tabuleiro sem solução', () {
      // Linha 0 com dois 5: à casa (0, 0) só restaria o 3, que já está na coluna.
      final grid = copyGrid(kSolved);
      grid[0][0] = 0;
      grid[0][1] = 5;
      expect(solver.solve(grid), isFalse);
    });
  });

  group('countSolutions / hasUniqueSolution', () {
    test('o problema clássico tem uma solução só', () {
      expect(solver.countSolutions(kPuzzle), 1);
      expect(solver.hasUniqueSolution(kPuzzle), isTrue);
    });

    test('não altera o tabuleiro recebido', () {
      final grid = copyGrid(kPuzzle);
      solver.countSolutions(grid);
      expect(grid, kPuzzle);
    });

    test('retângulo trocável dá duas soluções', () {
      // Dois pares a/b em cantos opostos de um retângulo que cruza dois
      // blocos: apagados, dá para trocar a com b.
      final grid = copyGrid(kSolved);
      late int r1, r2, c1, c2;
      search:
      for (r1 = 0; r1 < 9; r1++) {
        for (r2 = r1 + 1; r2 < 9; r2++) {
          for (c1 = 0; c1 < 9; c1++) {
            for (c2 = c1 + 1; c2 < 9; c2++) {
              final sameRowBox = r1 ~/ 3 == r2 ~/ 3;
              final sameColBox = c1 ~/ 3 == c2 ~/ 3;
              if (sameRowBox == sameColBox) continue; // precisa de 2 blocos
              if (grid[r1][c1] == grid[r2][c2] && grid[r1][c2] == grid[r2][c1]) {
                break search;
              }
            }
          }
        }
      }
      grid[r1][c1] = grid[r1][c2] = grid[r2][c1] = grid[r2][c2] = 0;

      expect(solver.countSolutions(grid), 2);
      expect(solver.hasUniqueSolution(grid), isFalse);
    });

    test('para de contar ao chegar no limite', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      expect(solver.countSolutions(grid, limit: 3), 3);
    });

    test('tabuleiro sem solução tem zero soluções', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      for (var c = 1; c < 9; c++) {
        grid[0][c] = c;
      }
      grid[1][0] = 9;
      expect(solver.countSolutions(grid), 0);
      expect(solver.hasUniqueSolution(grid), isFalse);
    });
  });
}
