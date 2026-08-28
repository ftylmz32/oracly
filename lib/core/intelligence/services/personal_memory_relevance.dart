/// Filters personal memory for OR — relevant themes only, never creepy detail.
library;

import '../../../features/personal_discovery/data/discovery_theme_lexicon.dart';
import '../../../features/personal_discovery/models/discovery_theme.dart';
import '../../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../../../features/personal_discovery/services/or_cross_discovery_context.dart';
import '../domain/models/personal_memory_summary.dart';

abstract final class PersonalMemoryRelevance {
  PersonalMemoryRelevance._();

  static String? hintForMessage(
    PersonalDiscoveryProfile profile,
    String userMessage,
  ) =>
      OrCrossDiscoveryContext.forMessage(profile, userMessage);

  static String? filterHint(String? hint, String userMessage) {
    final body = hint?.trim() ?? '';
    if (body.isEmpty) return null;
    final msg = userMessage.trim().toLowerCase();
    if (msg.isEmpty) return null;
    final lower = body.toLowerCase();
    for (final theme in DiscoveryTheme.values) {
      if (!_themeRelevant(theme.label, msg)) continue;
      if (lower.contains(theme.label.toLowerCase()) ||
          lower.contains(theme.name.toLowerCase())) {
        return body;
      }
      final tokens = DiscoveryThemeLexicon.map[theme] ?? const <String>[];
      if (tokens.any(lower.contains)) return body;
    }
    return null;
  }

  /// Proactive observation / tension line — only when the message shares a theme.
  static String? filterObservation(String? observation, String userMessage) {
    final body = observation?.trim() ?? '';
    if (body.isEmpty) return null;
    final msg = userMessage.trim();
    if (msg.length < 12) return null;
    if (filterHint(body, msg) != null) return body;
    final lowerMsg = msg.toLowerCase();
    final lowerBody = body.toLowerCase();
    for (final theme in DiscoveryTheme.values) {
      final tokens = <String>[
        theme.label,
        ...?DiscoveryThemeLexicon.map[theme],
      ];
      final inObs = tokens.any(lowerBody.contains);
      final inMsg = tokens.any(lowerMsg.contains);
      if (inObs && inMsg) return body;
    }
    return null;
  }

  static bool hasRelevantThemes(
    PersonalMemorySummary summary,
    String userMessage,
  ) {
    final msg = userMessage.trim().toLowerCase();
    if (msg.isEmpty) return false;
    return summary.themes.any(
      (t) => _themeRelevant(t.label, msg) || _themeRelevant(t.id, msg),
    );
  }

  static bool _themeRelevant(String themeLabel, String message) {
    final theme = DiscoveryTheme.resolve(themeLabel);
    if (theme == null) return message.contains(themeLabel.toLowerCase());
    final tokens = [...?DiscoveryThemeLexicon.map[theme]];
    if (theme == DiscoveryTheme.career && !tokens.contains('iş')) {
      tokens.add('iş');
    }
    for (final token in tokens) {
      if (message.contains(token)) return true;
    }
    return message.contains(theme.label.toLowerCase()) ||
        message.contains(theme.localized.toLowerCase());
  }
}
