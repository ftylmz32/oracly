/// Birth-chart and artifact starMap journal rows.
library;

import '../../../core/domain/models/birth_chart_record.dart';
import '../../birth_chart/data/birth_chart_record_mapper.dart';
import '../../personal_discovery/services/personal_theme_extractor.dart';
import '../../star_map/artifacts/yildizname_artifact.dart';
import '../../star_map/artifacts/yildizname_artifact_journal.dart';
import '../copy/discovery_journal_copy.dart';
import '../models/discovery_journal_entry.dart';
import '../models/discovery_journal_kind.dart';

abstract final class DiscoveryJournalMapStarMap {
  DiscoveryJournalMapStarMap._();

  static DiscoveryJournalEntry artifact(YildiznameArtifact artifact) =>
      YildiznameArtifactJournal.entry(artifact);

  static DiscoveryJournalEntry birthChart(BirthChartRecord record) {
    String preview = '';
    try {
      final chart = BirthChartRecordMapper.fromRecord(record);
      preview = chart.sun.sign.labelTr;
    } catch (_) {}
    final themes = <String>{};
    for (final theme in PersonalThemeExtractor.themesIn(preview)) {
      themes.add(theme.label);
    }
    return DiscoveryJournalEntry(
      id: record.id,
      kind: DiscoveryJournalKind.starMap,
      date: record.updatedAt ?? record.createdAt,
      title: DiscoveryJournalCopy.starTitle,
      preview: preview,
      themes: themes.toList(growable: false),
    );
  }
}
