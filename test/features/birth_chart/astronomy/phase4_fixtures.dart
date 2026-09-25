/// Phase 4 / 4.1 — authoritative external fixtures (frozen values).
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

  // --- Phase 4.1 independent Asc / MC numeric fixtures ---

  /// Chicago preferred Asc fixture (Phase 4.1 gate / independent review).
  /// UTC 1990-07-14T08:20:00Z · lat 41.85 · lon −87.65 · Asc ≈ 82.562°.
  static final DateTime chicagoAscUtc = DateTime.utc(1990, 7, 14, 8, 20);
  static const chicagoLat = 41.85;
  static const chicagoLon = -87.65;
  static const chicagoExpectedAsc = 82.562;
  static const chicagoAscSource =
      'Phase 4.1 independent validation gate preferred fixture '
      '(UTC/lat/lon/Asc published); independent astronomy-engine class';

  /// São Paulo southern Asc+MC — J-Kit / astronomy-engine worked example.
  /// Local 2000-07-15 09:30 (UTC−3) = 12:30 UTC.
  static final DateTime saoPauloUtc = DateTime.utc(2000, 7, 15, 12, 30);
  static const saoPauloLat = -23.55;
  static const saoPauloLon = -46.63;
  static const saoPauloExpectedAsc = 159.44;
  static const saoPauloExpectedMc = 75.76;
  static const saoPauloRamc = 74.53;
  static const saoPauloSource =
      'https://jkit.tools/en/articles/how-a-birth-chart-is-calculated '
      '(astronomy-engine / VSOP87; published 2026-07-09)';

  /// Enschede MC (+Asc cross-check) — RadixPro worked example.
  static final DateTime enschedeUtc = DateTime.utc(2016, 11, 2, 21, 17, 30);
  static const enschedeLat = 52 + 13 / 60;
  static const enschedeLon = 6.9;
  static const enschedeExpectedAsc = 123.5079833456672618;
  static const enschedeExpectedMc = 9.62989868323;
  static const enschedeRamc = 8.8485279795;
  static const enschedeAscSource =
      'https://radixpro.com/a4a-start/the-ascendant/ (retrieved 2026-09-25)';
  static const enschedeMcSource =
      'https://radixpro.com/a4a-start/medium-coeli/ (retrieved 2026-09-25)';

  /// Greenwich geometric sunrise sanity (Asc ≈ Sun).
  static final DateTime greenwichSunriseUtc = DateTime.utc(2000, 3, 20, 6, 7);
  static const greenwichSunriseLat = 51.5;
  static const greenwichSunriseLon = 0.0;
  static const sunriseAscSunTolDeg = 2.0;

  // --- Phase 4.1 retrograde Horizons T±12h (retrieved 2026-09-25) ---

  static final DateTime mercuryRetroUtc = DateTime.utc(2023, 8, 30, 12);
  static const mercuryRetroTm12 = 169.9930352;
  static const mercuryRetroT = 169.6801019;
  static const mercuryRetroTp12 = 169.3447391;

  static final DateTime mercuryDirectUtc = DateTime.utc(2024, 1, 15, 12);
  static const mercuryDirectTm12 = 270.9702279;
  static const mercuryDirectT = 271.5339956;
  static const mercuryDirectTp12 = 272.1072105;

  static final DateTime jupiterRetroUtc = DateTime.utc(2023, 9, 15, 12);
  static const jupiterRetroTm12 = 45.4000919;
  static const jupiterRetroT = 45.3822115;
  static const jupiterRetroTp12 = 45.3634975;

  static final DateTime jupiterDirectUtc = DateTime.utc(2024, 3, 1, 12);
  static const jupiterDirectTm12 = 41.3141715;
  static const jupiterDirectT = 41.3997110;
  static const jupiterDirectTp12 = 41.4857137;

  static const horizonsMotionSource =
      'NASA/JPL Horizons API OBSERVER QUANTITIES=31 CENTER=500@399 STEP=12h';

  /// Tolerances (Phase 4 freeze — do not loosen).
  static const sunTolDeg = 0.05;
  static const planetTolDeg = 0.05;
  static const moonTolDeg = 0.10;
  static const angleTolDeg = 0.10;
}
