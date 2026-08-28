/// Message ↔ theme relevance for Oracle Core → OR handoff.
library;

import '../../personal_discovery/data/discovery_theme_lexicon.dart';
import '../../personal_discovery/models/discovery_theme.dart';

abstract final class OracleOrThemeMatch {
  OracleOrThemeMatch._();

  static bool themeRelevant(String themeLabel, String message) {
    final theme = DiscoveryTheme.resolve(themeLabel);
    if (theme == null) return message.contains(themeLabel.toLowerCase());
    final tokens = <String>[
      theme.label,
      theme.localized,
      ...?DiscoveryThemeLexicon.map[theme],
      if (theme == DiscoveryTheme.career) 'is',
      if (theme == DiscoveryTheme.career) 'iş',
      if (theme == DiscoveryTheme.change) 'degistir',
      if (theme == DiscoveryTheme.change) 'değiştir',
    ];
    return tokens.any((t) => message.contains(t.toLowerCase()));
  }
}

class OracleOrThemeHit {
  const OracleOrThemeHit({required this.theme, required this.score});
  final String theme;
  final int score;
}
