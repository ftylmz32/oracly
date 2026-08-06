/// OR-1140 — Daily energy engine input payload.
library;

import '../core/oracle_engine_type.dart';

class DailyEnergyEngineInput {
  const DailyEnergyEngineInput({
    required this.date,
    required this.features,
  });

  final DateTime date;
  final Set<EnergyFeature> features;
}
