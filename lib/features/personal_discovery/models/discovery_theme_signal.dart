/// One observational theme derived from real discovery texts.
library;

import 'discovery_theme_strength.dart';

class DiscoveryThemeSignal {
  const DiscoveryThemeSignal({
    required this.label,
    required this.strength,
    required this.discoveryCount,
    required this.sources,
  });

  final String label;
  final DiscoveryThemeStrength strength;
  final int discoveryCount;
  final List<String> sources;

  bool get isCrossModal => sources.length >= 2;

  bool get isRecurring =>
      strength == DiscoveryThemeStrength.recurring ||
      strength == DiscoveryThemeStrength.strong;
}
