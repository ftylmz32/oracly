/// Swappable natal calculation port — evidence-aware.
library;

import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../models/chart_fidelity.dart';

export '../models/chart_fidelity.dart';

abstract class ChartCalculationPort {
  /// Baseline / documentation fidelity — must NOT claim every profile is full.
  ChartCalculationFidelity get fidelity;

  /// Evidence-derived expected fidelity for this profile.
  ChartCalculationFidelity fidelityFor(BirthProfile profile) => fidelity;

  String get calculationVersion => 'legacy-tropical-v0';

  BirthChart calculate(BirthProfile profile);
}
