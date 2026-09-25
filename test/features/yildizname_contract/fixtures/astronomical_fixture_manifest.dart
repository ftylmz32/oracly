/// Phase 2 — astronomical fixture manifest (no invented goldens).
library;

enum FixtureAuthority { pendingAuthority, legacyDateTable }

class AstronomicalFixtureCategory {
  const AstronomicalFixtureCategory({
    required this.id,
    required this.description,
    required this.authority,
    this.requiredFields = const [
      'source',
      'sourceDate',
      'expectedValues',
      'tolerance',
      'engineVersion',
    ],
  });

  final String id;
  final String description;
  final FixtureAuthority authority;
  final List<String> requiredFields;
}

abstract final class AstronomicalFixtureManifest {
  AstronomicalFixtureManifest._();

  static const categories = <AstronomicalFixtureCategory>[
    AstronomicalFixtureCategory(
      id: 'ordinary_full_natal',
      description: 'Ordinary full natal with authoritative ephemeris',
      authority: FixtureAuthority.pendingAuthority,
    ),
    AstronomicalFixtureCategory(
      id: 'sun_near_sign_boundary',
      description: 'Sun near tropical sign boundary',
      authority: FixtureAuthority.pendingAuthority,
    ),
    AstronomicalFixtureCategory(
      id: 'moon_transition_unknown_time',
      description: 'Moon changes during unknown-time interval',
      authority: FixtureAuthority.pendingAuthority,
    ),
    AstronomicalFixtureCategory(
      id: 'historical_dst_timezone',
      description: 'Historical DST / timezone edge',
      authority: FixtureAuthority.pendingAuthority,
    ),
    AstronomicalFixtureCategory(
      id: 'high_latitude_house_edge',
      description: 'High-latitude house edge case',
      authority: FixtureAuthority.pendingAuthority,
    ),
    AstronomicalFixtureCategory(
      id: 'invalid_date_time_place',
      description: 'Invalid date/time/place inputs',
      authority: FixtureAuthority.pendingAuthority,
    ),
    AstronomicalFixtureCategory(
      id: 'timezone_resolution_failure',
      description: 'Timezone resolution failure',
      authority: FixtureAuthority.pendingAuthority,
    ),
    AstronomicalFixtureCategory(
      id: 'unknown_birth_time_reduced',
      description: 'Unknown birth time reduced case',
      authority: FixtureAuthority.pendingAuthority,
    ),
  ];

  static const legacyDateTableLabel = 'LEGACY DATE TABLE';
  static const inventedAuthoritativeValues = false;
}
