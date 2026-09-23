/// Pure historical cross-feature theme recurrence (Phase 4B).
library;

import '../evidence/narrative_recurrence_evidence.dart';
import '../evidence/narrative_request.dart';
import 'tarot_connected_memory_eligibility.dart';
import 'tarot_connected_memory_models.dart';
import 'tarot_historical_current_signals.dart';
import 'tarot_historical_models.dart';
import 'tarot_historical_recall.dart';
import 'tarot_theme_recurrence_support.dart';

abstract final class TarotThemeRecurrenceEngine {
  TarotThemeRecurrenceEngine._();

  static List<TarotRecurringThemeEvidence> build({
    required TarotNarrativeRequest base,
    required TarotHistoricalSnapshot history,
    required DateTime now,
  }) {
    final eligible = TarotConnectedMemoryEligibility.eligible(
      records: history.connectedMemories,
      base: base,
      now: now,
    );
    final currentKw = TarotHistoricalCurrentSignals.cardKeywordsFrom(base);
    final currentThemes = TarotHistoricalCurrentSignals.currentThemeIds(
      base.question,
    );
    final recall = TarotHistoricalRecall.detects(base.question.rawText);

    final byTheme = <String, List<TarotConnectedMemoryRecord>>{};
    for (final r in eligible) {
      final themes = TarotHistoricalCurrentSignals.normalizeCanonicalThemes(
        r.themeIds,
      );
      for (final theme in themes) {
        (byTheme[theme] ??= []).add(r);
      }
    }

    final drafts = <_ThemeDraft>[];
    for (final e in byTheme.entries) {
      final supports = e.value;
      final types = supports.map((s) => s.sourceType).toSet();
      if (types.length < 2) continue;
      final relevance = TarotThemeRecurrenceSupport.relevance(
        themeId: e.key,
        question: base.question,
        currentThemes: currentThemes,
        currentKw: currentKw,
        recall: recall,
      );
      if (relevance < 0.35) continue;
      drafts.add(
        _ThemeDraft(
          themeId: e.key,
          supportCount: supports.length,
          distinctTypes: types.length,
          mostRecent: supports.first.occurredAt.toUtc(),
          relevance: relevance,
          supportingRefs: TarotThemeRecurrenceSupport.supportRefs(
            supports,
            base.bounds.maxRecurringOccurrencesListed,
          ),
          relatedCardIds: TarotThemeRecurrenceSupport.relatedCards(
            e.key,
            base.cards,
          ),
        ),
      );
    }

    drafts.sort(_compare);
    final max = base.bounds.maxThemeLabels;
    if (max <= 0) return const [];
    final taken = drafts.length <= max ? drafts : drafts.sublist(0, max);
    final out = <TarotRecurringThemeEvidence>[
      for (var i = 0; i < taken.length; i++)
        TarotRecurringThemeEvidence(
          evidenceId: 'rec_theme_${(i + 1).toString().padLeft(2, '0')}',
          themeIdOrLabel: taken[i].themeId,
          supportCount: taken[i].supportCount,
          supportingReadingIds: taken[i].supportingRefs,
          relatedCardIds: taken[i].relatedCardIds,
          relevanceToCurrentAsk: taken[i].relevance,
        ),
    ];
    return List<TarotRecurringThemeEvidence>.unmodifiable(out);
  }

  static int _compare(_ThemeDraft a, _ThemeDraft b) {
    final byRel = b.relevance.compareTo(a.relevance);
    if (byRel != 0) return byRel;
    final byTypes = b.distinctTypes.compareTo(a.distinctTypes);
    if (byTypes != 0) return byTypes;
    final byCount = b.supportCount.compareTo(a.supportCount);
    if (byCount != 0) return byCount;
    final byRecent = b.mostRecent.compareTo(a.mostRecent);
    if (byRecent != 0) return byRecent;
    return a.themeId.compareTo(b.themeId);
  }
}

class _ThemeDraft {
  const _ThemeDraft({
    required this.themeId,
    required this.supportCount,
    required this.distinctTypes,
    required this.mostRecent,
    required this.relevance,
    required this.supportingRefs,
    required this.relatedCardIds,
  });

  final String themeId;
  final int supportCount;
  final int distinctTypes;
  final DateTime mostRecent;
  final double relevance;
  final List<String> supportingRefs;
  final List<String> relatedCardIds;
}
