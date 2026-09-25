/// Phase 4 — civil local birth clock → UTC via explicit IANA (never device TZ).
library;

import 'package:timezone/timezone.dart' as tz;

import '../models/birth_profile.dart';
import 'birth_instant_resolution.dart';
import 'birth_timezone_database.dart';
import 'natal_calculation_error.dart';

/// Supported natal civil range: 1900-01-01 through today (UTC calendar).
abstract final class NatalSupportedRange {
  NatalSupportedRange._();

  static final DateTime start = DateTime.utc(1900, 1, 1);
  static DateTime get endExclusive {
    final n = DateTime.now().toUtc();
    return DateTime.utc(n.year, n.month, n.day).add(const Duration(days: 1));
  }

  static bool containsCivilDate(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    return !d.isBefore(start) && d.isBefore(endExclusive);
  }
}

abstract final class BirthInstantResolver {
  BirthInstantResolver._();

  static BirthInstantResolution resolve(BirthProfile profile) {
    if (!NatalSupportedRange.containsCivilDate(profile.birthDate)) {
      return const BirthInstantResolution.unsupportedDate();
    }
    final tzId = profile.timezoneId?.trim();
    if (tzId == null || tzId.isEmpty) {
      return const BirthInstantResolution.unavailable();
    }
    if (!profile.hasKnownTime || profile.birthTime == null) {
      return const BirthInstantResolution.unavailable();
    }

    late final tz.Location loc;
    try {
      loc = BirthTimezoneDatabase.locationOf(tzId);
    } catch (_) {
      throw NatalTimezoneInvalidException(tzId);
    }

    final y = profile.birthDate.year;
    final m = profile.birthDate.month;
    final d = profile.birthDate.day;
    final h = profile.birthTime!.hour;
    final min = profile.birthTime!.minute;

    final offsets = _plausibleOffsets(loc, y, m, d);
    final candidates = <DateTime>[];
    for (final offset in offsets) {
      final utc = DateTime.utc(y, m, d, h, min).subtract(offset);
      final back = tz.TZDateTime.from(utc, loc);
      if (back.year == y &&
          back.month == m &&
          back.day == d &&
          back.hour == h &&
          back.minute == min) {
        final key = utc.millisecondsSinceEpoch;
        if (!candidates.any((c) => c.millisecondsSinceEpoch == key)) {
          candidates.add(utc);
        }
      }
    }

    if (candidates.isEmpty) {
      return const BirthInstantResolution.nonexistent();
    }
    if (candidates.length == 1) {
      return BirthInstantResolution.exact(candidates.first);
    }
    return BirthInstantResolution.ambiguous(candidates);
  }

  static Set<Duration> _plausibleOffsets(tz.Location loc, int y, int m, int d) {
    final offsets = <Duration>{};
    final start = DateTime.utc(y, m, d).subtract(const Duration(days: 1));
    for (var i = 0; i < 72; i++) {
      final probe = start.add(Duration(hours: i));
      offsets.add(tz.TZDateTime.from(probe, loc).timeZoneOffset);
    }
    return offsets;
  }
}
