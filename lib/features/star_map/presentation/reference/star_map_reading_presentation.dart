/// Presentation bodies for Yıldızname — never invents natal fields.
library;

import '../../../personal_discovery/copy/personal_theme_copy.dart';
import '../../models/star_map_reading.dart';
import '../../services/star_map_archive_story.dart';

abstract final class StarMapReadingPresentation {
  StarMapReadingPresentation._();

  static String sunBody(StarMapReading reading) {
    return reading.overview.mainMessage.trim();
  }

  static String innerBody(StarMapReading reading) {
    return StarMapArchiveStory.knot(reading, seed: _seed(reading) + 2);
  }

  static String todayBody(StarMapReading reading) {
    final today = reading.skyMessage.today.trim();
    if (today.isEmpty) return reading.overview.mainMessage.trim();
    return today;
  }

  static String journeyBody(StarMapReading reading) {
    return StarMapArchiveStory.recent(reading, seed: _seed(reading) + 3);
  }

  static String thresholdBody(StarMapReading reading) {
    return StarMapArchiveStory.threshold(reading, seed: _seed(reading) + 4);
  }

  static String questionBody(StarMapReading reading) {
    return StarMapArchiveStory.leaveQuestion(reading, seed: _seed(reading) + 5);
  }

  static bool isInsufficient(String line) {
    return line.trim().isEmpty || line == PersonalThemeCopy.insufficient;
  }

  static int _seed(StarMapReading reading) {
    return (reading.sunLabel?.length ?? 0) +
        reading.overview.mainMessage.length +
        reading.todayReflection.length;
  }
}
