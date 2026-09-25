/// Narrative evidence scope — never call reduced "full".
library;

import '../../../birth_chart/models/chart_fidelity.dart';

enum YildiznameNarrativeScope {
  legacy,
  reduced,
  full,
}

extension YildiznameNarrativeScopeMap on YildiznameNarrativeScope {
  static YildiznameNarrativeScope fromFidelity(ChartCalculationFidelity f) {
    return switch (f) {
      ChartCalculationFidelity.tropicalSunSign =>
        YildiznameNarrativeScope.legacy,
      ChartCalculationFidelity.reducedNatal => YildiznameNarrativeScope.reduced,
      ChartCalculationFidelity.fullNatalEphemeris =>
        YildiznameNarrativeScope.full,
    };
  }

  String get wireName => name;
}
