/// Cinematic discovery portals — fixed cover crop, Flutter owns titles.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import 'home_module_visual.dart';

class HomeDiscoveryModuleArt extends StatelessWidget {
  const HomeDiscoveryModuleArt({super.key, required this.visual});

  final HomeModuleVisual visual;

  static String assetFor(HomeModuleVisual visual) => switch (visual) {
        HomeModuleVisual.coffee => AppAssets.homeCoffee,
        HomeModuleVisual.palm => AppAssets.homePalm,
        HomeModuleVisual.astrology => AppAssets.homeAstrology,
        HomeModuleVisual.starMap => AppAssets.homeYildizname,
        HomeModuleVisual.soulMate => AppAssets.homeSoulMate,
        HomeModuleVisual.tarot => AppAssets.homeTarot,
        HomeModuleVisual.dream => AppAssets.homeDream,
      };

  /// Subject-aware crop — keeps each chamber’s focal subject readable on tile.
  static Alignment alignmentFor(HomeModuleVisual visual) => switch (visual) {
        HomeModuleVisual.coffee => const Alignment(0, 0.04),
        HomeModuleVisual.palm => const Alignment(0, 0.18),
        HomeModuleVisual.astrology => const Alignment(0.08, 0.16),
        HomeModuleVisual.starMap => const Alignment(0, 0.22),
        HomeModuleVisual.soulMate => const Alignment(0, -0.16),
        HomeModuleVisual.tarot => const Alignment(0, 0.08),
        HomeModuleVisual.dream => const Alignment(0, -0.08),
      };

  static IconData iconFor(HomeModuleVisual visual) => switch (visual) {
        HomeModuleVisual.coffee => Icons.local_cafe_rounded,
        HomeModuleVisual.palm => Icons.pan_tool_alt_rounded,
        HomeModuleVisual.astrology => Icons.auto_awesome_rounded,
        HomeModuleVisual.starMap => Icons.star_rounded,
        HomeModuleVisual.soulMate => Icons.favorite_rounded,
        HomeModuleVisual.tarot => Icons.style_rounded,
        HomeModuleVisual.dream => Icons.nightlight_round,
      };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.nearBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: OraclyAssetImage(
              assetPath: assetFor(visual),
              fit: BoxFit.cover,
              alignment: alignmentFor(visual),
              filterQuality: FilterQuality.medium,
              cacheCapPx: 512,
              fallback: Icon(
                iconFor(visual),
                color: AppColors.goldLight.withValues(alpha: 0.72),
              ),
            ),
          ),
          // Soft grade — keep art luminous, never crush midtones.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x1A0A0618),
                  Color(0x08000000),
                  Color(0x185A3FD6),
                  Color(0x120A0614),
                ],
                stops: [0.0, 0.35, 0.72, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.15, -0.55),
                radius: 1.05,
                colors: [
                  AppColors.gold.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
