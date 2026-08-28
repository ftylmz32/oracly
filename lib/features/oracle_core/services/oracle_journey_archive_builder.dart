/// Builds Journey Archive from real observations — never invents links.
library;

import '../../personal_discovery/models/discovery_observation.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../models/oracle_journey_archive.dart';
import '../models/oracle_theme_history_entry.dart';
import 'oracle_next_action_eligibility.dart';
import 'oracle_next_action_engine.dart';

abstract final class OracleJourneyArchiveBuilder {
  OracleJourneyArchiveBuilder._();

  /// True when profile already carries journeyDepth-grade evidence.
  static bool isJourneyReady(
    PersonalDiscoveryProfile profile, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    for (final insight in profile.crossInsights) {
      if (insight.sourceCount < OracleNextActionEngine.journeyDepthSources) {
        continue;
      }
      if (insight.discoveryCount < OracleNextActionEngine.journeyDepthCount) {
        continue;
      }
      if (!OracleNextActionEligibility.insightQualifies(insight, clock)) {
        continue;
      }
      return true;
    }
    return false;
  }

  static OracleJourneyArchive? fromProfile(
    PersonalDiscoveryProfile profile, {
    DateTime? now,
    int maxThemes = 8,
  }) {
    final clock = now ?? DateTime.now();
    final byTheme = <String, List<DiscoveryObservation>>{};
    for (final o in profile.observations) {
      final key = o.theme.trim().toLowerCase();
      if (key.isEmpty) continue;
      byTheme.putIfAbsent(key, () => []).add(o);
    }

    final entries = <OracleThemeHistoryEntry>[];
    for (final rows in byTheme.values) {
      if (rows.length < OracleNextActionEligibility.minOccurrences) continue;
      final sources = {
        for (final r in rows) r.source,
      };
      if (sources.length < OracleNextActionEligibility.minSourceFeatures) {
        continue;
      }
      rows.sort((a, b) => a.observedAt.compareTo(b.observedAt));
      entries.add(
        OracleThemeHistoryEntry(
          theme: rows.first.theme,
          sourceFeatures: List.unmodifiable(sources.toList()..sort()),
          occurrenceCount: rows.length,
          firstObserved: rows.first.observedAt,
          lastObserved: rows.last.observedAt,
        ),
      );
    }
    if (entries.isEmpty) return null;
    entries.sort((a, b) => b.lastObserved.compareTo(a.lastObserved));
    return OracleJourneyArchive(
      entries: List.unmodifiable(entries.take(maxThemes)),
      generatedAt: clock,
    );
  }
}
