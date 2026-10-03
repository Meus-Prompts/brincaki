import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/difficulty.dart';
import '../models/sudoku_board.dart';
import '../services/sudoku_generator.dart';

class GameProvider extends ChangeNotifier {
  final _generator = SudokuGenerator();

  SudokuBoard? _board;
  Difficulty _difficulty = Difficulty.easy;
  int? _selectedRow;
  int? _selectedCol;
  int _hintsRemaining = 3;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isComplete = false;
  bool _numberFirstMode = false;
  int? _selectedNumber;

  SudokuBoard? get board => _board;
  Difficulty get difficulty => _difficulty;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  int get hintsRemaining => _hintsRemaining;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isComplete => _isComplete;
  bool get hasSelection => _selectedRow != null && _selectedCol != null;
  bool get numberFirstMode => _numberFirstMode;
  int? get selectedNumber => _selectedNumber;

  String get formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int getRemainingCount(int number) {
    if (_board == null) return 9;
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_board!.getCell(r, c).value == number) count++;
      }
    }
    return 9 - count;
  }

  bool isNumberComplete(int number) => getRemainingCount(number) == 0;

  void startGame(Difficulty difficulty) {
    _difficulty = difficulty;
    _board = _generator.generate(difficulty);
    _selectedRow = null;
    _selectedCol = null;
    _selectedNumber = null;
    _hintsRemaining = 3;
    _elapsedSeconds = 0;
    _isComplete = false;
    _startTimer();
    notifyListeners();
  }

  void toggleInputMode() {
    _numberFirstMode = !_numberFirstMode;
    _selectedNumber = null;
    _selectedRow = null;
    _selectedCol = null;
    notifyListeners();
  }

  void selectNumber(int number) {
    if (_isComplete) return;

    if (_numberFirstMode) {
      _selectedNumber = _selectedNumber == number ? null : number;
      notifyListeners();
    } else {
      enterNumber(number);
    }
  }

  void _selectNextAvailableNumber() {
    if (!_numberFirstMode) return;

    // Encontrar o próximo número disponível
    for (int i = 1; i <= 9; i++) {
      if (!isNumberComplete(i)) {
        _selectedNumber = i;
        return;
      }
    }
    // Se todos os números estão completos, desselecionar
    _selectedNumber = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void selectCell(int row, int col) {
    if (_isComplete) return;

    if (_numberFirstMode && _selectedNumber != null) {
      final cell = _board!.getCell(row, col);
      if (!cell.isFixed) {
        _board = _board!.setCell(row, col, _selectedNumber!);

        if (_board!.isComplete) {
          _isComplete = true;
          _timer?.cancel();
        } else if (isNumberComplete(_selectedNumber!)) {
          // Se o número atual foi completado, selecionar o próximo disponível
          _selectNextAvailableNumber();
        }
      }
    }

    _selectedRow = row;
    _selectedCol = col;
    notifyListeners();
  }

  void enterNumber(int number) {
    if (_board == null || !hasSelection || _isComplete) return;

    final cell = _board!.getCell(_selectedRow!, _selectedCol!);
    if (cell.isFixed) return;

    _board = _board!.setCell(_selectedRow!, _selectedCol!, number);

    if (_board!.isComplete) {
      _isComplete = true;
      _timer?.cancel();
    }

    // Desselecionar célula após inserir número no modo célula
    _selectedRow = null;
    _selectedCol = null;

    notifyListeners();
  }

  void clearCell() {
    if (_board == null || !hasSelection || _isComplete) return;

    final cell = _board!.getCell(_selectedRow!, _selectedCol!);
    if (cell.isFixed) return;

    _board = _board!.setCell(_selectedRow!, _selectedCol!, 0);
    _board = _board!.revalidateAll();
    notifyListeners();
  }

  void useHint() {
    if (_board == null || !hasSelection || _hintsRemaining <= 0 || _isComplete) return;

    final cell = _board!.getCell(_selectedRow!, _selectedCol!);
    if (cell.isFixed || !cell.isEmpty) return;

    final hint = _board!.getHint(_selectedRow!, _selectedCol!);
    _board = _board!.setCell(_selectedRow!, _selectedCol!, hint);
    _hintsRemaining--;

    if (_board!.isComplete) {
      _isComplete = true;
      _timer?.cancel();
    }

    notifyListeners();
  }

  void newGame() {
    startGame(_difficulty);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
