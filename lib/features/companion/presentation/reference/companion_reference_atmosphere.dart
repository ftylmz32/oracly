/// OR chamber sky — warm candle pool + soft personality wash.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';
import 'companion_or_atmosphere.dart';
import 'companion_or_chamber_geometry.dart';
import 'companion_or_presence.dart';
import 'companion_or_visual.dart';
import '../../../premium/models/personalization_models.dart';

class CompanionReferenceAtmosphere extends StatelessWidget {
  const CompanionReferenceAtmosphere({
    super.key,
    required this.child,
    this.personality,
    this.presence,
  });

  final Widget child;
  final AiPersonality? personality;
  final CompanionOrPresence? presence;

  @override
  Widget build(BuildContext context) {
    final visual = CompanionOrVisual.maybeOf(context);
    final atmosphere = CompanionOrAtmosphere.of(
      personality ?? visual?.personality ?? AiPersonality.mystical,
      presence ?? visual?.presence ?? CompanionOrPresence.idle,
    );
    return OraclyCosmicBackground(
      heroGlow: false,
      showStars: false,
      showDust: atmosphere.showDust && presence != CompanionOrPresence.idle,
      showNebula: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF050208)),
            ),
          ),
          const CompanionOrChamberGeometry(),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.22),
                  radius: 0.72,
                  colors: [
                    OraclyChrome.violet.withValues(alpha: 0.09),
                    const Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.78),
                  radius: 0.58,
                  colors: [
                    atmosphere.glow.withValues(alpha: atmosphere.wash * 0.65),
                    const Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          // Intimate candle warmth near the composer — never a neon wash.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 1.05),
                  radius: 0.72,
                  colors: [
                    OraclyChrome.amber.withValues(alpha: 0.045),
                    OraclyChrome.gold.withValues(alpha: 0.022),
                    const Color(0x00000000),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Soft cosmic violet pool behind the reading column.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.12),
                  radius: 0.92,
                  colors: [
                    OraclyChrome.violet.withValues(alpha: 0.055),
                    const Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.34),
                    const Color(0x00000000),
                    const Color(0x00000000),
                    Colors.black.withValues(alpha: 0.42),
                  ],
                  stops: const [0.0, 0.14, 0.86, 1.0],
                ),
              ),
            ),
          ),
          OraclyChamberVeil(child: child),
        ],
      ),
    );
  }
}
