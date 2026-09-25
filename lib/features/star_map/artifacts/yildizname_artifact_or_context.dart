/// OR handoff from artifact prose only — no birth / owner / fingerprints.
library;

import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import 'yildizname_artifact.dart';
import 'yildizname_artifact_presentation.dart';
import 'yildizname_artifact_source.dart';
import 'yildizname_narrative_payload.dart';

abstract final class YildiznameArtifactOrContext {
  YildiznameArtifactOrContext._();

  static OracleReadingContext build(YildiznameArtifact artifact) {
    final presentation = YildiznameArtifactPresentation.of(artifact);
    final bodies = [
      for (final s in presentation.sections)
        if (s.body.trim().isNotEmpty) s.body.trim(),
    ];
    final summary = bodies.isEmpty ? presentation.title : bodies.first;
    final full = bodies.take(4).join('\n\n');
    return OracleReadingContext(
      sessionId: artifact.id,
      kind: OracleReadingKind.starMap,
      sourceLabel: 'Yıldızname',
      spreadLabel: presentation.title.isEmpty ? 'Yıldızname' : presentation.title,
      deckId: 'star-map-artifact',
      deckName: 'Yıldızname',
      readingTitle:
          presentation.title.isEmpty ? 'Yıldızname' : presentation.title,
      cardsSummary: artifact.source == YildiznameArtifactSource.narrativeV1
          ? 'Yıldızname · arşiv'
          : 'Yıldızname · yerel',
      interpretationSummary: _clip(summary, 180),
      fullInterpretation: _clip(full.isEmpty ? summary : full, 900),
    );
  }

  static String _clip(String raw, int max) {
    final t = raw.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max).trimRight()}…';
  }

  /// Guard for tests — serialized OR text must not contain these.
  static bool containsForbidden(String text) {
    final lower = text.toLowerCase();
    for (final needle in const [
      'latitude',
      'longitude',
      'timezone',
      'ownerid',
      'evidencefingerprint',
      'semanticfingerprint',
      'factref',
      'birthdate',
      'birthtime',
      'birthplace',
    ]) {
      if (lower.contains(needle)) return true;
    }
    return false;
  }

  static String? storedSummaryText(YildiznameArtifact artifact) {
    if (artifact.source == YildiznameArtifactSource.narrativeV1) {
      final result = YildiznameNarrativePayload.resultOf(artifact.payload);
      final summary = result?['summary'];
      if (summary is Map) return summary['text']?.toString();
    }
    return YildiznameArtifactPresentation.summaryQuote(artifact);
  }
}
