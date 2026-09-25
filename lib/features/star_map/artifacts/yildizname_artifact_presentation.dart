/// Converts stored artifact payloads into existing StarMap section chrome.
library;

import '../models/star_map_reading.dart';
import '../presentation/reference/star_map_result_section.dart';
import 'yildizname_artifact.dart';
import 'yildizname_artifact_source.dart';
import 'yildizname_legacy_payload.dart';
import 'yildizname_narrative_payload.dart';

final class YildiznameArtifactPresentation {
  const YildiznameArtifactPresentation({
    required this.title,
    required this.sections,
    this.planets = const [],
  });

  final String title;
  final List<StarMapResultSection> sections;
  final List<StarMapPlanetInfluence> planets;

  /// Body = stored prose only. Never exposes factRefs / themeRefs in text.
  static YildiznameArtifactPresentation of(YildiznameArtifact artifact) {
    if (artifact.source == YildiznameArtifactSource.legacyLocal) {
      return YildiznameArtifactPresentation(
        title: YildiznameLegacyPayload.titleOf(artifact.payload) ?? '',
        sections: YildiznameLegacyPayload.sectionsOf(artifact.payload),
        planets: YildiznameLegacyPayload.planetsOf(artifact.payload),
      );
    }
    final result = YildiznameNarrativePayload.resultOf(artifact.payload);
    if (result == null) {
      return const YildiznameArtifactPresentation(title: '', sections: []);
    }
    final sections = <StarMapResultSection>[];
    final summary = result['summary'];
    if (summary is Map && '${summary['text'] ?? ''}'.trim().isNotEmpty) {
      sections.add(
        StarMapResultSection(title: 'summary', body: '${summary['text']}'),
      );
    }
    final rawSections = result['sections'];
    if (rawSections is List) {
      for (final s in rawSections) {
        if (s is! Map) continue;
        final text = '${s['text'] ?? ''}'.trim();
        if (text.isEmpty) continue;
        sections.add(
          StarMapResultSection(
            title: YildiznameNarrativePayload.sectionChromeTitle(
              '${s['kind'] ?? ''}',
            ),
            body: text,
          ),
        );
      }
    }
    final reflection = result['reflectionPrompt'];
    if (reflection is Map &&
        '${reflection['text'] ?? ''}'.trim().isNotEmpty) {
      sections.add(
        StarMapResultSection(
          title: 'reflection',
          body: '${reflection['text']}',
        ),
      );
    }
    final closing = result['closingMessage'];
    if (closing is Map && '${closing['text'] ?? ''}'.trim().isNotEmpty) {
      sections.add(
        StarMapResultSection(title: 'closing', body: '${closing['text']}'),
      );
    }
    return YildiznameArtifactPresentation(
      title: 'Yıldızname',
      sections: sections,
    );
  }

  static String summaryQuote(YildiznameArtifact artifact) {
    final p = of(artifact);
    for (final s in p.sections) {
      if (s.body.trim().isNotEmpty) return s.body.trim();
    }
    return p.title;
  }
}
