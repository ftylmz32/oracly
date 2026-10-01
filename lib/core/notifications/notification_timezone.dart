/// Device-local IANA timezone for the daily notification.
///
/// The device's own zone id (Android ZoneId.systemDefault, iOS
/// NSTimeZone.localTimeZone, via flutter_timezone) is the only source treated
/// as exact. A UTC-offset match is deliberately NOT used: many zones share an
/// offset today and diverge at the next DST change (e.g. Europe/Berlin and
/// Africa/Johannesburg are both +02:00 in summer, but not in winter). When the
/// device id is unavailable or unknown, ORACLY's product default zone is used
/// and the result is marked as a fallback — never presented as the device's.
library;

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

enum NotificationTimezoneSource {
  /// The device reported a valid IANA zone.
  device,

  /// The device zone was unavailable or unknown — product default used.
  fallback,
}

@immutable
class ResolvedNotificationTimezone {
  const ResolvedNotificationTimezone(this.location, this.source);

  final tz.Location location;
  final NotificationTimezoneSource source;

  bool get isExactDeviceZone => source == NotificationTimezoneSource.device;
}

abstract final class NotificationTimezone {
  NotificationTimezone._();

  static const defaultZone = 'Europe/Istanbul';

  /// Requires the timezone database to be initialized.
  static ResolvedNotificationTimezone resolve(String? deviceIanaZone) {
    final name = deviceIanaZone?.trim() ?? '';
    if (name.isNotEmpty) {
      try {
        return ResolvedNotificationTimezone(
          tz.getLocation(name),
          NotificationTimezoneSource.device,
        );
      } catch (_) {
        // Unknown to this tz database version — fall through to fallback.
      }
    }
    return ResolvedNotificationTimezone(
      tz.getLocation(defaultZone),
      NotificationTimezoneSource.fallback,
    );
  }

  /// Next occurrence of [hour]:00 wall-clock time in [location], strictly
  /// after [now]. Built from wall-clock fields, so it stays at [hour] local
  /// time across DST transitions.
  static tz.TZDateTime nextDaily(tz.Location location, int hour, {DateTime? now}) {
    final current = tz.TZDateTime.from(now ?? DateTime.now(), location);
    var next = tz.TZDateTime(
      location,
      current.year,
      current.month,
      current.day,
      hour,
    );
    if (!next.isAfter(current)) {
      next = tz.TZDateTime(
        location,
        current.year,
        current.month,
        current.day + 1,
        hour,
      );
    }
    return next;
  }
}
