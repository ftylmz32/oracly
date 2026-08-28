/// Structured insight — presentation/AI turns this into copy.
library;

import 'discovery_theme_strength.dart';

class PersonalInsight {
  const PersonalInsight({
    required this.theme,
    required this.sourceCount,
    required this.confidence,
    required this.recency,
    required this.explanation,
  });

  final String theme;
  final int sourceCount;
  final DiscoveryThemeStrength confidence;
  final String recency;
  final String explanation;
}
