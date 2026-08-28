/// Archive chapters under the celestial wheel — real history copy only.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_ornament_heading.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../copy/star_map_polish_copy.dart';
import '../../models/star_map_reading.dart';
import '../../services/star_map_personalization.dart';
import 'star_map_archive_chapter.dart';
import 'star_map_archive_separator.dart';

class StarMapReferenceThemes extends StatelessWidget {
  const StarMapReferenceThemes({
    super.key,
    required this.reading,
  });

  final StarMapReading reading;

  @override
  Widget build(BuildContext context) {
    final sections = StarMapPersonalization.innerThemeSections(reading);
    final last = sections.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChamberOrnamentHeading(label: StarMapPolishCopy.toldToday),
        SizedBox(height: CraftsmanshipRhythm.afterTitle),
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const StarMapArchiveSeparator(),
          StarMapArchiveChapter(
            title: sections[i].title,
            body: sections[i].body,
            index: i,
            emphasis: i == 0 || i == last,
          ),
        ],
      ],
    );
  }
}
