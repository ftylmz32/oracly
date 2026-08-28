/// Visual stack for FinalOraclySplash — one art + lights + veil.
library;

import 'package:flutter/material.dart';

import 'splash_destination.dart';
import 'splash_final_art.dart';
import 'splash_final_lights.dart';
import 'splash_final_timeline.dart';

class SplashFinalStage extends StatelessWidget {
  const SplashFinalStage({
    super.key,
    required this.t,
    required this.reduced,
    required this.onArtPainted,
    required this.onArtFailed,
  });

  final double t;
  final bool reduced;
  final VoidCallback onArtPainted;
  final VoidCallback onArtFailed;

  @override
  Widget build(BuildContext context) {
    final s = SplashFinalTimeline.smooth;
    final seg = SplashFinalTimeline.segment;
    final reveal = s(seg(t, 0.11, 0.30));
    final emblem = s(seg(t, 0.21, 0.44));
    final stars = s(seg(t, 0.33, 0.57));
    final word = s(seg(t, 0.43, 0.69));
    final beauty = s(seg(t, 0.57, 0.80));
    final exit = s(seg(t, 0.79, 1.0));
    final goldPass = s(seg(t, 0.57, 0.80));
    final imageOpacity = reduced ? 1.0 : (0.92 + 0.08 * reveal);
    final scale = reduced
        ? (1.008 - 0.008 * exit)
        : (1.018 - 0.010 * reveal - 0.008 * exit);
    final overlayOpacity = (1.0 - exit).clamp(0.0, 1.0);
    final lift = -5.0 * word;
    final lowerVeil = (0.28 * (1.0 - word)).clamp(0.0, 0.28);

    return IgnorePointer(
      child: Opacity(
        opacity: overlayOpacity,
        child: ColoredBox(
          color: SplashDestination.midnight,
          child: Transform.translate(
            offset: Offset(0, lift),
            child: Transform.scale(
              scale: scale.clamp(1.0, 1.02),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: imageOpacity.clamp(0.0, 1.0),
                    child: SplashFinalArt(
                      onPainted: onArtPainted,
                      onFailed: onArtFailed,
                    ),
                  ),
                  SplashFinalAtmosphere(strength: reveal * (1 - exit)),
                  SplashFinalLights(
                    emblemGlow: emblem * (0.55 + 0.45 * beauty),
                    starShimmer: reduced ? 0 : stars,
                    goldPass: reduced ? 0 : goldPass,
                    reduced: reduced,
                  ),
                  SplashFinalWordVeil(strength: lowerVeil),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
