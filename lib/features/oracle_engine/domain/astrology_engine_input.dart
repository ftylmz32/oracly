/// OR-1140 — Astrology engine input payload.
library;

import '../core/oracle_engine_type.dart';

class AstrologyEngineInput {
  const AstrologyEngineInput({
    required this.sunSign,
    required this.features,
    this.moonSign,
    this.ascendant,
    this.birthDate,
  });

  final String sunSign;
  final Set<AstrologyFeature> features;
  final String? moonSign;
  final String? ascendant;
  final DateTime? birthDate;
}
