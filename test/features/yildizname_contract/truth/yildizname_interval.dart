/// Phase 2 — interval stability helpers (test-only, synthetic).
library;

import 'yildizname_contract_enums.dart';

/// Synthetic day-interval samples — NOT real astronomy.
class IntervalSample {
  const IntervalSample({required this.label, required this.value});
  final String label;
  final String value;
}

abstract final class YildiznameIntervalOracle {
  YildiznameIntervalOracle._();

  static ContractFactCertainty classify(List<IntervalSample> samples) {
    if (samples.isEmpty) return ContractFactCertainty.unavailable;
    final first = samples.first.value;
    final allSame = samples.every((s) => s.value == first);
    return allSame
        ? ContractFactCertainty.intervalStable
        : ContractFactCertainty.ambiguous;
  }

  /// Never pick a midpoint / noon / midnight value when ambiguous.
  static String? chosenValue(List<IntervalSample> samples) {
    final c = classify(samples);
    if (c == ContractFactCertainty.intervalStable) return samples.first.value;
    return null;
  }
}
