/// Story first, then gold-rail asides from lines the image actually showed.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/fortune_voice.dart';
import '../../../core/design_system/chamber_narrative_block.dart';
import '../../../core/design_system/chamber_reading_lane.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../copy/palm_copy.dart';
import '../data/palm_observation.dart';
import '../models/palm_reading.dart';
import 'palm_result_separator.dart';
import 'palm_result_title.dart';

class PalmResultSections extends StatelessWidget {
  const PalmResultSections({super.key, required this.reading});

  final PalmReading reading;

  @override
  Widget build(BuildContext context) {
    final overall = FortuneVoice.scrub(reading.overall);
    final marks = PalmObservation.marks(reading.symbols);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PalmResultTitle(hand: reading.hand),
        SizedBox(height: CraftsmanshipRhythm.afterTitle),
        ChamberNarrativeBlock(hero: true, body: overall),
        const PalmResultSeparator(),
        _lane(0, PalmCopy.heartTitle, PalmObservation.line(reading.heartLine)),
        _lane(1, PalmCopy.headTitle, PalmObservation.line(reading.headLine)),
        _lane(2, PalmCopy.lifeTitle, PalmObservation.line(reading.lifeLine)),
        _lane(3, PalmCopy.fateTitle, PalmObservation.line(reading.fateLine)),
        if (reading.takeaway.trim().isNotEmpty)
          _lane(
            4,
            PalmCopy.takeawayTitle,
            reading.takeaway,
            emphasis: true,
          ),
        if (marks.isNotEmpty)
          _lane(5, PalmCopy.symbolsTitle, marks.join(' · '), emphasis: true),
        if (reading.themes.isNotEmpty)
          _lane(6, PalmCopy.themesTitle, reading.themes.join(' · ')),
      ],
    );
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
      padding: EdgeInsets.only(top: CraftsmanshipRhythm.betweenSections * 0.55),
      child: ChamberReadingLane(
        title: title,
        body: body,
        index: index,
        emphasis: emphasis,
      ),
    );
  }
}
