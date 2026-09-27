/// Dream Phase 4A — the visible recurring-thread section.
///
/// Local and deterministic: every label, count and date comes from saved
/// records. It is attached when a reading is shown and never persisted, so
/// a deleted or cleared prior Dream can never linger in it.
library;

import '../../../core/l10n/l10n.dart';
import '../models/dream.dart';
import '../models/dream_insight.dart';
import 'dream_history_evidence.dart';

abstract final class DreamHistoryInsight {
  DreamHistoryInsight._();

  static const maxLines = 3;

  static DreamInsight? of(DreamHistoryContext history, String language) {
    if (history.isEmpty) return null;
    final shown = history.evidence.take(maxLines).toList();
    final recurring =
        shown.any((e) => e.level == DreamRecurrenceLevel.recurring);
    return DreamInsight(
      kind: DreamInsightKind.recurringPattern,
      title: _t(
        recurring
            ? 'dream.history.title.recurring'
            : 'dream.history.title.seen',
        language,
      ),
      body: [for (final e in shown) _line(e, language)].join('\n'),
      source: DreamInsightSource.local,
    );
  }

  /// [dream] with only the live section for [history] — any older
  /// recurring section is dropped, never shown twice or stale.
  static Dream attach(Dream dream, DreamHistoryContext history, String language) {
    final section = of(history, language);
    return dream.copyWith(insights: [
      for (final insight in dream.insights)
        if (insight.kind != DreamInsightKind.recurringPattern) insight,
      ?section,
    ]);
  }

  static String _line(DreamHistoryEvidence e, String language) {
    final key = e.level == DreamRecurrenceLevel.recurring
        ? 'dream.history.line.recurring'
        : 'dream.history.line.seen';
    return _t(key, language)
        .replaceAll('{label}', _label(e.displayLabel, language))
        .replaceAll('{total}', '${e.totalWithCurrent}')
        .replaceAll(
          '{date}',
          OraclyFormat.dateNumeric(e.lastSeenAt, languageCode: language),
        );
  }

  static String _label(String label, String language) {
    if (language == AppLocale.tr || label.isEmpty) return label;
    return label[0].toUpperCase() + label.substring(1);
  }

  static String _t(String key, String language) =>
      OraclyL10n.t(key, languageCode: language);
}
