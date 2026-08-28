/// Planet influence — reading lane, not a postcard.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_reading_lane.dart';
import '../../models/star_map_reading.dart';

class StarMapReferencePlanetCard extends StatelessWidget {
  const StarMapReferencePlanetCard({
    super.key,
    required this.planet,
  });

  final StarMapPlanetInfluence planet;

  @override
  Widget build(BuildContext context) {
    return ChamberReadingLane(
      title: planet.nameTr,
      body: [
        planet.influence.trim(),
        planet.explanation.trim(),
      ].where((part) => part.isNotEmpty).join('\n\n'),
    );
  }
}
