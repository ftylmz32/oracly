/// Role-aware result section — summary / chapter / reflection / closing.
///
/// Treatment comes from [StarMapResultSection.role], never title strings.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_narrative_block.dart';
import '../../../../core/design_system/chamber_reading_lane.dart';
import '../../../../core/design_system/chamber_story_panel.dart';
import '../../result/yildizname_result_types.dart';
import 'star_map_archive_separator.dart';
import 'star_map_result_closing.dart';
import 'star_map_result_section.dart';

class StarMapResultSectionCard extends StatelessWidget {
  const StarMapResultSectionCard({
    super.key,
    required this.section,
    this.index = 0,
    this.showSeparator = false,
    this.legacyHero = false,
    this.forensicFlat = false,
  });

  final StarMapResultSection section;
  final int index;
  final bool showSeparator;

  /// Legacy leaves lack a summary role — first chapter may carry hero weight.
  final bool legacyHero;

  /// Phase 7C forensic freeze — treat reflection/closing as reading lanes.
  final bool forensicFlat;

  @override
  Widget build(BuildContext context) {
    final role = forensicFlat &&
            (section.role == YildiznameSectionRole.reflection ||
                section.role == YildiznameSectionRole.closing)
        ? YildiznameSectionRole.chapter
        : section.role;
    final child = switch (role) {
      YildiznameSectionRole.summary => ChamberNarrativeBlock(
          kicker: section.title,
          body: section.body,
          hero: true,
        ),
      YildiznameSectionRole.chapter => legacyHero
          ? ChamberNarrativeBlock(
              kicker: section.title,
              body: section.body,
              hero: true,
            )
          : ChamberReadingLane(
              title: section.title,
              body: section.body,
              index: index,
            ),
      YildiznameSectionRole.reflection => ChamberStoryPanel(
          title: section.title,
          body: section.body,
        ),
      YildiznameSectionRole.closing => StarMapResultClosing(
          title: section.title,
          body: section.body,
        ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSeparator) const StarMapArchiveSeparator(),
        child,
      ],
    );
  }
}
