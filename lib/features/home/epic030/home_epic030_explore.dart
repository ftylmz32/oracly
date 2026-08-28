/// EPIC-030 — Approved Home explore (KEŞFET) section.
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

class HomeEpic030Explore extends StatelessWidget {
  const HomeEpic030Explore({super.key});

  static const _items = <_ExploreItem>[
    _ExploreItem(
      id: OraclyFeatureId.dream,
      title: 'Rüya',
      icon: Icons.nightlight_round,
      asset: AppAssets.featureDream,
    ),
    _ExploreItem(
      id: OraclyFeatureId.astrology,
      title: 'Astroloji',
      icon: Icons.auto_awesome_rounded,
      asset: AppAssets.featureAstrology,
    ),
    _ExploreItem(
      id: OraclyFeatureId.starMap,
      title: 'Doğum Haritası',
      icon: Icons.star_outline_rounded,
      asset: AppAssets.featureStarMap,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          UniverseNavigationCopy.bandExplore,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.72),
            letterSpacing: HomeEpic030Spec.sectionLabelTracking,
            fontWeight: FontWeight.w600,
            fontSize: HomeEpic030Spec.sectionLabelSize,
          ),
        ),
        const OraclySignatureDivider(compact: true),
        SizedBox(height: HomeEpic030Spec.sectionLabelToContent),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) SizedBox(width: HomeEpic030Spec.exploreGap),
              Expanded(child: _ExploreTile(item: _items[i])),
            ],
          ],
        ),
      ],
    );
  }
}

class _ExploreItem {
  const _ExploreItem({
    required this.id,
    required this.title,
    required this.icon,
    this.asset,
  });

  final OraclyFeatureId id;
  final String title;
  final IconData icon;
  final String? asset;
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({required this.item});

  final _ExploreItem item;

  @override
  Widget build(BuildContext context) {
    final innerMin = HomeEpic030Spec.exploreMinHeight -
        HomeEpic030Spec.explorePadding.vertical;

    return HomeEpic030Surface(
      borderRadius: HomeEpic030Spec.exploreRadius,
      padding: HomeEpic030Spec.explorePadding,
      onTap: () => OraclyFeatureNavigation.open(context, item.id),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: innerMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (item.asset != null)
              OraclyAssetImage(
                assetPath: item.asset!,
                width: HomeEpic030Spec.exploreIcon,
                height: HomeEpic030Spec.exploreIcon,
                fit: BoxFit.contain,
                fallback: Icon(
                  item.icon,
                  size: HomeEpic030Spec.exploreIcon,
                  color: AppColors.goldLight.withValues(alpha: 0.92),
                ),
              )
            else
              Icon(
                item.icon,
                size: HomeEpic030Spec.exploreIcon,
                color: AppColors.goldLight.withValues(alpha: 0.92),
              ),
            Text(
              item.title,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
                letterSpacing: 0.15,
                color: AppColors.textPrimary.withValues(alpha: 0.90),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
