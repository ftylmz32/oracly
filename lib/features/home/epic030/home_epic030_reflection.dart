/// EPIC-030 — Approved Home reflection (YANSIT) section.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/navigation/universe/universe_navigation_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/oracly_signature_motifs.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import 'home_epic030_spec.dart';
import 'home_epic030_surface.dart';

class HomeEpic030Reflection extends StatelessWidget {
  const HomeEpic030Reflection({super.key});

  static const String _title = 'OR Rehberi';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          UniverseNavigationCopy.bandReflect,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.72),
            letterSpacing: HomeEpic030Spec.sectionLabelTracking,
            fontWeight: FontWeight.w600,
            fontSize: HomeEpic030Spec.sectionLabelSize,
          ),
        ),
        const OraclySignatureDivider(compact: true),
        SizedBox(height: HomeEpic030Spec.sectionLabelToContent),
        HomeEpic030Surface(
          borderRadius: HomeEpic030Spec.reflectionRadius,
          padding: HomeEpic030Spec.reflectionPadding,
          onTap: () =>
              OraclyFeatureNavigation.open(context, OraclyFeatureId.aiChat),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: HomeEpic030Spec.reflectionMinHeight -
                  HomeEpic030Spec.reflectionPadding.vertical,
            ),
            child: Row(
              children: [
                _IconWell(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: AppColors.textPrimary.withValues(alpha: 0.94),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IconWell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: HomeEpic030Spec.reflectionIconWell,
      height: HomeEpic030Spec.reflectionIconWell,
      decoration: BoxDecoration(
        borderRadius: HomeEpic030Spec.reflectionRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.14),
            AppColors.surface.withValues(alpha: 0.42),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.20),
        ),
      ),
      child: Center(
        child: OraclyAssetImage(
          assetPath: AppAssets.featureAiCrystal,
          width: HomeEpic030Spec.reflectionIcon,
          height: HomeEpic030Spec.reflectionIcon,
          fit: BoxFit.contain,
          fallback: Icon(
            Icons.smart_toy_rounded,
            size: HomeEpic030Spec.reflectionIcon,
            color: AppColors.goldLight.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}
