import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(9, (index) {
        final number = index + 1;
        final remaining = provider.getRemainingCount(number);
        final isComplete = remaining == 0;
        final isSelected = provider.numberFirstMode && provider.selectedNumber == number;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              height: 56,
              child: isComplete
                  ? const SizedBox.shrink()
                  : ElevatedButton(
                      onPressed: provider.isComplete ? null : () => provider.selectNumber(number),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        foregroundColor: isSelected ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isSelected
                              ? BorderSide(color: theme.colorScheme.primary, width: 2)
                              : BorderSide.none,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            number.toString(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            remaining.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.black54
                                  : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }
}
