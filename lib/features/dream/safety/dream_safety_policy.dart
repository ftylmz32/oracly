/// Dream Phase 3 input policy — deterministic, local, TR/EN/RU, zero
/// provider calls. Classifies only what the dreamer states: dream imagery
/// (death, blood, spirits, being watched, a diagnosis inside the dream) is
/// allowed; a waking-life disclosure or request is not.
library;

import '../models/dream_entry_selection.dart';
import 'dream_safety_concern.dart';
import 'dream_safety_lexicon.dart';
import 'dream_safety_text.dart';

abstract final class DreamSafetyPolicy {
  DreamSafetyPolicy._();

  /// The most urgent concern across [texts], or null when a reading may run.
  static DreamSafetyConcern? classify(Iterable<String> texts) {
    DreamSafetyConcern? worst;
    for (final text in texts) {
      for (final segment in DreamSafetyText.segments(text)) {
        final concern = _of(segment);
        if (concern != null && (worst == null || concern.index < worst.index)) {
          worst = concern;
        }
      }
    }
    return worst;
  }

  /// The dreamer's own words for one dream: narrative and raw guided
  /// answers. Stored tags count only for records saved before structured
  /// entry existed; ORACLY chip labels never establish a concern.
  static DreamSafetyConcern? forDream({
    required String narrative,
    DreamEntrySelection? entry,
    List<String> tags = const [],
  }) {
    return classify([
      narrative,
      if (entry != null) ...entry.guided.values else ...tags,
    ]);
  }

  /// Fails closed before any attempt, charge, provider call or storage.
  static void ensureSafe({
    required String narrative,
    DreamEntrySelection? entry,
    List<String> tags = const [],
  }) {
    final concern = forDream(narrative: narrative, entry: entry, tags: tags);
    if (concern != null) throw DreamSafetyException(concern);
  }

  /// Retrieved connected memory that must be left out of the request.
  static bool isSensitiveMemory(String? memory) {
    if (memory == null || memory.trim().isEmpty) return false;
    if (classify([memory]) != null) return true;
    return DreamSafetyText.has(
      DreamSafetyLexicon.memory,
      DreamSafetyText.fold(memory),
    );
  }

  static DreamSafetyConcern? _of(DreamSafetySegment segment) {
    final text = segment.text;
    bool framedHit(RegExp p) => DreamSafetyText.hit(
          p,
          text,
          dream: DreamSafetyLexicon.dream,
          waking: DreamSafetyLexicon.waking,
        );
    if (DreamSafetyText.has(DreamSafetyLexicon.crisis, text)) {
      return DreamSafetyConcern.crisis;
    }
    if (framedHit(DreamSafetyLexicon.acute)) {
      return DreamSafetyConcern.acuteDistress;
    }
    if (DreamSafetyText.has(DreamSafetyLexicon.abuse, text) &&
        DreamSafetyText.has(DreamSafetyLexicon.reality, text)) {
      return DreamSafetyConcern.trauma;
    }
    if ((DreamSafetyText.has(DreamSafetyLexicon.proof, text) &&
            DreamSafetyText.has(DreamSafetyLexicon.agents, text)) ||
        framedHit(DreamSafetyLexicon.voices)) {
      return DreamSafetyConcern.delusion;
    }
    if (framedHit(DreamSafetyLexicon.diagnosisTerms) &&
        (segment.question ||
            DreamSafetyText.has(DreamSafetyLexicon.diagnosisLinks, text))) {
      return DreamSafetyConcern.diagnosis;
    }
    return null;
  }
}
