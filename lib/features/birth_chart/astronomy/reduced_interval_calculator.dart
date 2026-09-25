/// Phase 4 — E2 unknown-time local-day interval sampling.
library;

import 'package:timezone/timezone.dart' as tz;

import 'astronomical_ephemeris_port.dart';
import 'astronomical_fact_certainty.dart';
import 'birth_timezone_database.dart';
import 'longitude_math.dart';
import 'natal_body.dart';

class IntervalBodyResult {
  const IntervalBodyResult({
    required this.body,
    required this.certainty,
    this.sign,
  });

  final NatalBody body;
  final AstronomicalFactCertainty certainty;
  final dynamic sign; // ZodiacSignId when stable
}

abstract final class ReducedIntervalCalculator {
  ReducedIntervalCalculator._();

  /// Conservative ≤5-minute samples across the civil local day.
  static const sampleStep = Duration(minutes: 5);

  static List<DateTime> localDayUtcSamples({
    required DateTime birthDate,
    required String timezoneId,
  }) {
    final loc = BirthTimezoneDatabase.locationOf(timezoneId);
    final out = <DateTime>[];
    var cursor = tz.TZDateTime(loc, birthDate.year, birthDate.month, birthDate.day);
    final end = cursor.add(const Duration(days: 1));
    while (cursor.isBefore(end)) {
      out.add(cursor.toUtc());
      cursor = cursor.add(sampleStep);
    }
    // Include final instant just before next midnight if needed.
    final last = end.subtract(const Duration(seconds: 1)).toUtc();
    if (out.isEmpty || out.last != last) out.add(last);
    return out;
  }

  static IntervalBodyResult classifyBody({
    required AstronomicalEphemerisPort ephemeris,
    required NatalBody body,
    required List<DateTime> utcSamples,
  }) {
    if (utcSamples.isEmpty) {
      return IntervalBodyResult(
        body: body,
        certainty: AstronomicalFactCertainty.unavailable,
      );
    }
    final signs = <String>{};
    for (final t in utcSamples) {
      signs.add(LongitudeMath.signOf(ephemeris.longitude(body, t)).name);
    }
    if (signs.length == 1) {
      return IntervalBodyResult(
        body: body,
        certainty: AstronomicalFactCertainty.intervalStable,
        sign: LongitudeMath.signOf(
          ephemeris.longitude(body, utcSamples.first),
        ),
      );
    }
    return IntervalBodyResult(
      body: body,
      certainty: AstronomicalFactCertainty.ambiguous,
    );
  }
}
