/// OR-050 — Shared moon artwork for hero transitions.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../daily_energy_constants.dart';

/// Moon illustration used as the hero flight element from Home card.
class DailyEnergyMoonHero extends StatelessWidget {
  const DailyEnergyMoonHero({
    super.key,
    this.width = 140,
    this.height = 168,
    this.enableHero = true,
  });

  final double width;
  final double height;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    final artwork = _MoonArtwork(width: width, height: height);

    if (!enableHero) return artwork;

    return Hero(
      tag: DailyEnergyHeroTags.moonIllustration,
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              type: MaterialType.transparency,
              child: child,
            );
          },
          child: toHeroContext.widget,
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: artwork,
      ),
    );
  }
}

class _MoonArtwork extends StatelessWidget {
  const _MoonArtwork({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.14),
                    AppColors.purple.withValues(alpha: 0.08),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) {
              return RadialGradient(
                colors: [
                  AppColors.white,
                  AppColors.white.withValues(alpha: 0.92),
                  AppColors.transparent,
                ],
                stops: const [0.55, 0.82, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: OraclyAssetImage(
              assetPath: AppAssets.dailyMoonPhotoreal,
              width: width,
              height: height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              fallback: Icon(
                Icons.nightlight_round,
                size: AppSpacing.xxl,
                color: AppColors.goldLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
