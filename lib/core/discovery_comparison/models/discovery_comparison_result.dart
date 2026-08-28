/// Earlier vs later discovery with an honest synthesis.
library;

import 'discovery_comparison_kind.dart';
import 'discovery_comparison_snapshot.dart';

class DiscoveryComparisonResult {
  const DiscoveryComparisonResult({
    required this.kind,
    required this.earlier,
    required this.later,
    required this.synthesis,
  });

  final DiscoveryComparisonKind kind;
  final DiscoveryComparisonSnapshot earlier;
  final DiscoveryComparisonSnapshot later;
  final String synthesis;
}
