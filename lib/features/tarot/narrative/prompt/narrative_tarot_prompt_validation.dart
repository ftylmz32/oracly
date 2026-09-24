/// Phase 6C.1 — closed-world + bounds validation before serialization.
library;

import '../evidence/narrative_request.dart';
import 'narrative_tarot_prompt_evidence_checks.dart';
import 'narrative_tarot_prompt_structure_checks.dart';

abstract final class NarrativeTarotPromptValidation {
  NarrativeTarotPromptValidation._();

  static const supportedLanguages = {'tr', 'en', 'ru'};

  static void validate(TarotNarrativeRequest request) {
    if (request.narrativeTarotVersion !=
        TarotNarrativeRequest.currentNarrativeVersion) {
      throw ArgumentError(
        'narrativeTarotVersion ${request.narrativeTarotVersion} '
        '!= ${TarotNarrativeRequest.currentNarrativeVersion}',
      );
    }
    if (!supportedLanguages.contains(request.languageCode)) {
      throw ArgumentError(
        'unsupported languageCode ${request.languageCode}',
      );
    }
    NarrativeTarotPromptStructureChecks.question(request);
    NarrativeTarotPromptStructureChecks.spread(request);
    NarrativeTarotPromptStructureChecks.cards(request);
    NarrativeTarotPromptEvidenceChecks.relationships(request);
    NarrativeTarotPromptEvidenceChecks.recurrenceAndMemory(request);
  }
}
