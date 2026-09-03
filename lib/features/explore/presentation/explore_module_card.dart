/// Compact Explore module card with chamber art thumb.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/preview_capability_copy.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_registry.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/home/reference/home_discovery_module_arts.dart';
import '../../../features/home/reference/home_module_visual.dart';
import '../../../shared/widgets/oracly_pressable.dart';

class ExploreModuleCard extends StatelessWidget {
  const ExploreModuleCard({
    super.key,
    required this.featureId,
    required this.title,
    required this.subtitle,
    required this.visual,
    required this.onTap,
    this.featured = false,
    this.premiumLocked = false,
  });

  final OraclyFeatureId featureId;
  final String title;
  final String subtitle;
  final HomeModuleVisual visual;
  final VoidCallback onTap;
  final bool featured;
  final bool premiumLocked;

  @override
  Widget build(BuildContext context) {
    final thumb = featured ? 72.0 : 56.0;
    final showPreview =
        OraclyFeatureRegistry.byId(featureId)?.isPreview ?? false;
    return OraclyPressable(
      onTap: onTap,
      borderRadius: AppRadius.s16,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: featured ? 88 : 72),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.s16,
            color: OraclyChrome.cardSurface.withValues(
              alpha: featured ? 0.18 : 0.10,
            ),
            border: Border.all(
              color: OraclyChrome.gold.withValues(
                alpha: featured ? 0.32 : 0.16,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(featured ? 14 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: thumb,
                    height: thumb,
                    child: HomeDiscoveryModuleArt(visual: visual),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ReadingTypography.title(
                          color: OraclyChrome.cream.withValues(alpha: 0.95),
                        ).copyWith(fontSize: featured ? 18 : 16),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: ReadingTypography.bodySmall(
                          color: OraclyChrome.cream.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                if (premiumLocked)
                  Text(
                    OraclyL10n.t('explore.premium_mark'),
                    style: ReadingTypography.micro(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.85),
                    ),
                  )
                else if (showPreview)
                  Text(
                    PreviewCapabilityCopy.badge,
                    style: ReadingTypography.micro(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
