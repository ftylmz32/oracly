/// EPIC-032 — Approved YANSIT / OR Rehberi section.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/navigation/universe/universe_navigation_copy.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../../shared/widgets/oracly_section_title.dart';
import 'home_epic032_spec.dart';
import 'home_epic032_surface.dart';

class HomeEpic032Reflection extends StatelessWidget {
  const HomeEpic032Reflection({super.key});

  static const String _title = 'OR Rehberi';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OraclySectionTitle(
          label: UniverseNavigationCopy.bandReflect,
          tracking: HomeEpic032Spec.sectionLabelTracking,
          fontSize: HomeEpic032Spec.sectionLabelSize,
        ),
        HomeEpic032Surface(
          premium: true,
          borderRadius: HomeEpic032Spec.reflectionRadius,
          padding: HomeEpic032Spec.reflectionPadding,
          onTap: () =>
              OraclyFeatureNavigation.open(context, OraclyFeatureId.aiChat),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: HomeEpic032Spec.reflectionMinHeight -
                  HomeEpic032Spec.reflectionPadding.vertical,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IconWell(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(
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
      width: HomeEpic032Spec.reflectionIconWell,
      height: HomeEpic032Spec.reflectionIconWell,
      decoration: BoxDecoration(
        borderRadius: HomeEpic032Spec.reflectionRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.18),
            AppColors.surfaceElevated.withValues(alpha: 0.48),
            AppColors.purpleDark.withValues(alpha: 0.36),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: 0.10),
            blurRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: OraclyAssetImage(
          assetPath: AppAssets.featureAiCrystal,
          width: HomeEpic032Spec.reflectionIcon,
          height: HomeEpic032Spec.reflectionIcon,
          fit: BoxFit.contain,
          fallback: Icon(
            Icons.smart_toy_rounded,
            size: HomeEpic032Spec.reflectionIcon,
            color: AppColors.goldLight.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}
