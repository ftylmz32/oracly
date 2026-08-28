/// Short symbolic reading under a portrait.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_reading_lane.dart';
import '../../copy/soul_mate_copy.dart';
import '../../data/soul_mate_interpretation_catalogue.dart';

class SoulMateInterpretationBlock extends StatelessWidget {
  const SoulMateInterpretationBlock({super.key, required this.parts});

  final SoulMateReadingParts parts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChamberReadingLane(
          title: SoulMateCopy.energyLabel,
          body: parts.energy,
          index: 0,
          emphasis: true,
        ),
        ChamberReadingLane(
          title: SoulMateCopy.attractionLabel,
          body: parts.attraction,
          index: 1,
        ),
        ChamberReadingLane(
          title: SoulMateCopy.dynamicsLabel,
          body: parts.dynamics,
          index: 2,
        ),
        ChamberReadingLane(
          title: SoulMateCopy.feelingLabel,
          body: parts.feeling,
          index: 3,
        ),
        ChamberReadingLane(
          title: SoulMateCopy.yourSideLabel,
          body: parts.yourSide,
          index: 4,
        ),
      ],
    );
  }
}
