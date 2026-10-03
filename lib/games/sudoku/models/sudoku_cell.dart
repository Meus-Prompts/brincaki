class SudokuCell {
  final int value;
  final bool isFixed;
  final bool isError;

  const SudokuCell({
    this.value = 0,
    this.isFixed = false,
    this.isError = false,
  });

  bool get isEmpty => value == 0;

  SudokuCell copyWith({
    int? value,
    bool? isFixed,
    bool? isError,
  }) {
    return SudokuCell(
      value: value ?? this.value,
      isFixed: isFixed ?? this.isFixed,
      isError: isError ?? this.isError,
    );
  }
}
