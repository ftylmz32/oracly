/// Detects symbolic themes from real text. Never diagnoses.
library;

import '../data/discovery_theme_lexicon.dart';
import '../models/cross_discovery_insight.dart';
import '../models/dated_discovery_text.dart';
import '../models/discovery_observation.dart';
import '../models/discovery_theme.dart';
import '../models/discovery_theme_signal.dart';
import '../models/discovery_theme_strength.dart';
import 'discovery_recency.dart';

abstract final class PersonalThemeExtractor {
  PersonalThemeExtractor._();

  static const minRecurring = 2;
  static const maxInsights = 3;

  static List<String> labelsIn(Iterable<String> texts) {
    final counts = <DiscoveryTheme, int>{};
    for (final raw in texts) {
      for (final theme in themesIn(raw)) {
        counts[theme] = (counts[theme] ?? 0) + 1;
      }
    }
    final recurring = counts.entries
        .where((e) => e.value >= minRecurring)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return recurring.map((e) => e.key.label).toList(growable: false);
  }

  static List<DiscoveryObservation> observationsFrom(
    Iterable<DatedDiscoveryText> items,
  ) {
    final out = <DiscoveryObservation>[];
    for (final item in items) {
      for (final theme in themesIn(item.text)) {
        out.add(
          DiscoveryObservation(
            source: item.source,
            theme: theme.label,
            observedAt: item.at,
          ),
        );
      }
    }
    return List.unmodifiable(out);
  }

  static List<CrossDiscoveryInsight> insightsFrom(
    List<DiscoveryObservation> observations, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final byTheme = <String, List<DiscoveryObservation>>{};
    for (final o in observations) {
      (byTheme[o.theme] ??= <DiscoveryObservation>[]).add(o);
    }
    final insights = <CrossDiscoveryInsight>[];
    for (final entry in byTheme.entries) {
      final list = entry.value;
      final sources = list.map((o) => o.source).toSet().toList()..sort();
      final last = list.map((o) => o.observedAt).reduce(
            (a, b) => a.isAfter(b) ? a : b,
          );
      final weight = list
          .map((o) => DiscoveryRecency.weight(o.observedAt, clock))
          .fold<double>(0, (a, b) => a + b);
      final recency = weight / list.length;
      insights.add(
        CrossDiscoveryInsight(
          theme: entry.key,
          sources: sources,
          confidence: _strength(
            count: list.length,
            sourceCount: sources.length,
            recencyWeight: recency,
          ),
          lastObserved: last,
          sourceCount: sources.length,
          discoveryCount: list.length,
          recencyWeight: recency,
        ),
      );
    }
    insights.sort((a, b) {
      final score = _scoreOf(b).compareTo(_scoreOf(a));
      if (score != 0) return score;
      final latest = b.lastObserved.compareTo(a.lastObserved);
      if (latest != 0) return latest;
      return a.theme.compareTo(b.theme);
    });
    return List.unmodifiable(insights.take(maxInsights).toList(growable: false));
  }

  /// Legacy aggregate for modality maps without dates.
  static List<DiscoveryThemeSignal> aggregate(
    Map<String, Iterable<String>> textsBySource,
  ) {
    final dated = <DatedDiscoveryText>[
      for (final e in textsBySource.entries)
        for (final text in e.value)
          DatedDiscoveryText(
            source: e.key,
            text: text,
            at: DateTime.fromMillisecondsSinceEpoch(0),
          ),
    ];
    return insightsFrom(observationsFrom(dated))
        .map(
          (i) => DiscoveryThemeSignal(
            label: i.theme,
            discoveryCount: i.discoveryCount,
            sources: i.sources,
            strength: i.confidence,
          ),
        )
        .toList(growable: false);
  }

  static Set<DiscoveryTheme> themesIn(String raw) {
    final text = raw.toLowerCase();
    if (text.trim().isEmpty) return const {};
    final found = <DiscoveryTheme>{};
    for (final entry in DiscoveryThemeLexicon.map.entries) {
      for (final token in entry.value) {
        if (text.contains(token)) {
          found.add(entry.key);
          break;
        }
      }
    }
    return found;
  }

  static DiscoveryThemeStrength _strength({
    required int count,
    required int sourceCount,
    required double recencyWeight,
  }) {
    if (sourceCount >= 3 && count >= 3 && recencyWeight >= 0.55) {
      return DiscoveryThemeStrength.strong;
    }
    if (sourceCount >= 2) return DiscoveryThemeStrength.recurring;
    return DiscoveryThemeStrength.observed;
  }

  static double _scoreOf(CrossDiscoveryInsight insight) {
    return (insight.recencyWeight * 140) +
        (insight.discoveryCount * 8) +
        (insight.sourceCount * 16);
  }
}
