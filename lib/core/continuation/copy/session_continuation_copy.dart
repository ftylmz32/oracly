/// Cross-feature continuation lines — one action, observational tone.
library;

import '../../../features/personal_discovery/models/discovery_recommended_feature.dart';
import '../../../features/personal_discovery/services/discovery_recommendation_map.dart';
import '../../../core/l10n/l10n.dart';

abstract final class SessionContinuationCopy {
  SessionContinuationCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String coffeeToTarot() => _t('continue.coffee.tarot');
  static String coffeeToOr() => _t('continue.coffee.or');
  static String? coffeeOrWhisperFor(List<String> themes) =>
      _orWhisper(themes, coffeeOrWhisper);

  static String palmToTarot() => _t('continue.palm.tarot');
  static String palmToOr() => _t('continue.palm.or');
  static String? palmOrWhisperFor(List<String> themes) =>
      _orWhisper(themes, palmOrWhisper);

  static String coffeeOrWhisper(String? theme) =>
      _withTheme('continue.coffee.or_whisper', theme);
  static String palmOrWhisper(String? theme) =>
      _withTheme('continue.palm.or_whisper', theme);

  static String tarotToOr() => _t('continue.tarot.or');

  static String dreamToJournal(String? theme) =>
      _withTheme('continue.dream.journal', theme);

  static String starToJournal(String? theme) =>
      _withTheme('continue.star.journal', theme);

  static String relationshipToJournal(String? theme) =>
      _withTheme('continue.relation.journal', theme);

  static String astrologyToJournal(String? theme) =>
      _withTheme('continue.astro.journal', theme);

  static String? _orWhisper(
    List<String> themes,
    String Function(String? theme) line,
  ) {
    for (final theme in themes) {
      if (DiscoveryRecommendationMap.forTheme(theme) ==
          DiscoveryRecommendedFeature.companion) {
        return line(theme);
      }
    }
    return null;
  }

  static String _withTheme(String key, String? theme) {
    final raw = (theme ?? '').trim();
    if (raw.isEmpty) return _t('$key.generic');
    return _t(key).replaceAll('{theme}', _title(raw));
  }

  static String _title(String raw) {
    final label = raw.trim();
    if (label.isEmpty) return label;
    final first = label.substring(0, 1);
    final upper = switch (first) {
      'i' => 'İ',
      'ı' => 'I',
      _ => first.toUpperCase(),
    };
    return '$upper${label.substring(1)}';
  }
}
