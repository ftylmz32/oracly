/// One grounded ORACLY observation from real discovery evidence.
library;

import 'cross_discovery_insight.dart';

class OraclyObservation {
  const OraclyObservation({
    required this.theme,
    required this.line,
    required this.insight,
  });

  final String theme;
  final String line;
  final CrossDiscoveryInsight insight;
}
