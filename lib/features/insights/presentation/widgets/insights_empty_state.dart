/// Insights empty — calm atmosphere until real patterns appear.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_empty_atmosphere.dart';
import '../../copy/personal_insights_copy.dart';

class InsightsEmptyState extends StatelessWidget {
  const InsightsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OraclyEmptyAtmosphere(
            assetPath: AppAssets.homeHeroMoon,
            size: 108,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            PersonalInsightsCopy.emptyTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.title(
              color: OraclyChrome.goldLight.withValues(alpha: 0.92),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            PersonalInsightsCopy.emptyBody,
            textAlign: TextAlign.center,
            style: ReadingTypography.body(
              color: OraclyChrome.cream.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}
