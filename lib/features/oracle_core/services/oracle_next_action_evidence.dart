/// Deterministic evidence ids from real discovery observations.
library;

import '../../personal_discovery/models/discovery_observation.dart';

abstract final class OracleNextActionEvidence {
  OracleNextActionEvidence._();

  static String idOf(DiscoveryObservation o) =>
      '${o.source}|${o.theme}|${o.observedAt.toUtc().toIso8601String()}';

  static List<String> idsForTheme(
    List<DiscoveryObservation> observations,
    String theme, {
    int max = 8,
  }) {
    final key = theme.trim().toLowerCase();
    final rows = [
      for (final o in observations)
        if (o.theme.trim().toLowerCase() == key) o,
    ]..sort((a, b) => b.observedAt.compareTo(a.observedAt));
    return [
      for (final o in rows.take(max)) idOf(o),
    ];
  }

  static List<String> sourcesForTheme(
    List<DiscoveryObservation> observations,
    String theme,
  ) {
    final key = theme.trim().toLowerCase();
    final set = <String>{
      for (final o in observations)
        if (o.theme.trim().toLowerCase() == key) o.source,
    };
    final list = set.toList()..sort();
    return list;
  }
}
