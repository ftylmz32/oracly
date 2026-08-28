/// Result chapter — brass rail hierarchy, same archive voice as the hub.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_narrative_block.dart';
import '../../../../core/design_system/chamber_reading_lane.dart';
import 'star_map_archive_separator.dart';
import 'star_map_result_section.dart';

class StarMapResultSectionCard extends StatelessWidget {
  const StarMapResultSectionCard({
    super.key,
    required this.section,
    this.hero = false,
    this.index = 0,
    this.showSeparator = false,
  });

  final StarMapResultSection section;
  final bool hero;
  final int index;
  final bool showSeparator;

  @override
  Widget build(BuildContext context) {
    final child = hero
        ? ChamberNarrativeBlock(
            kicker: section.title,
            body: section.body,
            hero: true,
          )
        : ChamberReadingLane(
            title: section.title,
            body: section.body,
            index: index,
            emphasis: false,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSeparator) const StarMapArchiveSeparator(),
        child,
      ],
    );
  }
}
