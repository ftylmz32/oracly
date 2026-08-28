/// EPIC-015 — Runtime performance preferences bridged from settings.
library;

import '../../features/premium/models/personalization_models.dart';

abstract final class OraclyPerformanceGate {
  OraclyPerformanceGate._();

  static ParticleIntensity particleIntensity = ParticleIntensity.medium;
}
