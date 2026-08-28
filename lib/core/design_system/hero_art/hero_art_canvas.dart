/// EPIC-024 — Five-layer hero artwork canvas with slow cinematic motion.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'hero_art_painters.dart';
import 'hero_art_tokens.dart';
import '../micro_details/micro_detail_tokens.dart';
import '../cinematic_lighting/hero_light_spill.dart';

/// Builds center artwork painter for the current animation phase.
typedef HeroArtworkBuilder = CustomPainter Function(double phase);

/// Composes background, light, artwork, glow, particles, and orbit layers.
class HeroArtCanvas extends StatefulWidget {
  const HeroArtCanvas({
    super.key,
    required this.size,
    required this.theme,
    required this.artwork,
    this.seed = 0,
    this.showOrbits = true,
    this.particleDensity = 22,
  });

  final double size;
  final HeroArtTheme theme;
  final HeroArtworkBuilder artwork;
  final int seed;
  final bool showOrbits;
  final int particleDensity;

  @override
  State<HeroArtCanvas> createState() => _HeroArtCanvasState();
}

class _HeroArtCanvasState extends State<HeroArtCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: HeroArtTokens.breathCycle,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HeroLightSpill(
      accent: HeroArtTokens.accentFor(widget.theme),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          final phase = Curves.easeInOut.transform(_motion.value);
          final floatY = math.sin(phase * math.pi * 2) * HeroArtTokens.floatAmplitude;
          final scaleBreath =
              1.0 + math.sin(phase * math.pi * 2) * MicroDetailTokens.heroScaleBreath;

          return Transform.scale(
            scale: scaleBreath,
            alignment: Alignment.center,
            child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: HeroBackgroundPainter(
                    theme: widget.theme,
                    phase: phase,
                  ),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: HeroLightPainter(
                    theme: widget.theme,
                    phase: phase,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, floatY),
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: widget.artwork(phase),
                  ),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: HeroGlowPainter(
                    theme: widget.theme,
                    phase: phase,
                  ),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: HeroParticlePainter(
                    seed: widget.seed,
                    phase: phase,
                    theme: widget.theme,
                    density: widget.particleDensity,
                  ),
                ),
              ),
              if (widget.showOrbits)
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: HeroOrbitPainter(
                      seed: widget.seed,
                      phase: phase,
                      theme: widget.theme,
                    ),
                  ),
                ),
            ],
          ),
          );
        },
        ),
      ),
    );
  }
}

/// Sizes hero artwork to ~35–50% of viewport height.
class HeroArtViewport extends StatelessWidget {
  const HeroArtViewport({
    super.key,
    required this.child,
    this.fraction = HeroArtTokens.viewportFractionDefault,
    this.minSize = HeroArtTokens.minHeroSize,
    this.maxSize = HeroArtTokens.maxHeroSize,
  });

  final Widget child;
  final double fraction;
  final double minSize;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    final viewportH = MediaQuery.sizeOf(context).height * fraction;
    final size = viewportH.clamp(minSize, maxSize);

    return SizedBox(
      width: double.infinity,
      height: size,
      child: Center(child: child),
    );
  }
}

/// Resolves hero size from viewport fraction.
double heroArtSizeForContext(
  BuildContext context, {
  double fraction = HeroArtTokens.viewportFractionDefault,
}) {
  final viewportH = MediaQuery.sizeOf(context).height * fraction;
  return viewportH.clamp(HeroArtTokens.minHeroSize, HeroArtTokens.maxHeroSize);
}
