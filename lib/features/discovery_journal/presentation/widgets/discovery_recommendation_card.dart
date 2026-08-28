/// One suggestion — title, optional evidence, one CTA. Never a score.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../personal_discovery/copy/discovery_recommendation_copy.dart';
import '../../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../services/discovery_recommendation_opener.dart';

class DiscoveryRecommendationCard extends ConsumerWidget {
  const DiscoveryRecommendationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(discoveryRecommendationProvider);
    final reason = DiscoveryRecommendationCopy.reason(item);
    final cta = DiscoveryRecommendationCopy.cta(item.feature);
    return Semantics(
      button: true,
      label: '${DiscoveryRecommendationCopy.title}. $cta',
      child: OraclyGlassCard(
        premium: true,
        onTap: () => DiscoveryRecommendationOpener.open(
          context,
          item.feature,
          theme: item.theme,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s16,
          AppSpacing.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DiscoveryRecommendationCopy.title,
              style: ReadingTypography.sectionLabel(
                color: OraclyChrome.goldLight,
                fontSize: 12,
              ),
            ),
            if (reason != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                reason,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.78),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s12),
            Text(
              cta,
              style: ReadingTypography.bodyCore(
                color: OraclyChrome.goldLight.withValues(alpha: 0.94),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
