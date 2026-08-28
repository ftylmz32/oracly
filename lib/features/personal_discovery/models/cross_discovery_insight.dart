/// Cross-modal pattern derived only from real observations.
library;

import 'discovery_theme_strength.dart';

class CrossDiscoveryInsight {
  const CrossDiscoveryInsight({
    required this.theme,
    required this.sources,
    required this.confidence,
    required this.lastObserved,
    required this.sourceCount,
    required this.discoveryCount,
    required this.recencyWeight,
  });

  final String theme;
  final List<String> sources;
  final DiscoveryThemeStrength confidence;
  final DateTime lastObserved;
  final int sourceCount;
  final int discoveryCount;
  final double recencyWeight;

  bool get isCrossModal => sourceCount >= 2;

  bool get isRecurring =>
      confidence == DiscoveryThemeStrength.recurring ||
      confidence == DiscoveryThemeStrength.strong;

  String get recencyBand {
    if (recencyWeight >= 0.85) return 'recent';
    if (recencyWeight >= 0.4) return 'aging';
    return 'distant';
  }
}
