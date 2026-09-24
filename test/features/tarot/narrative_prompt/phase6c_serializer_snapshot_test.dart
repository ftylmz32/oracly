/// Phase 6C — serializer snapshot + classical / enriched compatibility.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_cache_identity.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_canonical.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_input.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_special_requests.dart';
import 'narrative_prompt_test_support.dart';

void main() {
  late Map<String, dynamic> fixture;

  setUpAll(() {
    fixture = loadPromptFixture();
  });

  Map<String, dynamic> scenario(String id) {
    final list = fixture['scenarios'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>().firstWhere((s) => s['id'] == id);
  }

  TarotNarrativeRequest requestFor(String id) {
    return switch (id) {
      'classical_single_tr_open' =>
        NarrativeEvidenceBuilder.build(singleTrOpenInput()),
      'classical_three_en_decision' =>
        buildFromCorpusId('three_contrast_exemplar_en'),
      'classical_five_ru_reversed' =>
        buildFromCorpusId('five_conflict_exemplar_ru'),
      'enriched_phase4_recurrence_memory' => enrichedForSerialize(),
      'privacy_sentinel_internal_ids' => privacySentinelRequest(),
      'signature_manual_spread_generic' => signatureManualRequest(),
      'classical_single_en_open' => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: '6c_session_single_en',
          readingId: '6c_reading_single_en',
          languageCode: 'en',
          questionRaw: null,
          intentionTopic: null,
          spreadType: TarotSpreadType.single,
          cards: const [
            NarrativeEvidenceCardInput(
              canonicalCardId: 'major_00',
              ritualCardId: 0,
              isReversed: false,
              positionKey: 'sign',
              positionIndex: 0,
            ),
          ],
        ),
      ),
      'classical_single_ru_open' => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: '6c_session_single_ru',
          readingId: '6c_reading_single_ru',
          languageCode: 'ru',
          questionRaw: null,
          intentionTopic: null,
          spreadType: TarotSpreadType.single,
          cards: const [
            NarrativeEvidenceCardInput(
              canonicalCardId: 'major_00',
              ritualCardId: 0,
              isReversed: false,
              positionKey: 'sign',
              positionIndex: 0,
            ),
          ],
        ),
      ),
      _ => throw StateError(id),
    };
  }

  group('Phase 6C snapshots', () {
    test('fixture metadata locked', () {
      expect(fixture['serializerVersion'], 1);
      expect(fixture['policyVersion'], 'narrative_policy_v1');
      expect(fixture['cacheKeyPrefix'], NarrativeTarotCacheIdentity.keyPrefix);
      expect(NarrativeTarotPromptInput.kSerializerVersion, 1);
    });

    for (final id in [
      'classical_single_tr_open',
      'classical_three_en_decision',
      'classical_five_ru_reversed',
      'enriched_phase4_recurrence_memory',
      'privacy_sentinel_internal_ids',
      'signature_manual_spread_generic',
      'classical_single_en_open',
      'classical_single_ru_open',
    ]) {
      test('snapshot $id', () {
        final expected = scenario(id);
        final request = requestFor(id);
        final input = NarrativeTarotPromptSerializer.serialize(request);
        expect(
          NarrativeTarotPromptCanonical.toMap(input),
          expected['modelInput'],
        );
        expect(
          NarrativeTarotCacheIdentity.keyFor(request),
          expected['cacheKey'],
        );
        final a = NarrativeTarotPromptCanonical.encode(input);
        final b = NarrativeTarotPromptCanonical.encode(
          NarrativeTarotPromptSerializer.serialize(request),
        );
        expect(a, b);
      });
    }
  });

  group('Classical / enriched serialize', () {
    test('single / three / five / enriched pass', () {
      for (final id in [
        'single_open_fool_en',
        'three_contrast_exemplar_en',
        'five_conflict_exemplar_ru',
      ]) {
        final r = buildFromCorpusId(id);
        final input = NarrativeTarotPromptSerializer.serialize(r);
        expect(input.cards, isNotEmpty);
        expect(input.spread.spreadId, startsWith('classical.'));
      }
      final enriched = enrichedForSerialize();
      final input = NarrativeTarotPromptSerializer.serialize(enriched);
      expect(input.recurringCards, isNotEmpty);
      expect(input.memory.included, isTrue);
      expect(input.memory.entries, isNotEmpty);
    });
  });
}
