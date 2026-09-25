/// Phase 4 — idempotent historical IANA timezone bootstrap (no setLocalLocation).
library;

import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

abstract final class BirthTimezoneDatabase {
  BirthTimezoneDatabase._();

  static bool _ready = false;
  static const label = 'iana_latest_all';

  static void ensureInitialized() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  static tz.Location locationOf(String timezoneId) {
    ensureInitialized();
    try {
      return tz.getLocation(timezoneId);
    } catch (_) {
      throw StateError('invalid_timezone:$timezoneId');
    }
  }
}
