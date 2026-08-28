/// Static OR presence disk — brand mark geometry, never a Material sparkle.
library;

import 'package:flutter/material.dart';

import '../../../../core/brand/oracly_brand_mark.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import 'companion_or_atmosphere.dart';
import 'companion_or_presence.dart';
import 'companion_or_thinking_points.dart';

class CompanionOrStaticDisk extends StatelessWidget {
  const CompanionOrStaticDisk({
    super.key,
    required this.size,
    required this.atmosphere,
    required this.glow,
    required this.presence,
    this.phase = 0.5,
  });

  final double size;
  final CompanionOrAtmosphere atmosphere;
  final double glow;
  final CompanionOrPresence presence;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: atmosphere.glow.withValues(alpha: glow),
                  blurRadius: atmosphere.blur,
                  spreadRadius: atmosphere.spread,
                ),
              ],
            ),
            child: OraclyBrandMark(size: size, forLauncher: size <= 40),
          ),
          if (presence == CompanionOrPresence.thinking)
            CompanionOrThinkingPoints(
              size: size,
              phase: phase,
              color: OraclyChrome.goldLight.withValues(alpha: 0.72),
            ),
        ],
      ),
    );
  }
}
