/// OR-414 — Premium reward feeling — crafted, never game-like.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/oracly_brand_signature.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import 'home_focus.dart';

/// Reward motion and intensity tokens.
abstract final class HomeReward {
  HomeReward._();

  static const press = OraclySignatureMotion.press;
  static const release = OraclySignatureMotion.pressRelease;
  static const sweep = Duration(milliseconds: 480);
  static const pulse = Duration(milliseconds: 2400);

  static const curve = Curves.easeOutCubic;
  static const releaseCurve = Curves.easeOutQuart;

  /// Depth compression — luxury object settling into touch.
  static double depthCompress(bool pressed) => pressed ? 1.4 : 0.0;

  static double pressScale(bool pressed, {bool featured = false}) =>
      pressed ? (featured ? 0.978 : 0.982) : 1.0;

  /// Specular reflection travels slightly on press.
  static double reflectionShift(bool pressed) => pressed ? 0.06 : 0.0;

  /// Orb acknowledges spread selection — subconscious only.
  static double orbBoost(HomeFocusZone active) =>
      active == HomeFocusZone.spread ? 1.04 : 1.0;

  /// Nearby panels breathe a whisper of light when a neighbour interacts.
  static double ambientLift(HomeFocusZone zone, HomeFocusZone active) {
    if (active == HomeFocusZone.none || zone == active) return 0.0;
    return switch (active) {
      HomeFocusZone.spread when zone == HomeFocusZone.orb ||
          zone == HomeFocusZone.daily =>
        0.035,
      HomeFocusZone.daily when zone == HomeFocusZone.spread ||
          zone == HomeFocusZone.premium =>
        0.028,
      HomeFocusZone.premium when zone == HomeFocusZone.daily ||
          zone == HomeFocusZone.ai =>
        0.025,
      HomeFocusZone.ai when zone == HomeFocusZone.premium ||
          zone == HomeFocusZone.cosmic =>
        0.022,
      _ => 0.015,
    };
  }

  static double glowPulse(double phase) =>
      0.975 + 0.025 * Curves.easeInOut.transform(phase);
}

/// Travelling gold highlight — crystal acknowledging selection.
class HomeGoldSweepOverlay extends StatelessWidget {
  const HomeGoldSweepOverlay({
    super.key,
    required this.progress,
    required this.borderRadius,
    this.intensity = 1.0,
  });

  final double progress;
  final BorderRadius borderRadius;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.01) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _HomeGoldSweepPainter(
          progress: progress,
          intensity: intensity,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HomeGoldSweepPainter extends CustomPainter {
  const _HomeGoldSweepPainter({
    required this.progress,
    required this.intensity,
  });

  final double progress;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final travel = size.width * (progress * 1.35 - 0.18);
    final band = size.width * 0.22;
    final rect = Rect.fromLTWH(travel - band * 0.5, 0, band, size.height);

    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.transparent,
            AppColors.gold.withValues(alpha: 0.06 * intensity),
            AppColors.goldLight.withValues(alpha: 0.14 * intensity),
            AppColors.gold.withValues(alpha: 0.06 * intensity),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.32, 0.5, 0.68, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _HomeGoldSweepPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity;
}

/// Soft crystal shimmer — barely visible reward veil.
class HomeCrystalShimmerOverlay extends StatelessWidget {
  const HomeCrystalShimmerOverlay({
    super.key,
    required this.phase,
    required this.borderRadius,
    this.intensity = 1.0,
  });

  final double phase;
  final BorderRadius borderRadius;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final shimmer = HomeReward.glowPulse(phase);

    return ClipRRect(
      borderRadius: borderRadius,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.purpleLight.withValues(alpha: 0.04 * shimmer * intensity),
                AppColors.transparent,
                AppColors.goldLight.withValues(alpha: 0.05 * shimmer * intensity),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Luxury button specular — shifts on physical press.
class HomeLuxuryReflection extends StatelessWidget {
  const HomeLuxuryReflection({
    super.key,
    required this.pressed,
    this.borderRadius = AppRadius.sm,
  });

  final bool pressed;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final shift = HomeReward.reflectionShift(pressed);

    return ClipRRect(
      borderRadius: borderRadius,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment(-1.0 + shift * 2, -0.92),
          child: Container(
            height: 0.7,
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.md + shift * 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.transparent,
                  AppColors.goldLight.withValues(alpha: pressed ? 0.22 : 0.12),
                  AppColors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gentle reward glow pulse around embedded panels while pressed.
class HomeRewardGlowPulse extends StatelessWidget {
  const HomeRewardGlowPulse({
    super.key,
    required this.phase,
    required this.borderRadius,
    this.intensity = 1.0,
  });

  final double phase;
  final BorderRadius borderRadius;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final pulse = HomeReward.glowPulse(phase);

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: 0.08 * pulse * intensity),
              blurRadius: 20,
              spreadRadius: -4,
            ),
            BoxShadow(
              color: AppColors.glowPurple.withValues(alpha: 0.05 * pulse * intensity),
              blurRadius: 24,
              spreadRadius: -6,
            ),
          ],
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
