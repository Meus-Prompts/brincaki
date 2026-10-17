// lib/games/sudoku/models/difficulty.dart

enum Difficulty {
  easy(name: 'Fácil', minEmpty: 30, maxEmpty: 35),
  medium(name: 'Médio', minEmpty: 36, maxEmpty: 45),
  hard(name: 'Difícil', minEmpty: 46, maxEmpty: 52),
  expert(name: 'Expert', minEmpty: 53, maxEmpty: 58),
  master(name: 'Master', minEmpty: 59, maxEmpty: 64);

  const Difficulty({required this.name, required this.minEmpty, required this.maxEmpty});

  final String name;
  final int minEmpty;
  final int maxEmpty;
}
