/// Builds ThemeEvidence rows from real observations only.
library;

import '../../personal_discovery/models/discovery_observation.dart';
import '../models/oracle_theme_evidence.dart';
import 'oracle_next_action_evidence.dart';
import 'oracle_or_privacy.dart';

abstract final class OracleThemeEvidenceBuilder {
  OracleThemeEvidenceBuilder._();

  static List<OracleThemeEvidence> fromObservations(
    List<DiscoveryObservation> observations, {
    String? theme,
    Set<String>? allowedSources,
    int max = 8,
  }) {
    final key = theme?.trim().toLowerCase();
    final rows = <OracleThemeEvidence>[];
    for (final o in observations) {
      if (!OracleOrPrivacy.allows(o.source, allowedSources)) continue;
      if (key != null && o.theme.trim().toLowerCase() != key) continue;
      rows.add(
        OracleThemeEvidence(
          evidenceId: OracleNextActionEvidence.idOf(o),
          theme: o.theme,
          sourceFeature: o.source,
          observedAt: o.observedAt,
        ),
      );
    }
    rows.sort((a, b) => b.observedAt.compareTo(a.observedAt));
    return List.unmodifiable(rows.take(max));
  }
}
