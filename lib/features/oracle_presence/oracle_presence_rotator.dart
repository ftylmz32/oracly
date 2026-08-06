/// OR-436 — Natural observation rotation — rarely repeats.
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'oracle_observation_catalog.dart';
import 'oracle_presence_venue.dart';

/// Picks atmospheric lines without providers — local persistence only.
abstract final class OraclePresenceRotator {
  OraclePresenceRotator._();

  static const _recentKeyPrefix = 'oracle_recent_v1';
  static const _maxRecent = 28;

  /// Stable for the day on [OraclePresenceVenue.home]; shifts gently on tarot.
  static Future<String> current(OraclePresenceVenue venue) async {
    final pool = OracleObservationCatalog.poolFor(venue);
    if (pool.isEmpty) return '';

    final prefs = await SharedPreferences.getInstance();
    final recentKey = '$_recentKeyPrefix.${venue.name}';
    final recentRaw = prefs.getStringList(recentKey) ?? [];
    final recent = recentRaw.map(int.tryParse).whereType<int>().toList();

    var available = List<int>.generate(pool.length, (i) => i)
        .where((i) => !recent.contains(i))
        .toList();
    if (available.isEmpty) {
      available = List<int>.generate(pool.length, (i) => i);
      await prefs.remove(recentKey);
    }

    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch ~/
        86400000;
    final seed = switch (venue) {
      OraclePresenceVenue.home => day,
      OraclePresenceVenue.tarot => day * 37 + now.hour * 3 + venue.index,
    };

    final index = available[seed.abs() % available.length];

    final trimmed = [...recent, index];
    if (trimmed.length > _maxRecent) {
      trimmed.removeRange(0, trimmed.length - _maxRecent);
    }
    await prefs.setStringList(
      recentKey,
      trimmed.map((e) => e.toString()).toList(),
    );

    return pool[index];
  }

  /// Deterministic pick for tests — no persistence.
  static String peek({
    required OraclePresenceVenue venue,
    required int day,
    int hour = 12,
    List<int> exclude = const [],
  }) {
    final pool = OracleObservationCatalog.poolFor(venue);
    var available = List<int>.generate(pool.length, (i) => i)
        .where((i) => !exclude.contains(i))
        .toList();
    if (available.isEmpty) {
      available = List<int>.generate(pool.length, (i) => i);
    }
    final seed = switch (venue) {
      OraclePresenceVenue.home => day,
      OraclePresenceVenue.tarot => day * 37 + hour * 3 + venue.index,
    };
    return pool[available[seed.abs() % available.length]];
  }
}
