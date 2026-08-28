/// User-facing Yıldızname insight — never polarity enums or session keys.
library;

import '../../../../core/insight_copy/insight_copy_text.dart';
import '../../models/star_map_reading.dart';
import 'star_map_result_section.dart';

abstract final class StarMapInsightCopy {
  StarMapInsightCopy._();

  static String fromResult({
    required String title,
    required List<StarMapResultSection> sections,
    required List<StarMapPlanetInfluence> planets,
  }) {
    return InsightCopyText.joinBlocks([
      title,
      for (final section in sections) ...[section.title, section.body],
      for (final planet in planets) ...[
        planet.nameTr,
        planet.influence,
        planet.explanation,
      ],
    ]);
  }
}
