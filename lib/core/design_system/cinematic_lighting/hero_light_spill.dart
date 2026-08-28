/// EPIC-026 — Hero light spill — illuminates nearby UI from hero artwork.
library;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'cinematic_lighting_tokens.dart';

/// Wraps a hero widget and casts soft radial light onto surrounding content.
class HeroLightSpill extends StatefulWidget {
  const HeroLightSpill({
    super.key,
    required this.child,
    required this.accent,
    this.intensity = 1.0,
    this.spillHeight = 120,
  });

  final Widget child;
  final Color accent;
  final double intensity;
  final double spillHeight;

  @override
  State<HeroLightSpill> createState() => _HeroLightSpillState();
}

class _HeroLightSpillState extends State<HeroLightSpill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: CinematicLightingTokens.breathCycle,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final phase = Curves.easeInOut.transform(_pulse.value);
        final spillAlpha = (0.14 + phase * 0.08) * widget.intensity;
        final glowAlpha = (0.22 + phase * 0.12) * widget.intensity;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: -widget.spillHeight * 0.35,
              left: -40,
              right: -40,
              height: widget.spillHeight,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.1,
                      colors: [
                        widget.accent.withValues(alpha: spillAlpha),
                        widget.accent.withValues(alpha: spillAlpha * 0.35),
                        AppColors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: CinematicLightingTokens.heroSpillRadius,
                      colors: [
                        widget.accent.withValues(alpha: glowAlpha * 0.35),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Soft bloom for important titles — subtle shadow hierarchy, never blurry.
class LitTitle extends StatelessWidget {
  const LitTitle({
    super.key,
    required this.child,
    this.bloomStrength = 1.0,
  });

  final Widget child;
  final double bloomStrength;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(
        shadows: [
          Shadow(
            color: AppColors.goldLight.withValues(alpha: 0.38 * bloomStrength),
            blurRadius: 14,
          ),
          Shadow(
            color: AppColors.glowPurple.withValues(alpha: 0.18 * bloomStrength),
            blurRadius: 24,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Proximity-based card illumination — cards closer to hero receive more light.
class HeroProximityLight extends StatelessWidget {
  const HeroProximityLight({
    super.key,
    required this.child,
    required this.proximity,
    this.accent = AppColors.goldLight,
  });

  /// 0 = far from hero, 1 = directly beneath hero.
  final Widget child;
  final double proximity;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final clamped = proximity.clamp(0.0, 1.0);
    if (clamped < 0.05) return child;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    accent.withValues(alpha: 0.08 * clamped),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
