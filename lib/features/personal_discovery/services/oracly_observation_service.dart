/// Selects one observational line — recurring themes, anti-repetition, no invention.
library;

import '../copy/daily_observation_copy.dart';
import '../models/cross_discovery_insight.dart';
import '../models/oracly_observation.dart';
import '../models/personal_discovery_profile.dart';
import '../models/personal_insight.dart';
import '../models/surfaced_theme_record.dart';
import 'personal_insight_service.dart';

abstract final class OraclyObservationService {
  OraclyObservationService._();

  static OraclyObservation? resolve(
    PersonalDiscoveryProfile profile, {
    required List<SurfacedThemeRecord> recent,
    required String surface,
    DateTime? now,
  }) {
    if (!profile.hasHistory) return null;
    final clock = now ?? DateTime.now();
    final insight = _selectInsight(
      profile,
      recent: recent,
      surface: surface,
      now: clock,
    );
    if (insight == null) return null;
    final line = DailyObservationCopy.line(insight, now: clock);
    if (line.trim().isEmpty) return null;
    return OraclyObservation(theme: insight.theme, line: line, insight: insight);
  }

  static CrossDiscoveryInsight? _selectInsight(
    PersonalDiscoveryProfile profile, {
    required List<SurfacedThemeRecord> recent,
    required String surface,
    required DateTime now,
  }) {
    for (final crossModalOnly in [true, false]) {
      final picked = PersonalInsightService.fromProfile(
        profile,
        day: now,
        recent: recent,
        surface: surface,
        crossModalOnly: crossModalOnly,
      );
      final insight = _mapFirst(profile, picked);
      if (insight != null) return insight;
    }
    return null;
  }

  static CrossDiscoveryInsight? _mapFirst(
    PersonalDiscoveryProfile profile,
    List<PersonalInsight> picked,
  ) {
    for (final item in picked) {
      for (final insight in profile.crossInsights) {
        if (insight.theme != item.theme) continue;
        final line = DailyObservationCopy.line(insight);
        if (line.trim().isEmpty) continue;
        return insight;
      }
    }
    return null;
  }
}
