/// EPIC-032 — Approved 2×3 feature grid.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import 'home_epic032_spec.dart';
import 'home_epic032_surface.dart';

class HomeEpic032FeatureGrid extends StatelessWidget {
  const HomeEpic032FeatureGrid({super.key});

  static const _modules = <_ModuleSpec>[
    _ModuleSpec(
      id: OraclyFeatureId.tarot,
      title: 'Tarot',
      icon: Icons.style_rounded,
      iconAsset: AppAssets.featureTarot,
    ),
    _ModuleSpec(
      id: OraclyFeatureId.dream,
      title: 'Rüya',
      icon: Icons.nightlight_round,
      iconAsset: AppAssets.featureDream,
    ),
    _ModuleSpec(
      id: OraclyFeatureId.astrology,
      title: 'Astroloji',
      icon: Icons.auto_awesome_rounded,
      iconAsset: AppAssets.featureAstrology,
    ),
    _ModuleSpec(
      id: OraclyFeatureId.aiChat,
      title: 'OR Rehberi',
      icon: Icons.smart_toy_rounded,
      iconAsset: AppAssets.featureAiCrystal,
    ),
    _ModuleSpec(
      id: OraclyFeatureId.readingHistory,
      title: 'Geçmiş',
      icon: Icons.menu_book_rounded,
    ),
    _ModuleSpec(
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
          if (row > 0) SizedBox(height: HomeEpic032Spec.gridGap),
          Row(
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col > 0) SizedBox(width: HomeEpic032Spec.gridGap),
                Expanded(
                  child: _ModuleTile(spec: _modules[row * 2 + col]),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ModuleSpec {
  const _ModuleSpec({
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

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.spec});

  final _ModuleSpec spec;

  @override
  Widget build(BuildContext context) {
    final innerMinHeight =
        HomeEpic032Spec.tileHeight(context) - HomeEpic032Spec.tilePadding.vertical;

    return HomeEpic032Surface(
      premium: true,
      borderRadius: HomeEpic032Spec.tileRadius,
      padding: HomeEpic032Spec.tilePadding,
      onTap: () => OraclyFeatureNavigation.open(context, spec.id),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: innerMinHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Transform.translate(
              offset: Offset(0, HomeEpic032Spec.tileIconLift),
              child: _IconWell(
                icon: spec.icon,
                iconAsset: spec.iconAsset,
              ),
            ),
            Text(
              spec.title,
              style: AppTypography.title.copyWith(
                fontSize: HomeEpic032Spec.tileTitleSize,
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
  const _IconWell({required this.icon, this.iconAsset});

  final IconData icon;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HomeEpic032Spec.tileIconWell,
      height: HomeEpic032Spec.tileIconWell,
      decoration: BoxDecoration(
        borderRadius: HomeEpic032Spec.tileRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.14),
            AppColors.surfaceElevated.withValues(alpha: 0.52),
            AppColors.purpleDark.withValues(alpha: 0.38),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: 0.12),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: iconAsset != null
            ? OraclyAssetImage(
                assetPath: iconAsset!,
                width: HomeEpic032Spec.tileIcon + 2,
                height: HomeEpic032Spec.tileIcon + 2,
                fit: BoxFit.contain,
                fallback: Icon(
                  icon,
                  size: HomeEpic032Spec.tileIcon,
                  color: AppColors.goldLight.withValues(alpha: 0.92),
                ),
              )
            : Icon(
                icon,
                size: HomeEpic032Spec.tileIcon,
                color: AppColors.goldLight.withValues(alpha: 0.92),
              ),
      ),
    );
  }
}
