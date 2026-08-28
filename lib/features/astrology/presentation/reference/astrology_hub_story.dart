/// One editorial daily story under a gold chapter line.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_narrative_block.dart';
import '../../../../core/design_system/chamber_ornament_heading.dart';
import '../../copy/astrology_presentation_copy.dart';
import '../../models/astrology_daily_reading.dart';
import 'astrology_reading_presentation.dart';

class AstrologyHubStory extends StatelessWidget {
  const AstrologyHubStory({super.key, required this.reading});

  final AstrologyDailyReading reading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChamberOrnamentHeading(label: AstrologyPresentationCopy.todayAsk),
        ChamberNarrativeBlock(
          hero: true,
          align: TextAlign.center,
          body: AstrologyReadingPresentation.storyBody(reading),
        ),
      ],
    );
  }
}
