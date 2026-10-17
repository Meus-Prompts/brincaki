// lib/games/sudoku/providers/game_provider.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/difficulty.dart';
import '../models/game_state.dart';
import '../models/sudoku_board.dart';
import '../services/sudoku_generator.dart';

/// Dicas por partida.
const kSudokuHints = 3;

class SudokuProvider extends ChangeNotifier {
  SudokuProvider({Random? random}) : _generator = SudokuGenerator(random: random);

  final SudokuGenerator _generator;

  SudokuPhase _phase = SudokuPhase.setup;
  SudokuBoard? _board;
  Difficulty _difficulty = Difficulty.easy;
  int? _selectedRow;
  int? _selectedCol;
  int _hintsRemaining = kSudokuHints;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _numberFirstMode = false;
  int? _selectedNumber;

  SudokuPhase get phase => _phase;
  SudokuBoard? get board => _board;
  Difficulty get difficulty => _difficulty;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  int get hintsRemaining => _hintsRemaining;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isComplete => _phase == SudokuPhase.solved;
  bool get isPlaying => _phase == SudokuPhase.playing;
  bool get hasSelection => _selectedRow != null && _selectedCol != null;
  bool get numberFirstMode => _numberFirstMode;
  int? get selectedNumber => _selectedNumber;

  /// O cronômetro está contando.
  bool get timerRunning => _timer?.isActive ?? false;

  String get formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Quantas vezes [number] ainda falta aparecer no tabuleiro.
  int getRemainingCount(int number) {
    final board = _board;
    if (board == null) return 9;
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board.getCell(r, c).value == number) count++;
      }
    }
    return 9 - count;
  }

  bool isNumberComplete(int number) => getRemainingCount(number) == 0;

  /// Começa uma partida na [difficulty] escolhida na tela de início.
  void start(Difficulty difficulty) {
    if (_phase != SudokuPhase.setup) return;
    _newBoard(difficulty);
  }

  /// Nova partida na mesma dificuldade ("Jogar de novo" / "Novo jogo").
  void newGame() {
    if (_phase == SudokuPhase.setup) return;
    _newBoard(_difficulty);
  }

  /// Volta à escolha de dificuldade.
  void exitToSetup() {
    if (_phase == SudokuPhase.setup) return;
    _timer?.cancel();
    _phase = SudokuPhase.setup;
    _board = null;
    _clearSelection();
    notifyListeners();
  }

  void _newBoard(Difficulty difficulty) {
    _difficulty = difficulty;
    _board = _generator.generate(difficulty);
    _phase = SudokuPhase.playing;
    _clearSelection();
    _hintsRemaining = kSudokuHints;
    _elapsedSeconds = 0;
    _startTimer();
    notifyListeners();
  }

  void _clearSelection() {
    _selectedRow = null;
    _selectedCol = null;
    _selectedNumber = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  /// Alterna entre escolher a casa primeiro e escolher o número primeiro.
  void toggleInputMode() {
    if (_phase != SudokuPhase.playing) return;
    _numberFirstMode = !_numberFirstMode;
    _clearSelection();
    notifyListeners();
  }

  /// Toque no teclado: no modo número-primeiro escolhe (ou solta) o número;
  /// no modo célula-primeiro escreve na casa selecionada.
  void selectNumber(int number) {
    if (_phase != SudokuPhase.playing) return;

    if (_numberFirstMode) {
      _selectedNumber = _selectedNumber == number ? null : number;
      notifyListeners();
    } else {
      enterNumber(number);
    }
  }

  /// Toque numa casa: seleciona e, no modo número-primeiro com um número
  /// escolhido, já escreve nela.
  void selectCell(int row, int col) {
    if (_phase != SudokuPhase.playing) return;

    final number = _selectedNumber;
    if (_numberFirstMode && number != null && !_board!.getCell(row, col).isFixed) {
      _board = _board!.setCell(row, col, number);
      if (!_checkSolved() && isNumberComplete(number)) {
        _selectNextAvailableNumber();
      }
    }

    _selectedRow = row;
    _selectedCol = col;
    notifyListeners();
  }

  void _selectNextAvailableNumber() {
    _selectedNumber = null;
    for (int i = 1; i <= 9; i++) {
      if (!isNumberComplete(i)) {
        _selectedNumber = i;
        return;
      }
    }
  }

  /// Escreve [number] na casa selecionada (modo célula-primeiro).
  void enterNumber(int number) {
    if (_phase != SudokuPhase.playing || !hasSelection) return;
    if (_board!.getCell(_selectedRow!, _selectedCol!).isFixed) return;

    _board = _board!.setCell(_selectedRow!, _selectedCol!, number);
    _checkSolved();

    // Depois de escrever, a casa é solta.
    _selectedRow = null;
    _selectedCol = null;
    notifyListeners();
  }

  /// Apaga a casa selecionada.
  void clearCell() {
    if (_phase != SudokuPhase.playing || !hasSelection) return;
    if (_board!.getCell(_selectedRow!, _selectedCol!).isFixed) return;

    _board = _board!.setCell(_selectedRow!, _selectedCol!, 0);
    notifyListeners();
  }

  /// Preenche a casa selecionada (vazia) com o número certo.
  void useHint() {
    if (_phase != SudokuPhase.playing || !hasSelection || _hintsRemaining <= 0) return;

    final cell = _board!.getCell(_selectedRow!, _selectedCol!);
    if (cell.isFixed || !cell.isEmpty) return;

    final hint = _board!.getHint(_selectedRow!, _selectedCol!);
    _board = _board!.setCell(_selectedRow!, _selectedCol!, hint);
    _hintsRemaining--;
    _checkSolved();
    notifyListeners();
  }

  /// Passa para "resolvido" e para o cronômetro quando o tabuleiro fecha.
  bool _checkSolved() {
    if (!_board!.isComplete) return false;
    _phase = SudokuPhase.solved;
    _timer?.cancel();
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
