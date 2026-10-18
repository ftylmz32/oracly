/// Debug-only Home daypart. Release builds never read the launch extra.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/universe/oracly_ritual_time.dart';

abstract final class HomeDaypartPreview {
  HomeDaypartPreview._();

  static const _channel = MethodChannel('oracly/debug');

  static OraclyRitualTime? parse(String? raw) => switch (raw) {
        'morning' => OraclyRitualTime.morning,
        'noon' || 'afternoon' => OraclyRitualTime.afternoon,
        'evening' => OraclyRitualTime.evening,
        'night' => OraclyRitualTime.night,
        _ => null,
      };

  /// Fixed local hour inside the existing window. Does not touch the device clock.
  static DateTime momentFor(OraclyRitualTime time, DateTime today) {
    final hour = switch (time) {
      OraclyRitualTime.morning => 8,
      OraclyRitualTime.afternoon => 14,
      OraclyRitualTime.evening => 19,
      OraclyRitualTime.night => 23,
    };
    return DateTime(today.year, today.month, today.day, hour);
  }

  static Future<DateTime?> moment() async {
    if (kReleaseMode) return null;
    try {
      final raw = await _channel.invokeMethod<String>('homeDaypart');
      final time = parse(raw);
      if (time == null) return null;
      return momentFor(time, DateTime.now());
    } catch (_) {
      return null;
    }
  }
}
