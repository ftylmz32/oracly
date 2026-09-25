/// Phase 4 — calculation provenance for every structured fact.
library;

class AstronomicalProvenance {
  const AstronomicalProvenance({
    required this.engineId,
    required this.engineVersion,
    required this.calculationVersion,
    required this.evidenceFingerprint,
    required this.zodiacSystem,
    required this.coordinateConvention,
    this.timezoneDatabase,
    this.houseSystem,
  });

  static const engineAstronomia = 'oracly.astronomia';
  static const calcYildiznameNatalV1 = 'yildizname-natal-v1';
  static const zodiacTropical = 'tropical';
  static const coordApparentEclipticOfDate = 'geocentric_apparent_ecliptic_of_date';

  final String engineId;
  final String engineVersion;
  final String calculationVersion;
  final String evidenceFingerprint;
  final String zodiacSystem;
  final String coordinateConvention;
  final String? timezoneDatabase;
  final String? houseSystem;

  Map<String, dynamic> toJson() => {
        'engineId': engineId,
        'engineVersion': engineVersion,
        'calculationVersion': calculationVersion,
        'evidenceFingerprint': evidenceFingerprint,
        'zodiacSystem': zodiacSystem,
        'coordinateConvention': coordinateConvention,
        if (timezoneDatabase != null) 'timezoneDatabase': timezoneDatabase,
        if (houseSystem != null) 'houseSystem': houseSystem,
      };

  factory AstronomicalProvenance.fromJson(Map<String, dynamic> json) {
    return AstronomicalProvenance(
      engineId: json['engineId'] as String,
      engineVersion: json['engineVersion'] as String,
      calculationVersion: json['calculationVersion'] as String,
      evidenceFingerprint: json['evidenceFingerprint'] as String,
      zodiacSystem: json['zodiacSystem'] as String,
      coordinateConvention: json['coordinateConvention'] as String,
      timezoneDatabase: json['timezoneDatabase'] as String?,
      houseSystem: json['houseSystem'] as String?,
    );
  }
}
