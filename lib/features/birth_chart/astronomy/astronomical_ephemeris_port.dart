/// Phase 4 — swappable ephemeris port (no BirthChart coupling).
library;

import 'natal_body.dart';

abstract class AstronomicalEphemerisPort {
  /// Apparent geocentric ecliptic longitude of date, degrees `[0,360)`.
  double longitude(NatalBody body, DateTime utc);

  /// Apparent Greenwich sidereal time in radians `[0, 2π)`.
  double apparentSiderealTime(DateTime utc);

  /// True obliquity of date (mean + nutation), radians.
  double trueObliquity(DateTime utc);

  String get engineId;
  String get engineVersion;
}
