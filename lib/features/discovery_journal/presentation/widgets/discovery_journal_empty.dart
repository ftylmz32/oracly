/// Truthful empty archive — atmospheric plate + one next step.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_empty_atmosphere.dart';
import '../../copy/discovery_journal_copy.dart';
import '../widgets/discovery_recommendation_card.dart';

class DiscoveryJournalEmpty extends StatelessWidget {
  const DiscoveryJournalEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s32,
          AppSpacing.s12,
          AppSpacing.s32,
          AppSpacing.s32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OraclyEmptyAtmosphere(
              assetPath: AppAssets.profileJournalHero,
              size: 108,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              DiscoveryJournalCopy.emptyTitle,
              textAlign: TextAlign.center,
              style: ReadingTypography.title(
                color: OraclyChrome.goldLight.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              DiscoveryJournalCopy.emptyMessage,
              textAlign: TextAlign.center,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.74),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            const DiscoveryRecommendationCard(),
          ],
        ),
      ),
    );
  }
}
