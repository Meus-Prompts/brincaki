import 'package:flutter/material.dart';

import '../models/sudoku_cell.dart';

class SudokuCellWidget extends StatelessWidget {
  final SudokuCell cell;
  final bool isSelected;
  final bool isHighlighted;
  final bool isSameNumber;
  final VoidCallback onTap;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.isSelected,
    required this.isHighlighted,
    required this.isSameNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.4);
    } else if (isSameNumber && !cell.isEmpty) {
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.2);
    } else if (isHighlighted) {
      backgroundColor = theme.colorScheme.surface.withValues(alpha: 0.3);
    } else {
      backgroundColor = Colors.transparent;
    }

    Color textColor;
    if (cell.isError) {
      textColor = theme.colorScheme.error;
    } else if (cell.isFixed) {
      textColor = Colors.grey.shade400;
    } else {
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Center(
          child: cell.isEmpty
              ? null
              : Text(
                  cell.value.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: cell.isFixed ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
