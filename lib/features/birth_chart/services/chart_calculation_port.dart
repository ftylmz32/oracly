/// SPRINT-002 — Swappable chart calculation port (ephemeris-ready).
library;

import '../models/birth_chart.dart';
import '../models/birth_profile.dart';

abstract class ChartCalculationPort {
  BirthChart calculate(BirthProfile profile);
}
