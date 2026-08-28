/// Quiet pause before the reading conclusion.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/reading_section_copy.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import 'reading_sacred_rhythm.dart';

class ReadingPremiumThreshold extends StatelessWidget {
  const ReadingPremiumThreshold({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: ReadingSacredRhythm.beforeReflection,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.transparent,
                    AppColors.gold.withValues(alpha: 0.18),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            ReadingSectionCopy.bridgeToClosing,
            textAlign: TextAlign.center,
            style: ReadingTypography.eyebrow(
              fontSize: 11,
              color: AppColors.textHint.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class ReadingPremiumClosingBreath extends StatelessWidget {
  const ReadingPremiumClosingBreath({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: ReadingSacredRhythm.afterReflection);
  }
}
