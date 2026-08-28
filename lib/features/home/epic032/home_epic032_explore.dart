/// EPIC-032 — Approved KEŞFET trio.
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

class HomeEpic032Explore extends StatelessWidget {
  const HomeEpic032Explore({super.key});

  static const _items = <_DiscoverItem>[
    _DiscoverItem(
      id: OraclyFeatureId.dream,
      title: 'Rüya',
      icon: Icons.nightlight_round,
      iconAsset: AppAssets.featureDream,
    ),
    _DiscoverItem(
      id: OraclyFeatureId.astrology,
      title: 'Astroloji',
      icon: Icons.auto_awesome_rounded,
      iconAsset: AppAssets.featureAstrology,
    ),
    _DiscoverItem(
      id: OraclyFeatureId.starMap,
      title: 'Doğum Haritası',
      icon: Icons.star_outline_rounded,
      iconAsset: AppAssets.featureStarMap,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OraclySectionTitle(
          label: UniverseNavigationCopy.bandExplore,
          tracking: HomeEpic032Spec.sectionLabelTracking,
          fontSize: HomeEpic032Spec.sectionLabelSize,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) SizedBox(width: HomeEpic032Spec.exploreGap),
              Expanded(child: _DiscoverCard(item: _items[i])),
            ],
          ],
        ),
      ],
    );
  }
}

class _DiscoverItem {
  const _DiscoverItem({
    required this.id,
    required this.title,
    required this.icon,
    this.iconAsset,
  });

  final OraclyFeatureId id;
  final String title;
  final IconData icon;
  final String? iconAsset;
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({required this.item});

  final _DiscoverItem item;

  @override
  Widget build(BuildContext context) {
    final innerMinHeight =
        HomeEpic032Spec.exploreMinHeight - HomeEpic032Spec.explorePadding.vertical;

    return HomeEpic032Surface(
      premium: true,
      borderRadius: HomeEpic032Spec.exploreRadius,
      padding: HomeEpic032Spec.explorePadding,
      onTap: () => OraclyFeatureNavigation.open(context, item.id),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: innerMinHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (item.iconAsset != null)
              OraclyAssetImage(
                assetPath: item.iconAsset!,
                width: HomeEpic032Spec.exploreIcon,
                height: HomeEpic032Spec.exploreIcon,
                fit: BoxFit.contain,
                fallback: Icon(
                  item.icon,
                  size: HomeEpic032Spec.exploreIcon,
                  color: AppColors.goldLight.withValues(alpha: 0.92),
                ),
              )
            else
              Icon(
                item.icon,
                size: HomeEpic032Spec.exploreIcon,
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
