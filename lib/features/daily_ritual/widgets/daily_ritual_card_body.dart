/// Daily ritual card — full-bleed cinematic hero, copy over dark left sky.
library;

import 'package:flutter/material.dart';

import '../../../core/universe/oracly_universe_state.dart';
import 'daily_ritual_hero_atmosphere.dart';
import 'daily_ritual_hero_copy.dart';
import 'daily_ritual_hero_plate.dart';
import 'daily_ritual_hero_text_scrim.dart';

class DailyRitualCardBody extends StatelessWidget {
  const DailyRitualCardBody({
    super.key,
    required this.universe,
    required this.body,
    required this.art,
    required this.energySize,
    required this.cardDrawn,
    required this.onDraw,
  });

  final OraclyUniverseState universe;
  final String body;
  final double art;
  final double energySize;
  final bool cardDrawn;
  final VoidCallback? onDraw;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 128;
        final textPad = EdgeInsets.fromLTRB(
          14,
          compact ? 8 : 10,
          14,
          compact ? 8 : 10,
        );
        final slotW = constraints.maxWidth;
        final slotH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : compact
                ? 106.0
                : 122.0;

        return SizedBox(
          width: slotW,
          height: slotH,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: DailyRitualHeroPlate(
                    width: slotW,
                    height: slotH,
                    fallbackArt: art,
                  ),
                ),
              ),
              const Positioned.fill(child: DailyRitualHeroAtmosphere()),
              // Scrim + copy stay static — never ride image drift.
              const Positioned.fill(child: DailyRitualHeroTextScrim()),
              Padding(
                padding: textPad,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: slotW * 0.54,
                    height: slotH - textPad.vertical,
                    child: DailyRitualHeroCopy(
                      universe: universe,
                      body: body,
                      energySize: energySize,
                      cardDrawn: cardDrawn,
                      onDraw: onDraw,
                      compact: compact,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
