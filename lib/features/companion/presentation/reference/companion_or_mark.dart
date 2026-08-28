/// Compact OR monogram — presence through glow, never a mascot.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/oracly_quiet_motion.dart';
import 'companion_or_living_disk.dart';
import 'companion_or_presence.dart';
import 'companion_or_static_disk.dart';
import 'companion_or_visual.dart';

class CompanionOrMark extends StatelessWidget {
  const CompanionOrMark({
    super.key,
    required this.size,
    this.breathe = false,
    this.presence,
  });

  final double size;
  final bool breathe;
  final CompanionOrPresence? presence;

  @override
  Widget build(BuildContext context) {
    final resolved = presence ?? CompanionOrVisual.presenceOf(context);
    final atmosphere = CompanionOrVisual.atmosphereOf(context);
    final live = breathe &&
        resolved != CompanionOrPresence.error &&
        !OraclyQuietMotion.still(context) &&
        atmosphere.glowSpan > 0;

    if (!live) {
      return CompanionOrStaticDisk(
        size: size,
        atmosphere: atmosphere,
        glow: atmosphere.glowMin + atmosphere.glowSpan * 0.5,
        presence: resolved,
      );
    }
    return CompanionOrLivingDisk(
      size: size,
      atmosphere: atmosphere,
      presence: resolved,
    );
  }
}
