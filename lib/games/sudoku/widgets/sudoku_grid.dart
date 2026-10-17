// lib/games/sudoku/widgets/sudoku_grid.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/game_palette.dart';
import '../providers/game_provider.dart';
import 'sudoku_cell_widget.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SudokuProvider>(
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

        final thick = kSudokuPalette.dark;
        final thin = kSudokuPalette.accent.withValues(alpha: 0.3);

        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: thick, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: List.generate(9, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(9, (col) {
                      final cell = board.getCell(row, col);
                      final isSelected = row == provider.selectedRow && col == provider.selectedCol;
                      final isHighlighted =
                          row == provider.selectedRow ||
                          col == provider.selectedCol ||
                          _sameBox(row, col, provider.selectedRow, provider.selectedCol);
                      final isSameNumber = selectedValue != 0 && cell.value == selectedValue;
                      final boxRight = (col + 1) % 3 == 0 && col != 8;
                      final boxBottom = (row + 1) % 3 == 0 && row != 8;

                      return Expanded(
                        child: Container(
                          key: Key('cell-$row-$col'),
                          decoration: BoxDecoration(
                            border: Border(
                              right: col == 8
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: boxRight ? thick : thin,
                                      width: boxRight ? 2 : 1,
                                    ),
                              bottom: row == 8
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: boxBottom ? thick : thin,
                                      width: boxBottom ? 2 : 1,
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
