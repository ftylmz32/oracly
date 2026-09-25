/// Phase 4 — authoritative JPL Horizons / Meeus fixtures (frozen values).
library;

/// All longitudes: geocentric ecliptic of date, degrees.
/// Source timestamps are UT unless noted.
abstract final class Phase4AstronomicalFixtures {
  Phase4AstronomicalFixtures._();

  /// J2000 epoch: 2000-01-01 12:00:00 UT = JD 2451545.0
  static final DateTime j2000Utc = DateTime.utc(2000, 1, 1, 12);

  /// NASA/JPL Horizons OBSERVER QUANTITIES=31, CENTER=500@399,
  /// START=2000-01-01 12:00, retrieved 2026-09-25.
  static const horizonsJ2000 = <String, double>{
    'sun': 280.3689092,
    'moon': 223.3237860,
    'mercury': 271.8892699,
    'venus': 241.5657794,
    'mars': 327.9632921,
    'jupiter': 25.2530685,
    'saturn': 40.3956366,
    'uranus': 314.8091680,
    'neptune': 303.1930007,
    'pluto': 251.4547644,
  };

  static const horizonsSource =
      'NASA/JPL Horizons API (ssd.jpl.nasa.gov) OBSERVER ObsEcLon';
  static const horizonsRetrieved = '2026-09-25';
  static const horizonsConvention = 'geocentric_ecliptic_of_date_deg';

  /// Meeus AA Ch.25 example: 1992-10-13.0 TD apparent Sun ≈ 199°54′32″
  static final DateTime meeusSunUtc = DateTime.utc(1992, 10, 13);
  static const meeusSunApparentDeg = 199 + 54 / 60 + 32 / 3600;
  static const meeusSunSource =
      'Jean Meeus, Astronomical Algorithms, Ch.25 worked example';

  /// Meeus AA Ch.47 / PyMeeus: 1992-04-12.0 TD Moon mean lon 133.162655°
  static final DateTime meeusMoonUtc = DateTime.utc(1992, 4, 12);
  static const meeusMoonMeanLonDeg = 133.162655;
  static const meeusMoonSource =
      'Jean Meeus, Astronomical Algorithms, Ch.47 / PyMeeus geocentric_ecliptical_pos';

  /// Tolerances (Phase 4 freeze).
  static const sunTolDeg = 0.05;
  static const planetTolDeg = 0.05;
  static const moonTolDeg = 0.10;
  static const angleTolDeg = 0.10;
}
