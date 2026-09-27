/// Pure provenance summary over the sections the result view shows.
library;

import '../models/dream.dart';
import '../models/dream_insight.dart';
import '../models/dream_provenance.dart';
import 'dream_reading_presentation.dart';

abstract final class DreamReadingProvenance {
  DreamReadingProvenance._();

  /// True when at least one section is accepted AI text — the only meaning
  /// of the compatibility [Dream.fromAi] flag.
  static bool hasAcceptedAi(List<DreamInsight> insights) =>
      insights.any((i) => i.source == DreamInsightSource.ai);

  /// The insights behind the meaning, symbols, emotion and reflection
  /// blocks, chosen exactly as [DreamReadingPresentation] chooses them.
  static List<DreamInsight> displayed(Dream dream) => [
        DreamReadingPresentation.insightOf(
              dream,
              DreamInsightKind.mainInterpretation,
            ) ??
            DreamReadingPresentation.insightOf(dream, DreamInsightKind.summary),
        DreamReadingPresentation.insightOf(dream, DreamInsightKind.symbols),
        DreamReadingPresentation.insightOf(
          dream,
          DreamInsightKind.emotionalMeaning,
        ),
        DreamReadingPresentation.insightOf(
          dream,
          DreamInsightKind.closingTakeaway,
        ),
      ].nonNulls.toList(growable: false);

  /// Never reads [Dream.fromAi]: a legacy record flagged `fromAi` without
  /// section sources stays [DreamProvenance.legacyUnknown].
  static DreamProvenance of(Dream dream) {
    final sources = displayed(dream).map((i) => i.source).toSet();
    if (sources.isEmpty ||
        sources.contains(DreamInsightSource.legacyUnknown)) {
      return DreamProvenance.legacyUnknown;
    }
    final ai = sources.contains(DreamInsightSource.ai);
    final local = sources.contains(DreamInsightSource.local);
    if (ai && local) return DreamProvenance.mixed;
    return ai ? DreamProvenance.aiOnly : DreamProvenance.localOnly;
  }
}
