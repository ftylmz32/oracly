/// EPIC-005 — Rare ambient events — infrequent delight, never distraction.
library;

import 'oracly_ritual_time.dart';

/// A quiet moment in the observatory — at most one per day.
enum OraclyLivingEventKind {
  shootingStar,
  distantGlow,
  shiftingConstellation,
  goldenReflection,
}

/// Resolved ambient event for the current day, if any.
class OraclyLivingEvent {
  const OraclyLivingEvent({
    required this.kind,
    required this.seed,
    required this.intensity,
  });

  final OraclyLivingEventKind kind;
  final int seed;
  final double intensity;

  /// ~14% of days carry a rare event; kind respects ritual time.
  static OraclyLivingEvent? resolve(DateTime moment) {
    final dayKey = moment.year * 10000 + moment.month * 100 + moment.day;
    final hash = _stableHash(dayKey);
    if (hash % 7 != 0) return null;

    final ritual = OraclyRitualAtmosphere.fromHour(moment.hour);
    final candidates = _candidatesFor(ritual);
    if (candidates.isEmpty) return null;

    final kind = candidates[hash % candidates.length];
    final intensity = 0.72 + (hash % 29) / 100.0;

    return OraclyLivingEvent(
      kind: kind,
      seed: hash,
      intensity: intensity.clamp(0.72, 0.98),
    );
  }

  static List<OraclyLivingEventKind> _candidatesFor(OraclyRitualTime ritual) =>
      switch (ritual) {
        OraclyRitualTime.morning => [
            OraclyLivingEventKind.goldenReflection,
            OraclyLivingEventKind.shiftingConstellation,
          ],
        OraclyRitualTime.afternoon => [
            OraclyLivingEventKind.shiftingConstellation,
          ],
        OraclyRitualTime.evening => [
            OraclyLivingEventKind.shootingStar,
            OraclyLivingEventKind.goldenReflection,
            OraclyLivingEventKind.shiftingConstellation,
          ],
        OraclyRitualTime.night => [
            OraclyLivingEventKind.shootingStar,
            OraclyLivingEventKind.distantGlow,
            OraclyLivingEventKind.shiftingConstellation,
          ],
      };

  static int _stableHash(int value) {
    var h = value ^ 0x9e3779b9;
    h = (h ^ (h >> 16)) * 0x85ebca6b;
    h = (h ^ (h >> 13)) * 0xc2b2ae35;
    return (h ^ (h >> 16)) & 0x7fffffff;
  }
}
