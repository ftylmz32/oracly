/// Continuous coffee story — cup hero, then narrative, then real marks.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/fortune_voice.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/chamber_narrative_block.dart';
import '../../../../core/design_system/chamber_reading_lane.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../copy/coffee_copy.dart';
import '../../data/coffee_symbol_lexicon.dart';
import '../../models/coffee_reading.dart';
import 'coffee_result_observations.dart';
import 'coffee_result_separator.dart';
import 'coffee_result_title.dart';

class CoffeeResultSections extends StatelessWidget {
  const CoffeeResultSections({
    super.key,
    required this.reading,
    this.markKeys = const {},
  });

  final CoffeeReading reading;
  final Map<int, GlobalKey> markKeys;

  @override
  Widget build(BuildContext context) {
    final overall = FortuneVoice.scrub(reading.overall);
    final seen = FortuneVoice.scrub(reading.visualObservation);
    final showSeen = seen.length >= 24 &&
        (overall.isEmpty ||
            !overall.toLowerCase().contains(
                  seen.toLowerCase().substring(0, seen.length < 18 ? seen.length : 18),
                ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CoffeeResultTitle(),
        SizedBox(height: CraftsmanshipRhythm.afterTitle),
        if (showSeen) ...[
          ChamberNarrativeBlock(body: seen),
          SizedBox(height: CraftsmanshipRhythm.betweenSections),
        ],
        ChamberNarrativeBlock(
          hero: true,
          body: overall.isEmpty ? CoffeeCopy.disclaimer : overall,
        ),
        CoffeeResultObservations(
          symbols: reading.symbols,
          markKeys: markKeys,
        ),
        const CoffeeResultSeparator(),
        _lane(0, CoffeeCopy.loveTitle, reading.love),
        _lane(1, CoffeeCopy.careerTitle, reading.career),
        _lane(2, _nearTitle(), reading.nearFuture),
        _lane(3, CoffeeCopy.cautionTitle, reading.takeaway, emphasis: true),
        SizedBox(height: AppSpacing.s8),
      ],
    );
  }

  String _nearTitle() {
    final ids = {
      for (final sense in CoffeeSymbolLexicon.presentIn(
        names: reading.symbols
            .where((s) => s.trust.isFirm)
            .map((s) => s.name),
      ))
        sense.id,
    };
    if (ids.contains('road')) return CoffeeCopy.pathTitle;
    return CoffeeCopy.newsTitle;
  }

  Widget _lane(
    int index,
    String title,
    String source, {
    bool emphasis = false,
  }) {
    final body = FortuneVoice.scrub(source);
    if (body.isEmpty || FortuneVoice.looksRobotic(source)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: CraftsmanshipRhythm.betweenSections),
      child: ChamberReadingLane(
        title: title,
        body: body,
        index: index,
        emphasis: emphasis,
      ),
    );
  }
}
