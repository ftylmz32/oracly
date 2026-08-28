/// One optional daily observation from real discovery evidence only.
library;

import '../copy/daily_observation_copy.dart';
import '../data/daily_personal_observation_store.dart';
import '../models/cross_discovery_insight.dart';
import '../models/daily_personal_observation_record.dart';
import '../models/oracly_observation.dart';
import '../models/personal_discovery_profile.dart';
import '../models/surfaced_theme_record.dart';
import 'oracly_observation_service.dart';

abstract final class DailyPersonalObservationService {
  DailyPersonalObservationService._();

  static OraclyObservation? resolve(
    PersonalDiscoveryProfile profile, {
    required DailyPersonalObservationStore store,
    required List<SurfacedThemeRecord> recent,
    required String surface,
    DateTime? now,
  }) {
    if (!profile.hasHistory) return null;
    final clock = now ?? DateTime.now();
    final fingerprint = _fingerprint(profile);
    if (fingerprint.isEmpty) return null;

    final dateKey = _dateKey(clock);
    final cached = store.read();
    if (cached != null &&
        cached.dateKey == dateKey &&
        cached.evidenceFingerprint == fingerprint) {
      return _fromCache(cached, profile);
    }

    final extended = List<SurfacedThemeRecord>.from(recent);
    var variant = 0;
    if (cached != null && cached.evidenceFingerprint == fingerprint) {
      extended.add(
        SurfacedThemeRecord(
          theme: cached.theme,
          surface: 'daily',
          at: clock.subtract(const Duration(hours: 6)),
        ),
      );
      variant = cached.variant + 1;
    }

    final picked = OraclyObservationService.resolve(
      profile,
      recent: extended,
      surface: surface,
      now: clock,
    );
    if (picked == null) {
      if (cached != null && cached.evidenceFingerprint == fingerprint) {
        final rotated = _rotateCached(cached, profile, variant, clock);
        if (rotated != null) {
          store.writeNow(
            DailyPersonalObservationRecord(
              dateKey: dateKey,
              evidenceFingerprint: fingerprint,
              theme: rotated.theme,
              line: rotated.line,
              variant: variant,
            ),
          );
        }
        return rotated;
      }
      return null;
    }

    final line = DailyObservationCopy.line(
      picked.insight,
      now: clock,
      variant: variant,
    );
    if (line.trim().isEmpty) return null;

    store.writeNow(
      DailyPersonalObservationRecord(
        dateKey: dateKey,
        evidenceFingerprint: fingerprint,
        theme: picked.theme,
        line: line,
        variant: variant,
      ),
    );
    return OraclyObservation(
      theme: picked.theme,
      line: line,
      insight: picked.insight,
    );
  }

  static String _fingerprint(PersonalDiscoveryProfile profile) {
    final parts = [
      for (final i in profile.crossInsights.where((i) => i.isRecurring))
        '${i.theme}:${i.discoveryCount}:${i.sourceCount}:'
        '${i.lastObserved.toIso8601String()}',
    ]..sort();
    return parts.join('|');
  }

  static String _dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static OraclyObservation? _fromCache(
    DailyPersonalObservationRecord cached,
    PersonalDiscoveryProfile profile,
  ) {
    final insight = _insightFor(profile, cached.theme);
    if (insight == null) return null;
    return OraclyObservation(
      theme: cached.theme,
      line: cached.line,
      insight: insight,
    );
  }

  static OraclyObservation? _rotateCached(
    DailyPersonalObservationRecord cached,
    PersonalDiscoveryProfile profile,
    int variant,
    DateTime now,
  ) {
    final insight = _insightFor(profile, cached.theme);
    if (insight == null) return null;
    final line = DailyObservationCopy.line(insight, now: now, variant: variant);
    if (line.trim().isEmpty) return null;
    return OraclyObservation(theme: cached.theme, line: line, insight: insight);
  }

  static CrossDiscoveryInsight? _insightFor(
    PersonalDiscoveryProfile profile,
    String theme,
  ) {
    for (final item in profile.crossInsights) {
      if (item.theme == theme && item.isRecurring) return item;
    }
    return null;
  }
}
