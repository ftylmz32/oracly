/// Explore (Keşfet) hub — browse live modules; not a second Home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/reading_ux/reading_long_form_scroll.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/home/copy/home_discovery_copy.dart';
import '../../../features/home/reference/home_module_visual.dart';
import '../../../features/premium/providers/premium_providers.dart';
import '../copy/explore_copy.dart';
import 'explore_module_card.dart';

class ExploreReferenceScreen extends ConsumerWidget {
  const ExploreReferenceScreen({super.key});

  static const _modules = <(OraclyFeatureId, HomeModuleVisual, bool)>[
    (OraclyFeatureId.coffee, HomeModuleVisual.coffee, false),
    (OraclyFeatureId.palm, HomeModuleVisual.palm, false),
    (OraclyFeatureId.dream, HomeModuleVisual.dream, false),
    (OraclyFeatureId.astrology, HomeModuleVisual.astrology, false),
    (OraclyFeatureId.starMap, HomeModuleVisual.starMap, false),
    (OraclyFeatureId.soulMate, HomeModuleVisual.soulMate, true),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumStatusProvider).isPremium;
    return ReadingLongFormScroll(
      kicker: ExploreCopy.screenTitle,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppLayout.scrollBottomInset(context),
      ),
      children: [
        Text(
          ExploreCopy.screenTitle,
          style: ReadingTypography.title(
            color: OraclyChrome.cream.withValues(alpha: 0.96),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          ExploreCopy.subtitle,
          style: ReadingTypography.body(
            color: OraclyChrome.cream.withValues(alpha: 0.72),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        ExploreModuleCard(
          title: HomeDiscoveryCopy.title(OraclyFeatureId.coffee),
          subtitle: ExploreCopy.featuredSubtitle,
          visual: HomeModuleVisual.coffee,
          featured: true,
          premiumLocked: false,
          onTap: () => OraclyFeatureNavigation.open(
            context,
            OraclyFeatureId.coffee,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          ExploreCopy.modulesLabel,
          style: ReadingTypography.sectionLabel(
            color: OraclyChrome.goldLight.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        for (final row in _modules)
          if (row.$1 != OraclyFeatureId.coffee) ...[
            ExploreModuleCard(
              title: HomeDiscoveryCopy.title(row.$1),
              subtitle: ExploreCopy.moduleHint(row.$1),
              visual: row.$2,
              featured: false,
              premiumLocked: row.$3 && !premium,
              onTap: () => OraclyFeatureNavigation.open(context, row.$1),
            ),
            SizedBox(height: AppSpacing.sm),
          ],
        SizedBox(height: AppSpacing.lg),
        Text(
          ExploreCopy.orHint,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(
            color: OraclyChrome.cream.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
