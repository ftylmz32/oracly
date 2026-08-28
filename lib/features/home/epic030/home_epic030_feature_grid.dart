/// EPIC-030 — Approved Home 2×3 feature grid.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import 'home_epic030_spec.dart';
import 'home_epic030_surface.dart';

class HomeEpic030FeatureGrid extends StatelessWidget {
  const HomeEpic030FeatureGrid({super.key});

  static const _items = <_FeatureItem>[
    _FeatureItem(
      id: OraclyFeatureId.tarot,
      title: 'Tarot',
      icon: Icons.style_rounded,
      asset: AppAssets.featureTarot,
    ),
    _FeatureItem(
      id: OraclyFeatureId.dream,
      title: 'Rüya',
      icon: Icons.nightlight_round,
      asset: AppAssets.featureDream,
    ),
    _FeatureItem(
      id: OraclyFeatureId.astrology,
      title: 'Astroloji',
      icon: Icons.auto_awesome_rounded,
      asset: AppAssets.featureAstrology,
    ),
    _FeatureItem(
      id: OraclyFeatureId.aiChat,
      title: 'OR Rehberi',
      icon: Icons.smart_toy_rounded,
      asset: AppAssets.featureAiCrystal,
    ),
    _FeatureItem(
      id: OraclyFeatureId.readingHistory,
      title: 'Geçmiş',
      icon: Icons.menu_book_rounded,
    ),
    _FeatureItem(
      id: OraclyFeatureId.memory,
      title: 'Hafıza',
      icon: Icons.psychology_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 3; row++) ...[
          if (row > 0) SizedBox(height: HomeEpic030Spec.gridGap),
          Row(
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col > 0) SizedBox(width: HomeEpic030Spec.gridGap),
                Expanded(
                  child: _FeatureTile(item: _items[row * 2 + col]),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
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

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item});

  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    final innerMin = HomeEpic030Spec.tileHeight(context) -
        HomeEpic030Spec.tilePadding.vertical;

    return HomeEpic030Surface(
      premium: true,
      borderRadius: HomeEpic030Spec.tileRadius,
      padding: HomeEpic030Spec.tilePadding,
      onTap: () => OraclyFeatureNavigation.open(context, item.id),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: innerMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Transform.translate(
              offset: const Offset(0, HomeEpic030Spec.tileIconLift),
              child: _IconWell(icon: item.icon, asset: item.asset),
            ),
            Text(
              item.title,
              style: AppTextStyles.title.copyWith(
                fontSize: HomeEpic030Spec.tileTitleSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                height: 1.25,
                color: AppColors.textPrimary.withValues(alpha: 0.94),
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

class _IconWell extends StatelessWidget {
  const _IconWell({required this.icon, this.asset});

  final IconData icon;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HomeEpic030Spec.tileIconWell,
      height: HomeEpic030Spec.tileIconWell,
      decoration: BoxDecoration(
        borderRadius: HomeEpic030Spec.tileRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.textPrimary.withValues(alpha: 0.16),
            AppColors.textPrimary.withValues(alpha: 0.04),
            AppColors.surface.withValues(alpha: 0.40),
          ],
        ),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.09),
        ),
      ),
      child: Center(
        child: asset != null
            ? OraclyAssetImage(
                assetPath: asset!,
                width: HomeEpic030Spec.tileIcon + 2,
                height: HomeEpic030Spec.tileIcon + 2,
                fit: BoxFit.contain,
                fallback: Icon(
                  icon,
                  size: HomeEpic030Spec.tileIcon,
                  color: AppColors.goldLight.withValues(alpha: 0.92),
                ),
              )
            : Icon(
                icon,
                size: HomeEpic030Spec.tileIcon,
                color: AppColors.goldLight.withValues(alpha: 0.92),
              ),
      ),
    );
  }
}
