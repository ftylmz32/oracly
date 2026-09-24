/// Phase 6C.1 — cache keyForInput version namespace tamper tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_cache_identity.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_evidence_parts.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_input.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_test_support.dart';

void main() {
  test('cache wrong narrative/serializer/policy versions throw', () {
    final base = buildFromCorpusId('single_open_fool_en');
    final ok = NarrativeTarotPromptSerializer.serialize(base);
    expect(
      () => NarrativeTarotCacheIdentity.keyForInput(
        input: NarrativeTarotPromptInput(
          narrativeTarotVersion: 1,
          languageCode: ok.languageCode,
          question: ok.question,
          spread: ok.spread,
          cards: ok.cards,
          relationships: ok.relationships,
          recurringCards: ok.recurringCards,
          recurringThemes: ok.recurringThemes,
          memory: ok.memory,
          policy: ok.policy,
        ),
        bounds: base.bounds,
        sessionId: base.sessionId,
        readingId: base.readingId,
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeTarotCacheIdentity.keyForInput(
        input: NarrativeTarotPromptInput(
          narrativeTarotVersion: ok.narrativeTarotVersion,
          serializerVersion: 99,
          languageCode: ok.languageCode,
          question: ok.question,
          spread: ok.spread,
          cards: ok.cards,
          relationships: ok.relationships,
          recurringCards: ok.recurringCards,
          recurringThemes: ok.recurringThemes,
          memory: ok.memory,
          policy: ok.policy,
        ),
        bounds: base.bounds,
        sessionId: base.sessionId,
        readingId: base.readingId,
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeTarotCacheIdentity.keyForInput(
        input: NarrativeTarotPromptInput(
          narrativeTarotVersion: ok.narrativeTarotVersion,
          languageCode: ok.languageCode,
          question: ok.question,
          spread: ok.spread,
          cards: ok.cards,
          relationships: ok.relationships,
          recurringCards: ok.recurringCards,
          recurringThemes: ok.recurringThemes,
          memory: ok.memory,
          policy: NarrativePromptPolicy(
            version: 'narrative_policy_v999',
            rules: ok.policy.rules,
          ),
        ),
        bounds: base.bounds,
        sessionId: base.sessionId,
        readingId: base.readingId,
      ),
      throwsArgumentError,
    );
  });
}
