/// Quiet gold hairline between reading acts — hierarchy, not decoration.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'reading_sacred_rhythm.dart';

class ReadingResultSeparator extends StatelessWidget {
  const ReadingResultSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ReadingSacredRhythm.betweenActs * 0.35,
      ),
      child: Center(
        child: Container(
          width: 40,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.transparent,
                AppColors.gold.withValues(alpha: 0.20),
                AppColors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Breath before a new reading act.
class ReadingResultActGap extends StatelessWidget {
  const ReadingResultActGap({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: ReadingSacredRhythm.betweenActs);
  }
}
