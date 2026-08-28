/// EPIC-017 / EPIC-018 / EPIC-022 — Premium hero card — orb centerpiece.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_glows.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_shadows.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/oracly_signature_motifs.dart';
import '../../../core/design_system/hero_art/hero_art.dart' as hero_art;
import '../theme/home_architecture.dart';
import '../theme/home_composition.dart';
import '../theme/home_focus.dart';
import '../theme/home_presence.dart';
import '../theme/home_reward.dart';
import 'hero_orb_v3/orb_constants.dart';

/// Large premium hero chamber — ~40% viewport, orb overlaps rim with depth.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = HomeFocusScope.of(context);
    final orbSize = HomeComposition.orbSize;
    final halo = orbSize * HomeComposition.orbHaloScale;
    final glowStrength = scope.glowFor(HomeFocusZone.orb);
    final parallax =
        HomePresenceRhythm.parallaxForeground(scope.scrollOffset);
    final cardHeight = HomeComposition.heroCardHeight(context);
    final overlap = HomeComposition.orbContainerOverlap;
    final orbCanvas = OrbConstants.renderSize(orbSize);

    return AnimatedBuilder(
      animation: scope.presence,
      builder: (context, _) {
        final phase = scope.presencePhase;
        final floatY = sin(phase * pi * 2) * 4.5;
        final veil = HomePresenceRhythm.ambientVeil(phase);
        final combinedVeil =
            (veil * (0.88 + scope.worldCalm * 0.12)).clamp(0.0, 1.0);
        final chamberAlpha =
            (0.68 + glowStrength * 0.24).clamp(0.0, 1.0) * combinedVeil;

        return Transform.translate(
          offset: Offset(0, parallax + floatY),
          child: SizedBox(
            width: double.infinity,
            height: cardHeight + overlap,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: overlap,
                  left: 0,
                  right: 0,
                  height: cardHeight - overlap * 0.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.s32,
                      boxShadow: [
                        ...AppShadows.luxury,
                        ...AppGlows.medium(strength: 0.85 + glowStrength * 0.15),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.s32,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.surfaceElevated
                                      .withValues(alpha: 0.96),
                                  AppColors.surface.withValues(alpha: 0.88),
                                  AppColors.backgroundSecondary
                                      .withValues(alpha: 0.94),
                                ],
                                stops: const [0.0, 0.48, 1.0],
                              ),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.32),
                                width: AppBorderWidth.gold,
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: Opacity(
                              opacity: 0.62 * combinedVeil,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(0, -0.12),
                                    radius: 1.0,
                                    colors: [
                                      AppColors.glowGold.withValues(alpha: 0.20),
                                      AppColors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const OraclySignatureCornerOrnaments(
                            inset: 14,
                            size: 16,
                          ),
                          Positioned.fill(
                            child: _DecorativeStars(opacity: combinedVeil),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: (0.28 + glowStrength * 0.16)
                                    .clamp(0.0, 1.0),
                                child: HomeCrystalShimmerOverlay(
                                  phase: phase,
                                  borderRadius: AppRadius.s32,
                                  intensity: 0.38,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: (0.48 + glowStrength * 0.2).clamp(0.0, 1.0),
                      child: Center(
                        child: Container(
                          width: halo * 1.22,
                          height: halo * 0.76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: AppGlows.hero(strength: 0.72),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: overlap * 0.2,
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.s12,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      IgnorePointer(
                        child: Opacity(
                          opacity: chamberAlpha,
                          child: Container(
                            width: halo * 1.14,
                            height: halo * 0.92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient:
                                  HomeComposition.orbChamberGlow(phase),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Opacity(
                          opacity: (0.82 + glowStrength * 0.18)
                                  .clamp(0.0, 1.0) *
                              combinedVeil,
                          child: Container(
                            width: halo,
                            height: halo * 0.74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: HomeComposition.orbPedestalGlow,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: orbCanvas * 0.38,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: combinedVeil.clamp(0.0, 1.0),
                            child: HomeOrbSpillColumn(
                              width: halo * 0.48,
                              height: orbSize * 0.34,
                            ),
                          ),
                        ),
                      ),
                      hero_art.HeroOrb(size: orbSize),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DecorativeStars extends StatelessWidget {
  const _DecorativeStars({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Stack(
          fit: StackFit.expand,
          children: const [
            _Star(top: 22, left: 28, size: 6),
            _Star(top: 36, right: 32, size: 4, dim: true),
            _Star(bottom: 48, left: 40, size: 5),
            _Star(bottom: 62, right: 44, size: 4, dim: true),
            _Star(top: 72, left: 72, size: 3, dim: true),
            _Star(top: 88, right: 68, size: 5),
          ],
        ),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.size = 5,
    this.dim = false,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Icon(
        Icons.auto_awesome,
        size: size,
        color: dim
            ? AppColors.gold.withValues(alpha: 0.45)
            : AppColors.goldLight.withValues(alpha: 0.75),
      ),
    );
  }
}
