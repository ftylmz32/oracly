/// Seven-beat dream reading from told facts and AI fields.
///
/// Every section carries its true [DreamInsightSource]: provider text that
/// survives [DreamAnalysisGuard] is `ai`; any on-device replacement is
/// `local`. A rejected AI interpretation is omitted, never replaced.
library;

import '../../../core/reading/human_reader.dart';
import '../../ai/production/models/dream_ai_analysis.dart';
import '../copy/dream_copy.dart';
import '../models/dream.dart';
import '../models/dream_insight.dart';
import 'dream_analysis_beats.dart';
import 'dream_analysis_facts.dart';
import 'dream_analysis_guard.dart';
import 'dream_provider_evidence.dart';

typedef _Beat = ({String body, DreamInsightSource source});

abstract final class DreamAnalysisComposer {
  DreamAnalysisComposer._();

  static List<DreamInsight> compose({
    required Dream dream,
    required DreamUnderstanding understanding,
    required String language,
    DreamAiAnalysis? ai,
    String? memorySummary,
  }) {
    final facts = DreamAnalysisFacts.from(
      narrative: dream.narrative,
      understanding: understanding,
      tags: dream.tags,
      statedFeelings:
          DreamProviderEvidence.emotions(dream, understanding, language),
      language: language,
    );
    final seed = Object.hash(dream.id, facts.scene, facts.image).abs();
    final beats = <DreamInsightKind, _Beat>{
      DreamInsightKind.summary: _first(
        [ai?.summary],
        facts,
        () => DreamAnalysisBeats.feeling(facts, seed),
      ),
      DreamInsightKind.symbols: _symbols(facts, ai, seed),
      DreamInsightKind.emotionalMeaning: _first(
        [ai?.emotionalTheme],
        facts,
        () => DreamAnalysisBeats.feeling(facts, seed),
        role: DreamGuardRole.emotionalTheme,
      ),
      DreamInsightKind.mainInterpretation: _first(
        [ai?.interpretation],
        facts,
        () => '',
      ),
      // Prior-Dream history is its own section (DreamHistoryInsight); it
      // never competes with this beat.
      DreamInsightKind.personalConnection: _first(
        [ai?.dailyLifeReflection],
        facts.withContext(memorySummary),
        () => DreamAnalysisBeats.you(facts),
      ),
      DreamInsightKind.themes: _local(
        HumanReader.guard(DreamAnalysisBeats.detail(facts, seed)),
      ),
      DreamInsightKind.closingTakeaway: _closing(facts, ai, seed),
    };
    return [
      for (final entry in beats.entries)
        if (entry.value.body.isNotEmpty)
          DreamInsight(
            kind: entry.key,
            title: DreamCopy.sectionTitle(entry.key, facts.language),
            body: entry.value.body,
            source: entry.value.source,
          ),
    ];
  }

  /// First AI candidate the guard accepts, else the local beat.
  static _Beat _first(
    List<String?> candidates,
    DreamAnalysisFacts facts,
    String Function() local, {
    DreamGuardRole role = DreamGuardRole.dream,
  }) {
    for (final candidate in candidates) {
      final accepted = DreamAnalysisGuard.polish(candidate, facts,
          role: role, source: DreamGuardSource.providerAi);
      if (accepted != null) return _ai(accepted);
    }
    final text = local();
    return text.isEmpty ? _local('') : _local(HumanReader.guard(text));
  }

  static _Beat _symbols(
    DreamAnalysisFacts facts,
    DreamAiAnalysis? ai,
    int seed,
  ) {
    final named = ai?.symbols
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];
    if (named.isNotEmpty) {
      final joined = named.take(5).join(' · ');
      final accepted = DreamAnalysisGuard.polish(joined, facts,
          source: DreamGuardSource.providerAi);
      if (accepted != null) return _ai(accepted);
    }
    // One observed item can fill several slots (the image "Ev" is also the
    // place "Ev"); identical items are shown once.
    final seen = <String>{};
    final parts = <String>[
      for (final part in [facts.image, facts.companion, facts.place])
        if (part != null && seen.add(part.trim().toLowerCase())) part,
    ];
    final local = parts.isNotEmpty
        ? parts.take(4).join(' · ')
        : DreamAnalysisBeats.detail(facts, seed);
    return _local(HumanReader.guard(local));
  }

  static _Beat _closing(
    DreamAnalysisFacts facts,
    DreamAiAnalysis? ai,
    int seed,
  ) {
    final accepted = DreamAnalysisGuard.conclusion(ai?.conclusion, facts,
        source: DreamGuardSource.providerAi);
    if (accepted != null) return _ai(accepted);
    return _local(HumanReader.guard(DreamAnalysisBeats.ask(facts, seed)));
  }

  static _Beat _ai(String body) => (body: body, source: DreamInsightSource.ai);

  static _Beat _local(String body) =>
      (body: body, source: DreamInsightSource.local);
}
