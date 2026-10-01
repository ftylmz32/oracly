/// Device-local timezone for the daily notification, without a native plugin.
///
/// The previous code always used Europe/Istanbul, so a device elsewhere got
/// the daily invitation at the wrong local hour. The schedule is re-applied
/// on every start, so a zone that only matches the current offset (e.g.
/// across a DST change) self-corrects on the next launch.
library;

import 'package:timezone/timezone.dart' as tz;

abstract final class NotificationTimezone {
  NotificationTimezone._();

  static const defaultZone = 'Europe/Istanbul';

  /// Picks the IANA location to schedule in. Order:
  /// 1. the device-reported zone name when it is a real IANA name,
  /// 2. Europe/Istanbul when its current offset equals the device offset,
  /// 3. the first IANA location (sorted, deterministic) with that offset,
  /// 4. Europe/Istanbul as a last resort.
  /// Requires the timezone database to be initialized.
  static tz.Location resolve({
    required String deviceZoneName,
    required Duration deviceOffset,
    required DateTime nowUtc,
  }) {
    final named = _tryLocation(deviceZoneName.trim());
    if (named != null && _offsetAt(named, nowUtc) == deviceOffset) {
      return named;
    }
    final istanbul = tz.getLocation(defaultZone);
    if (_offsetAt(istanbul, nowUtc) == deviceOffset) return istanbul;

    final names = tz.timeZoneDatabase.locations.keys.toList()..sort();
    for (final name in names) {
      final location = tz.timeZoneDatabase.locations[name]!;
      if (_offsetAt(location, nowUtc) == deviceOffset) return location;
    }
    return istanbul;
  }

  static tz.Location? _tryLocation(String name) {
    if (name.isEmpty || !name.contains('/')) return null;
    try {
      return tz.getLocation(name);
    } catch (_) {
      return null;
    }
  }

  static Duration _offsetAt(tz.Location location, DateTime nowUtc) {
    return location.timeZone(nowUtc.millisecondsSinceEpoch).offset;
  }

  /// Next occurrence of [hour]:00 in [location], strictly after [now].
  static tz.TZDateTime nextDaily(tz.Location location, int hour, {DateTime? now}) {
    final current = tz.TZDateTime.from(now ?? DateTime.now(), location);
    var next = tz.TZDateTime(
      location,
      current.year,
      current.month,
      current.day,
      hour,
    );
    if (!next.isAfter(current)) next = next.add(const Duration(days: 1));
    return next;
  }
}
