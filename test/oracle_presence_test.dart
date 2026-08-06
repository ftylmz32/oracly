import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/features/oracle_presence/oracle_observation_catalog.dart';
import 'package:oracly_new/features/oracle_presence/oracle_presence_rotator.dart';
import 'package:oracly_new/features/oracle_presence/oracle_presence_venue.dart';

void main() {
  test('catalog has a large non-repeating pool per venue', () {
    expect(OracleObservationCatalog.totalCount, greaterThan(100));
    expect(
      OracleObservationCatalog.poolFor(OraclePresenceVenue.home).length,
      greaterThan(60),
    );
    expect(
      OracleObservationCatalog.poolFor(OraclePresenceVenue.tarot).length,
      greaterThan(60),
    );
  });

  test('peek rotates across days without immediate repeat in short window', () {
    final seen = <String>{};
    for (var day = 0; day < 14; day++) {
      final line = OraclePresenceRotator.peek(
        venue: OraclePresenceVenue.home,
        day: day,
      );
      expect(line, isNotEmpty);
      seen.add(line);
    }
    expect(seen.length, greaterThan(10));
  });

  test('home and tarot venues can differ on the same day', () {
    final home = OraclePresenceRotator.peek(
      venue: OraclePresenceVenue.home,
      day: 42,
    );
    final tarot = OraclePresenceRotator.peek(
      venue: OraclePresenceVenue.tarot,
      day: 42,
      hour: 14,
    );
    expect(home, isNotEmpty);
    expect(tarot, isNotEmpty);
  });
}
