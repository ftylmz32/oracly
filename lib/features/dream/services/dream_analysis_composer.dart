/// Seven-beat dream reading from told facts and AI fields.
library;

import '../../../core/reading/human_reader.dart';
import '../../ai/production/models/dream_ai_analysis.dart';
import '../copy/dream_copy.dart';
import '../models/dream.dart';
import '../models/dream_insight.dart';
import 'dream_analysis_beats.dart';
import 'dream_analysis_facts.dart';
import 'dream_analysis_guard.dart';
import 'dream_pattern_service.dart';

abstract final class DreamAnalysisComposer {
  DreamAnalysisComposer._();

  static List<DreamInsight> compose({
    required Dream dream,
    required DreamUnderstanding understanding,
    DreamPatternMatch? pattern,
    DreamAiAnalysis? ai,
  }) {
    final facts = DreamAnalysisFacts.from(
      narrative: dream.narrative,
      understanding: understanding,
      tags: dream.tags,
    );
    final seed = Object.hash(dream.id, facts.scene, facts.image).abs();
    final out = <DreamInsight>[
      _item(
        DreamInsightKind.summary,
        DreamCopy.summaryTitle,
        _theme(facts, ai, seed),
      ),
      _item(
        DreamInsightKind.symbols,
        DreamCopy.symbolsTitle,
        _symbols(facts, ai, seed),
      ),
      _item(
        DreamInsightKind.emotionalMeaning,
        DreamCopy.emotionalMeaningTitle,
        _emotion(facts, ai, seed),
      ),
    ];
    final reading = _interpretation(facts, ai, seed);
    if (reading.isNotEmpty) {
      out.add(
        _item(
          DreamInsightKind.mainInterpretation,
          DreamCopy.interpretationTitle,
          reading,
        ),
      );
    }
    final life = _life(facts, ai, pattern, seed);
    if (life.isNotEmpty) {
      out.add(
        _item(
          DreamInsightKind.personalConnection,
          DreamCopy.lifeReflectionTitle,
          life,
        ),
      );
    }
    out.add(
      _item(
        DreamInsightKind.themes,
        DreamCopy.symbolsHighlightTitle,
        HumanReader.guard(DreamAnalysisBeats.detail(facts, seed)),
      ),
    );
    out.add(
      _item(
        DreamInsightKind.closingTakeaway,
        DreamCopy.optionalQuestionTitle,
        _orSuggest(facts, ai, seed),
      ),
    );
    return out;
  }

  static String _theme(
    DreamAnalysisFacts facts,
    DreamAiAnalysis? ai,
    int seed,
  ) {
    return DreamAnalysisGuard.polish(ai?.summary, facts) ??
        DreamAnalysisGuard.polish(ai?.emotionalTheme, facts) ??
        HumanReader.guard(DreamAnalysisBeats.feeling(facts, seed));
  }

  static String _symbols(
    DreamAnalysisFacts facts,
    DreamAiAnalysis? ai,
    int seed,
  ) {
    final fromAi = ai?.symbols
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const [];
    if (fromAi.isNotEmpty) {
      final joined = fromAi.take(5).join(' · ');
      final polished = DreamAnalysisGuard.polish(joined, facts);
      if (polished != null) return polished;
    }
    final parts = <String>[
      if (facts.image != null) facts.image!,
      if (facts.companion != null) facts.companion!,
      if (facts.place != null) facts.place!,
    ];
    if (parts.isNotEmpty) return HumanReader.guard(parts.take(4).join(' · '));
    return HumanReader.guard(DreamAnalysisBeats.detail(facts, seed));
  }

  static String _emotion(
    DreamAnalysisFacts facts,
    DreamAiAnalysis? ai,
    int seed,
  ) {
    return DreamAnalysisGuard.polish(ai?.emotionalTheme, facts) ??
        HumanReader.guard(DreamAnalysisBeats.feeling(facts, seed));
  }

  static String _interpretation(
    DreamAnalysisFacts facts,
    DreamAiAnalysis? ai,
    int seed,
  ) {
    return DreamAnalysisGuard.polish(ai?.interpretation, facts) ?? '';
  }

  static String _life(
    DreamAnalysisFacts facts,
    DreamAiAnalysis? ai,
    DreamPatternMatch? pattern,
    int seed,
  ) {
    final fromAi = DreamAnalysisGuard.polish(ai?.dailyLifeReflection, facts);
    if (fromAi != null) return fromAi;
    final date = pattern == null
        ? null
        : DreamPatternService.formatDate(pattern.previousDreamDate);
    return HumanReader.guard(
      DreamAnalysisBeats.you(
        facts: facts,
        date: date,
        sharedSymbols: pattern?.sharedSymbols ?? const [],
      ),
    );
  }

  static String _orSuggest(
    DreamAnalysisFacts facts,
    DreamAiAnalysis? ai,
    int seed,
  ) {
    final advice = DreamAnalysisGuard.polish(ai?.conclusion, facts);
    if (advice != null) return advice;
    return DreamAnalysisGuard.oneQuestion(ai?.conclusion, facts) ??
        HumanReader.guard(DreamAnalysisBeats.ask(facts, seed));
  }

  static DreamInsight _item(DreamInsightKind kind, String title, String body) {
    return DreamInsight(kind: kind, title: title, body: body);
  }
}
