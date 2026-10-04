// lib/games/memoria/data/levels.dart

class MemoryGrid {
  const MemoryGrid(this.rows, this.cols);

  final int rows;
  final int cols;

  int get pairs => rows * cols ~/ 2;
}

/// Níveis do modo solo, em pé (o app só roda na vertical).
const List<MemoryGrid> kSoloLevels = [
  MemoryGrid(4, 3),
  MemoryGrid(4, 4),
  MemoryGrid(5, 4),
  MemoryGrid(6, 5),
  MemoryGrid(6, 6),
];

const Map<String, MemoryGrid> kDuoSizes = {
  'Pequena': MemoryGrid(4, 3),
  'Média': MemoryGrid(5, 4),
  'Grande': MemoryGrid(6, 6),
};
