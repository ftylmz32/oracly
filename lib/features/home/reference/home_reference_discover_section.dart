/// Reference Keşfet row — three equal vertical cards.
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
import 'home_reference_card_shell.dart';
import 'home_reference_tokens.dart';

class HomeReferenceDiscoverSection extends StatelessWidget {
  const HomeReferenceDiscoverSection({super.key});

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
      title: 'Yıldızname',
      icon: Icons.star_outline_rounded,
      iconAsset: AppAssets.featureStarMap,
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
            letterSpacing: 2.8,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const OraclySignatureDivider(compact: true),
        SizedBox(height: HomeReferenceTokens.sectionLabelToContent),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) SizedBox(width: HomeReferenceTokens.discoverGap),
              Expanded(
                child: _DiscoverCard(item: _items[i]),
              ),
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
    final innerMinHeight = HomeReferenceTokens.discoverCardMinHeight -
        HomeReferenceTokens.discoverPadding.vertical;

    return HomeReferenceCardShell(
      borderRadius: HomeReferenceTokens.discoverRadius,
      padding: HomeReferenceTokens.discoverPadding,
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
                width: HomeReferenceTokens.discoverIconSize,
                height: HomeReferenceTokens.discoverIconSize,
                fit: BoxFit.contain,
                fallback: Icon(
                  item.icon,
                  size: HomeReferenceTokens.discoverIconSize,
                  color: AppColors.goldLight.withValues(alpha: 0.92),
                ),
              )
            else
              Icon(
                item.icon,
                size: HomeReferenceTokens.discoverIconSize,
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
