/// Picks one relevant cross-feature action after a session ends.
library;

import '../../../features/personal_discovery/models/discovery_recommended_feature.dart';
import '../../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../../../features/personal_discovery/services/discovery_recommendation_map.dart';
import '../copy/session_continuation_copy.dart';
import '../models/session_continuation.dart';

abstract final class SessionContinuationEngine {
  SessionContinuationEngine._();

  static SessionContinuation? decide({
    required SessionContinuationSource from,
    PersonalDiscoveryProfile profile = PersonalDiscoveryProfile.empty,
    List<String> sessionThemes = const [],
    bool orAlreadyOffered = false,
  }) {
    final themes = _themes(sessionThemes, profile);
    final crossModal = _hasCrossModal(profile);
    final mapped = _primaryMapped(themes);

    return switch (from) {
      SessionContinuationSource.coffee => _mappedChamber(
          mapped: mapped,
          theme: themes.firstOrNull ?? sessionThemes.firstOrNull,
          orAlreadyOffered: orAlreadyOffered,
          tarotLine: SessionContinuationCopy.coffeeToTarot(),
          orLine: SessionContinuationCopy.coffeeToOr(),
        ),
      SessionContinuationSource.palm => _mappedChamber(
          mapped: mapped,
          theme: themes.firstOrNull ?? sessionThemes.firstOrNull,
          orAlreadyOffered: orAlreadyOffered,
          tarotLine: SessionContinuationCopy.palmToTarot(),
          orLine: SessionContinuationCopy.palmToOr(),
        ),
      SessionContinuationSource.tarot => orAlreadyOffered
          ? (crossModal ? _dream(themes) : null)
          : _tarot(),
      SessionContinuationSource.dream =>
        crossModal ? _dream(themes) : null,
      SessionContinuationSource.starMap =>
        crossModal ? _star(themes) : null,
      SessionContinuationSource.astrology =>
        crossModal && themes.isNotEmpty ? _astro(themes) : null,
      SessionContinuationSource.soulMate =>
        crossModal ? _star(themes) : null,
    };
  }

  static SessionContinuation? _mappedChamber({
    required DiscoveryRecommendedFeature? mapped,
    required String? theme,
    required bool orAlreadyOffered,
    required String tarotLine,
    required String orLine,
  }) {
    return switch (mapped) {
      DiscoveryRecommendedFeature.companion => orAlreadyOffered
          ? null
          : SessionContinuation(
              target: SessionContinuationTarget.companion,
              line: orLine,
              theme: theme,
            ),
      DiscoveryRecommendedFeature.tarot => SessionContinuation(
          target: SessionContinuationTarget.tarot,
          line: tarotLine,
          theme: theme,
        ),
      DiscoveryRecommendedFeature.starMap => SessionContinuation(
          target: SessionContinuationTarget.discoveryJournal,
          line: SessionContinuationCopy.relationshipToJournal(theme),
          theme: theme,
        ),
      _ => null,
    };
  }

  static SessionContinuation? _tarot() => SessionContinuation(
        target: SessionContinuationTarget.companion,
        line: SessionContinuationCopy.tarotToOr(),
      );

  static SessionContinuation? _dream(List<String> themes) => SessionContinuation(
        target: SessionContinuationTarget.discoveryJournal,
        line: SessionContinuationCopy.dreamToJournal(themes.firstOrNull),
        theme: themes.firstOrNull,
      );

  static SessionContinuation? _star(List<String> themes) => SessionContinuation(
        target: SessionContinuationTarget.discoveryJournal,
        line: SessionContinuationCopy.starToJournal(themes.firstOrNull),
        theme: themes.firstOrNull,
      );

  static SessionContinuation? _astro(List<String> themes) =>
      SessionContinuation(
        target: SessionContinuationTarget.discoveryJournal,
        line: SessionContinuationCopy.astrologyToJournal(themes.firstOrNull),
        theme: themes.firstOrNull,
      );

  static DiscoveryRecommendedFeature? _primaryMapped(List<String> themes) {
    for (final theme in themes) {
      final mapped = DiscoveryRecommendationMap.forTheme(theme);
      if (mapped != null) return mapped;
    }
    return null;
  }

  static List<String> _themes(
    List<String> sessionThemes,
    PersonalDiscoveryProfile profile,
  ) {
    final seen = <String>{};
    final out = <String>[];
    void add(String raw) {
      final text = raw.trim();
      if (text.isEmpty || !seen.add(text.toLowerCase())) return;
      out.add(text);
    }

    for (final theme in sessionThemes) {
      add(theme);
    }
    for (final theme in profile.crossModalThemes) {
      add(theme);
    }
    return out;
  }

  static bool _hasCrossModal(PersonalDiscoveryProfile profile) => profile
      .crossInsights
      .any((item) => item.isRecurring && item.isCrossModal);
}
