/// Builds today's Yıldızname reading from calendar day + optional sun sign.
library;

import '../../birth_chart/models/zodiac_sign_id.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../data/star_map_copy.dart';
import '../models/star_map_reading.dart';
import '../services/star_map_insight_locale.dart';
import 'star_map_personalization.dart';

abstract final class StarMapReadingService {
  StarMapReadingService._();

  static StarMapReading build({
    DateTime? now,
    ZodiacSignId? sunSign,
    PersonalDiscoveryProfile? discovery,
  }) {
    final day = now ?? DateTime.now();
    final tone = _tone(day, sunSign);
    final karmicTheme = (day.year + day.month * 13 + day.day) % 6;
    final signLabel =
        sunSign == null ? null : StarMapInsightLocale.signName(sunSign);
    final base = StarMapReading(
      overview: StarMapCopy.overview(tone, sunLabel: signLabel),
      skyMessage: StarMapCopy.skyMessage(tone, sunLabel: signLabel),
      karmic: StarMapCopy.karmic(karmicTheme),
      planets: StarMapCopy.planets(tone),
      isPersonalized: sunSign != null,
      sunLabel: signLabel,
    );
    return StarMapPersonalization.overlay(
      base: base,
      discovery: discovery,
      day: day,
    );
  }

  static int _tone(DateTime day, ZodiacSignId? sunSign) {
    final sign = sunSign?.index ?? 0;
    return (day.year * 17 + day.month * 29 + day.day + sign * 13) % 3;
  }
}
