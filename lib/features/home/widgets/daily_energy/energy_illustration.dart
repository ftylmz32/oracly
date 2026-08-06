/// OR-004.4 / OR-026 — Daily energy card premium moon artwork.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';

/// Premium daily energy artwork — integrated into the card's right column.
class EnergyIllustration extends StatelessWidget {
  const EnergyIllustration({super.key});

  static const double _minSlotHeight = 148;
  static const double _fallbackSlotWidth = 112;
  static const double _scale = 1.10;
  static const double _edgeOverflow = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : _fallbackSlotWidth;
        final slotHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : _minSlotHeight;

        final artHeight = slotHeight * _scale;
        final artWidth = slotWidth + _edgeOverflow;
        final verticalOverflow = (artHeight - slotHeight) / 2;

        return SizedBox(
          width: slotWidth,
          height: slotHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerRight,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.82, 0.42),
                      radius: 0.72,
                      colors: [
                        AppColors.gold.withValues(alpha: 0.07),
                        AppColors.purple.withValues(alpha: 0.05),
                        AppColors.transparent,
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: slotWidth * 0.10,
                top: slotHeight * 0.14,
                child: _IntegratedMoonGlow(size: slotHeight * 0.50),
              ),
              Positioned(
                right: -_edgeOverflow,
                top: -verticalOverflow - 2,
                width: artWidth,
                height: artHeight,
                child: _BlendedMoonArtwork(
                  width: artWidth,
                  height: artHeight,
                ),
              ),
              Positioned(
                right: slotWidth * 0.06,
                bottom: slotHeight * 0.06,
                child: _MoonContactShadow(width: slotWidth * 0.42),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Moon PNG with soft edge blending into the card surface.
class _BlendedMoonArtwork extends StatelessWidget {
  const _BlendedMoonArtwork({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.transparent,
            Color(0xCCFFFFFF),
            AppColors.white,
          ],
          stops: [0.0, 0.14, 0.38],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppColors.transparent,
              Color(0xEEFFFFFF),
              AppColors.white,
            ],
            stops: [0.0, 0.08, 0.22],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: OraclyAssetImage(
          assetPath: AppAssets.dailyEnergyMoon,
          width: width,
          height: height,
          fit: BoxFit.contain,
          alignment: Alignment.centerRight,
          filterQuality: FilterQuality.high,
          fallback: Icon(
            Icons.nightlight_round,
            size: AppSpacing.xxl,
            color: AppColors.goldLight,
          ),
        ),
      ),
    );
  }
}

/// Ground shadow beneath the moon — anchors artwork to the card.
class _MoonContactShadow extends StatelessWidget {
  const _MoonContactShadow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 3),
      child: Container(
        width: width,
        height: AppSpacing.sm,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.elliptical(width * 0.5, AppSpacing.xs),
          ),
          gradient: RadialGradient(
            colors: [
              AppColors.background.withValues(alpha: 0.42),
              AppColors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft radial wash integrated behind the moon artwork.
class _IntegratedMoonGlow extends StatelessWidget {
  const _IntegratedMoonGlow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.goldLight.withValues(alpha: 0.12),
                AppColors.gold.withValues(alpha: 0.06),
                AppColors.purpleGlow.withValues(alpha: 0.04),
                AppColors.transparent,
              ],
              stops: const [0.0, 0.38, 0.62, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
