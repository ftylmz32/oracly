/// Stable coffee result — continuous story + observed marks only.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/fortune_voice.dart';
import '../../../../core/design_system/chamber_narrative_block.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../copy/coffee_copy.dart';
import '../../models/coffee_reading.dart';
import 'coffee_result_observations.dart';
import 'coffee_result_title.dart';

class CoffeeResultStable extends StatelessWidget {
  const CoffeeResultStable({
    super.key,
    required this.reading,
    this.markKeys = const {},
  });

  final CoffeeReading reading;
  final Map<int, GlobalKey> markKeys;

  @override
  Widget build(BuildContext context) {
    final overall = FortuneVoice.scrub(reading.overall);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CoffeeResultTitle(),
        SizedBox(height: CraftsmanshipRhythm.afterTitle),
        ChamberNarrativeBlock(
          hero: true,
          body: overall.isEmpty ? CoffeeCopy.disclaimer : overall,
        ),
        CoffeeResultObservations(
          symbols: reading.symbols,
          markKeys: markKeys,
        ),
      ],
    );
  }
}
