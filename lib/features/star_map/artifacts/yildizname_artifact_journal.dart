/// Discovery Journal row from a Yıldızname artifact (opener wired elsewhere).
library;

import '../../discovery_journal/models/discovery_journal_entry.dart';
import '../../discovery_journal/models/discovery_journal_kind.dart';
import 'yildizname_artifact.dart';
import 'yildizname_artifact_presentation.dart';
import 'yildizname_artifact_source.dart';
import 'yildizname_narrative_payload.dart';

abstract final class YildiznameArtifactJournal {
  YildiznameArtifactJournal._();

  static DiscoveryJournalEntry entry(YildiznameArtifact artifact) {
    final presentation = YildiznameArtifactPresentation.of(artifact);
    final preview = YildiznameArtifactPresentation.summaryQuote(artifact);
    return DiscoveryJournalEntry(
      id: artifact.id,
      kind: DiscoveryJournalKind.starMap,
      date: artifact.createdAtUtc,
      title: presentation.title.isEmpty ? 'Yıldızname' : presentation.title,
      preview: preview.length > 160
          ? '${preview.substring(0, 160).trimRight()}…'
          : preview,
      themes: _safeThemes(artifact),
    );
  }

  static List<String> _safeThemes(YildiznameArtifact artifact) {
    if (artifact.source != YildiznameArtifactSource.narrativeV1) {
      return const [];
    }
    final request = YildiznameNarrativePayload.requestOf(artifact.payload);
    final accepted =
        YildiznameNarrativePayload.acceptedThemeRefs(artifact.payload);
    if (request == null || accepted.isEmpty) return const [];
    final themes = request['discoveryThemes'];
    if (themes is! List) return const [];
    final labels = <String>[];
    for (final t in themes) {
      if (t is! Map) continue;
      final ref = t['themeRef']?.toString() ?? '';
      if (!accepted.contains(ref)) continue;
      final label = t['label']?.toString().trim() ?? '';
      if (label.isNotEmpty) labels.add(label);
    }
    return labels;
  }
}
