/// Daily ritual card — daypart plate, copy along the lower edge.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_reduced_motion.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../../home/theme/home_ritual_plates.dart';
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
    final plate = HomeRitualPlates.of(universe.ritualTime);
    final focus = HomeRitualPlates.focus(universe.ritualTime);
    final fade = OraclyReducedMotion.duration(
      context,
      const Duration(milliseconds: 480),
    );
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
                  child: AnimatedSwitcher(
                    duration: fade,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: DailyRitualHeroPlate(
                      key: ValueKey(plate),
                      width: slotW,
                      height: slotH,
                      fallbackArt: art,
                      assetPath: plate,
                      alignment: focus,
                    ),
                  ),
                ),
              ),
              const Positioned.fill(child: DailyRitualHeroAtmosphere()),
              const Positioned.fill(child: DailyRitualHeroTextScrim()),
              Padding(
                padding: textPad,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                    width: slotW * 0.66,
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
