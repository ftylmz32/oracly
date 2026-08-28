/// OR-004.4 / OR-026 / EPIC-024 — Daily energy hero artwork slot.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/hero_art/hero_art.dart';

/// Compact dream-portal artwork for daily energy cards.
class EnergyIllustration extends StatelessWidget {
  const EnergyIllustration({super.key});

  static const double _minSlotHeight = 148;
  static const double _fallbackSlotWidth = 112;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : _fallbackSlotWidth;
        final slotHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : _minSlotHeight;
        final artSize = (slotHeight * 1.05).clamp(120.0, 168.0);

        return SizedBox(
          width: slotWidth,
          height: slotHeight,
          child: Align(
            alignment: Alignment.centerRight,
            child: HeroDream(size: artSize),
          ),
        );
      },
    );
  }
}
