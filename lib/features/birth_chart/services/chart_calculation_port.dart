/// Swappable natal calculation port — ephemeris-ready.
library;

import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../models/chart_fidelity.dart';

export '../models/chart_fidelity.dart';

abstract class ChartCalculationPort {
  ChartCalculationFidelity get fidelity;

  BirthChart calculate(BirthProfile profile);
}
