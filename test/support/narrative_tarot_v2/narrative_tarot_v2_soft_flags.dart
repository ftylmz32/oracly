/// Phase 2 CONTRACT HARNESS — soft quality flags (offline).
library;

import 'narrative_tarot_v2_hard_failures.dart';
import 'narrative_tarot_v2_models.dart';
import 'narrative_tarot_v2_question_grounding.dart';
import 'narrative_tarot_v2_text.dart';

abstract final class Ntv2SoftFlags {
  static Map<String, bool> compute({
    required Ntv2Scenario s,
    required String text,
    required Set<String> hard,
    required Set<String> drawn,
    required List<Map> beats,
    required List<Map> details,
    required Set<String> relIds,
    required Set<String> memRefs,
    required Set<String> foreignRefs,
    required Set<String> recIds,
    required Map mem,
    required List<String> recentNames,
    required Map<String, int> recCounts,
  }) {
    final usedMem = {
      for (final b in beats)
        ...((b['memoryEvidenceRefs'] as List? ?? const []).cast<String>()),
    };
    final usedRel = {
      for (final b in beats)
        ...((b['relationshipEvidenceIds'] as List? ?? const []).cast<String>()),
    };
    final usedRec = {
      for (final b in beats)
        ...((b['recurringEvidenceIds'] as List? ?? const []).cast<String>()),
    };

    final genericity = Ntv2TextHeuristics.genericity(text);
    final sycophancy = Ntv2TextHeuristics.sycophancy(text);
    final repetitive = Ntv2TextHeuristics.repetitiveEssay(text);
    final legacy = legacyDependence(s.candidate, s);
    final irrMem =
        mem['omitReason'] == 'irrelevant' && usedMem.any(memRefs.contains);
    final cert =
        hard.contains(Ntv2HardFailure.unsupportedCertainty) ||
        hard.contains(Ntv2HardFailure.safetyViolation);

    return {
      'questionGrounded': Ntv2QuestionGrounding.evaluate(
        s,
        text,
        irrMem: irrMem,
        sycophancy: sycophancy,
        legacy: legacy,
        repetitive: repetitive,
        cert: cert,
        genericity: genericity,
        hard: hard,
      ),
      'allCardsAccountedFor': allCardsAccounted(drawn, beats, details),
      'positionSemanticsUsed': beats.any(
        (b) => ((b['positionKeys'] as List?)?.isNotEmpty ?? false),
      ),
      'relationshipEvidenceUsed': usedRel.any(relIds.contains),
      'memoryEvidenceUsed': usedMem.any(
        (r) => memRefs.contains(r) && !foreignRefs.contains(r),
      ),
      'recurrenceEvidenceUsed': usedRec.any(recIds.contains),
      'legacySectionDependence': legacy,
      'genericityDetected': genericity,
      'sycophancyDetected': sycophancy,
      'repetitiveCardEssayDetected': repetitive,
      'naturalUncertainty': naturalUncertainty(
        s.locale,
        cert: cert,
        genericity: genericity,
      ),
      'referentialIntegrityOk': referentialOk(hard, recentNames, recCounts),
    };
  }

  static bool allCardsAccounted(
    Set<String> drawn,
    List<Map> beats,
    List<Map> details,
  ) {
    final seen = <String>{};
    for (final b in beats) {
      seen.addAll((b['cardIds'] as List? ?? const []).cast<String>());
    }
    for (final d in details) {
      seen.add(d['canonicalCardId'] as String);
    }
    return drawn.every(seen.contains);
  }

  static bool legacyDependence(Map candidate, Ntv2Scenario s) {
    final legacy = candidate['legacySections'];
    if (legacy is! Map) return false;
    final forced = [
      'love',
      'career',
      'money',
      'health',
      'luckyEnergy',
    ].every((k) => '${legacy[k] ?? ''}'.trim().isNotEmpty);
    if (!forced) return false;
    final q = '${s.input['questionText'] ?? ''}'.toLowerCase();
    return q.contains('aile') || q.contains('family');
  }

  static bool naturalUncertainty(
    String locale, {
    required bool cert,
    required bool genericity,
  }) {
    if (cert) return false;
    if (genericity && locale == 'tr') return false;
    return true;
  }

  static bool referentialOk(
    Set<String> hard,
    List<String> recentNames,
    Map<String, int> recCounts,
  ) {
    if (hard.intersection(Ntv2HardFailure.referential).isNotEmpty) {
      return false;
    }
    if (hard.contains(Ntv2HardFailure.fabricatedRecurrence) &&
        recentNames.isEmpty &&
        recCounts.isEmpty) {
      return false;
    }
    return true;
  }
}
