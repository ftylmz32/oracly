/// Phase 6E.3 — enriched provider-QA request (authoritative displayName + memory).
library;

import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';

import '../narrative_history/tarot_history_test_support.dart';
import '../narrative_history/tarot_narrative_request_enricher_fixtures.dart';
import '../narrative_prompt/narrative_prompt_test_support.dart';

/// Corpus base (real deck displayName) + Phase 4 enricherRichHistory.
TarotNarrativeRequest enrichedProviderQaRequest() {
  final base = copyRequest(
    buildFromCorpusId('single_open_fool_en'),
    question: NarrativeQuestionGrounding.from(
      rawQuestion: 'Should I stay in this relationship?',
      topic: 'love',
    ),
  );
  return TarotNarrativeRequestEnricher.enrich(
    base: base,
    history: enricherRichHistory(base, nowFixed),
    currentOwnerId: null,
    privacyBlocked: false,
    now: nowFixed,
  );
}
