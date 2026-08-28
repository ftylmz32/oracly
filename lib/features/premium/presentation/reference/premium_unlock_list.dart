/// Concise unlock lines — never prices, scarcity, or timers.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';

class PremiumUnlockList extends StatelessWidget {
  const PremiumUnlockList({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          PremiumCopy.unlockTitle,
          textAlign: TextAlign.center,
          style: ReadingTypography.sectionLabel(
            color: OraclyChrome.goldLight.withValues(alpha: 0.88),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.s12),
        for (final line in PremiumCopy.unlocks) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '·  ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.82),
                  ),
                ),
                Expanded(
                  child: Text(
                    line,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: OraclyChrome.cream.withValues(alpha: 0.88),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
