import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import 'sudoku_cell_widget.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        final board = provider.board;
        if (board == null) return const SizedBox.shrink();

        int selectedValue;
        if (provider.numberFirstMode && provider.selectedNumber != null) {
          selectedValue = provider.selectedNumber!;
        } else if (provider.hasSelection) {
          selectedValue = board.getCell(provider.selectedRow!, provider.selectedCol!).value;
        } else {
          selectedValue = 0;
        }

        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: List.generate(9, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(9, (col) {
                      final cell = board.getCell(row, col);
                      final isSelected =
                          row == provider.selectedRow && col == provider.selectedCol;
                      final isHighlighted = row == provider.selectedRow ||
                          col == provider.selectedCol ||
                          _sameBox(row, col, provider.selectedRow, provider.selectedCol);
                      final isSameNumber = selectedValue != 0 && cell.value == selectedValue;

                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: (col + 1) % 3 == 0 && col != 8
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                width: (col + 1) % 3 == 0 && col != 8 ? 2 : 1,
                              ),
                              bottom: BorderSide(
                                color: (row + 1) % 3 == 0 && row != 8
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                width: (row + 1) % 3 == 0 && row != 8 ? 2 : 1,
                              ),
                            ),
                          ),
                          child: SudokuCellWidget(
                            cell: cell,
                            isSelected: isSelected,
                            isHighlighted: isHighlighted,
                            isSameNumber: isSameNumber,
                            onTap: () => provider.selectCell(row, col),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  bool _sameBox(int row1, int col1, int? row2, int? col2) {
    if (row2 == null || col2 == null) return false;
    return (row1 ~/ 3 == row2 ~/ 3) && (col1 ~/ 3 == col2 ~/ 3);
  }
}
