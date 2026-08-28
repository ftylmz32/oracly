/// EPIC-026 — Five-layer cinematic lighting stack for full-screen atmosphere.
library;

import 'package:flutter/material.dart';

import 'cinematic_lighting_painters.dart';
import 'cinematic_lighting_tokens.dart';
import '../micro_details/micro_detail_widgets.dart';
import '../oracly_light_sanctuary_background.dart';
import '../../theme/oracly_quiet_motion.dart';

/// Composes the global 5-layer light model behind all screen content.
///
/// Layer 1 — Deep ambient darkness
/// Layer 2 — Large radial nebula gradients + moving fog
/// Layer 3 — Gold highlight wash (hero zone illumination)
/// Layer 4 — Gold specular accents
/// Layer 5 — Soft particles + cinematic vignette
class CinematicLightingStack extends StatefulWidget {
  const CinematicLightingStack({
    super.key,
    this.preset = CinematicLightingPreset.neutral,
    this.child,
    this.showNoise = true,
    this.showStars = true,
    this.showParticles = true,
    this.showVignette = true,
    this.intensity = 1.0,
  });

  final CinematicLightingPreset preset;
  final Widget? child;
  final bool showNoise;
  final bool showStars;
  final bool showParticles;
  final bool showVignette;
  final double intensity;

  @override
  State<CinematicLightingStack> createState() => _CinematicLightingStackState();
}

class _CinematicLightingStackState extends State<CinematicLightingStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: CinematicLightingTokens.breathCycle,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.5);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return OraclyLightSanctuaryBackground(child: widget.child);
    }
    final still = OraclyQuietMotion.still(context);
    final showBusy = !still;
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final phase = Curves.easeInOut.transform(
          still ? 0.5 : _breath.value,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // L1 — ambient darkness
            RepaintBoundary(
              child: CustomPaint(
                painter: AmbientDarknessPainter(preset: widget.preset),
              ),
            ),
            // L2 — nebula + fog (parallax drift)
            MicroParallaxDrift(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: NebulaRadialPainter(
                    preset: widget.preset,
                    phase: phase,
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: LightFogPainter(
                  phase: phase,
                  preset: widget.preset,
                ),
              ),
            ),
            if (widget.showNoise && showBusy)
              RepaintBoundary(
                child: CustomPaint(
                  painter: SubtleNoisePainter(seed: 31, phase: phase),
                ),
              ),
            if (widget.showStars)
              RepaintBoundary(
                child: CustomPaint(
                  painter: DistantStarsPainter(
                    preset: widget.preset,
                    phase: phase,
                  ),
                ),
              ),
            // L3/L4 — gold highlights
            RepaintBoundary(
              child: CustomPaint(
                painter: GoldHighlightPainter(phase: phase),
              ),
            ),
            // L5 — particles
            if (widget.showParticles && showBusy)
              RepaintBoundary(
                child: CustomPaint(
                  painter: SoftParticleLightPainter(
                    preset: widget.preset,
                    phase: phase,
                  ),
                ),
              ),
            if (widget.showVignette)
              RepaintBoundary(
                child: CustomPaint(
                  painter: CinematicVignettePainter(
                    strength: CinematicLightingTokens.vignetteStrength *
                        widget.intensity,
                  ),
                ),
              ),
            ?child,
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Maps [OraclyAmbience]-like names to lighting presets.
CinematicLightingPreset presetForAmbience(String ambience) =>
    switch (ambience) {
      'home' => CinematicLightingPreset.home,
      'dream' => CinematicLightingPreset.dream,
      'celestial' => CinematicLightingPreset.celestial,
      'tarot' => CinematicLightingPreset.tarot,
      'premium' => CinematicLightingPreset.premium,
      'companion' => CinematicLightingPreset.companion,
      _ => CinematicLightingPreset.neutral,
    };
