/// Phase 4 — natal calculation metadata (UTC kept calculation-internal).
library;

import 'natal_house_system.dart';

class NatalCalculationMetadata {
  const NatalCalculationMetadata({
    required this.calculationVersion,
    required this.engineId,
    required this.engineVersion,
    required this.evidenceFingerprint,
    required this.houseSystem,
    required this.zodiacSystem,
    required this.coordinateConvention,
    this.timezoneDatabase,
    this.utcInstantIso,
    this.birthInstantKind,
  });

  final String calculationVersion;
  final String engineId;
  final String engineVersion;
  final String evidenceFingerprint;
  final NatalHouseSystem houseSystem;
  final String zodiacSystem;
  final String coordinateConvention;
  final String? timezoneDatabase;

  /// ISO-8601 UTC — calculation metadata only; never share/OR/analytics.
  final String? utcInstantIso;
  final String? birthInstantKind;

  Map<String, dynamic> toJson() => {
        'calculationVersion': calculationVersion,
        'engineId': engineId,
        'engineVersion': engineVersion,
        'evidenceFingerprint': evidenceFingerprint,
        'houseSystem': houseSystem.name,
        'zodiacSystem': zodiacSystem,
        'coordinateConvention': coordinateConvention,
        if (timezoneDatabase != null) 'timezoneDatabase': timezoneDatabase,
        if (utcInstantIso != null) 'utcInstantIso': utcInstantIso,
        if (birthInstantKind != null) 'birthInstantKind': birthInstantKind,
      };

  factory NatalCalculationMetadata.fromJson(Map<String, dynamic> json) {
    return NatalCalculationMetadata(
      calculationVersion: json['calculationVersion'] as String,
      engineId: json['engineId'] as String,
      engineVersion: json['engineVersion'] as String,
      evidenceFingerprint: json['evidenceFingerprint'] as String,
      houseSystem: NatalHouseSystem.values.byName(json['houseSystem'] as String),
      zodiacSystem: json['zodiacSystem'] as String,
      coordinateConvention: json['coordinateConvention'] as String,
      timezoneDatabase: json['timezoneDatabase'] as String?,
      utcInstantIso: json['utcInstantIso'] as String?,
      birthInstantKind: json['birthInstantKind'] as String?,
    );
  }
}
