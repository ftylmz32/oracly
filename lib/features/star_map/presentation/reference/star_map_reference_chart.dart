/// Archive seal — photoreal plate in a brass medallion, never a zodiac wheel.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_soft_reveal.dart';
import 'star_map_archive_plate.dart';
import 'star_map_hero_nebula.dart';
import 'star_map_reference_tokens.dart';
import 'star_map_star_drift.dart';

class StarMapReferenceChart extends StatelessWidget {
  const StarMapReferenceChart({
    super.key,
    required this.diameter,
  });

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final brass = StarMapReferenceTokens.brassGlow;
    final ink = StarMapReferenceTokens.archiveInk;
    final candle = StarMapReferenceTokens.candleAmber;
    return OraclySoftReveal(
      child: Center(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: StarMapStarDrift(
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: StarMapHeroNebula(size: diameter),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: candle.withValues(alpha: 0.16),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: StarMapReferenceTokens.violetSky.withValues(
                          alpha: 0.22,
                        ),
                        blurRadius: 26,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                RepaintBoundary(
                  child: ClipOval(
                    child: StarMapArchivePlate(
                      width: diameter,
                      height: diameter,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: brass.withValues(alpha: 0.46),
                        width: 1.35,
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: brass.withValues(alpha: 0.20),
                          width: 0.7,
                        ),
                        gradient: RadialGradient(
                          colors: [
                            Colors.transparent,
                            ink.withValues(alpha: 0.14),
                            ink.withValues(alpha: 0.40),
                          ],
                          stops: const [0.50, 0.80, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
