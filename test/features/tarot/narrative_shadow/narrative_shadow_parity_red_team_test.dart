/// Phase 6E — parity red-team (shared facts only).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_card_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_parity.dart';

import 'narrative_shadow_test_support.dart';

TarotNarrativeRequest _mutate(
  TarotNarrativeRequest r, {
  String? languageCode,
  QuestionGrounding? question,
  String? spreadId,
  List<TarotNarrativeCardEvidence>? cards,
}) {
  return TarotNarrativeRequest(
    narrativeTarotVersion: r.narrativeTarotVersion,
    languageCode: languageCode ?? r.languageCode,
    sessionId: r.sessionId,
    readingId: r.readingId,
    question: question ?? r.question,
    spread: spreadId == null
        ? r.spread
        : SpreadSemanticDefinition(
            spreadId: spreadId,
            legacyTypeName: r.spread.legacyTypeName,
            cardCount: r.spread.cardCount,
            purposeKey: r.spread.purposeKey,
            positions: r.spread.positions,
            interpretationOrder: r.spread.interpretationOrder,
            geometryHook: r.spread.geometryHook,
            lengthBand: r.spread.lengthBand,
          ),
    cards: cards ?? r.cards,
    relationships: r.relationships,
    memory: r.memory,
    recurringCards: r.recurringCards,
    recurringThemes: r.recurringThemes,
    bounds: r.bounds,
  );
}

TarotNarrativeCardEvidence _card(
  TarotNarrativeCardEvidence c, {
  String? canonicalCardId,
  bool? isReversed,
  int? positionIndex,
  String? positionKey,
}) {
  return TarotNarrativeCardEvidence(
    canonicalCardId: canonicalCardId ?? c.canonicalCardId,
    ritualCardId: c.ritualCardId,
    isReversed: isReversed ?? c.isReversed,
    positionKey: positionKey ?? c.positionKey,
    positionIndex: positionIndex ?? c.positionIndex,
    displayName: c.displayName,
    profileSlice: c.profileSlice,
    imageAsset: c.imageAsset,
  );
}

void main() {
  test('parity red-team detects shared-fact mutations', () {
    final scenario = launchScenarios().firstWhere(
      (s) => s['id'] == 'three_contrast_exemplar_en',
    );
    final result = evaluateScenario(scenario);
    expect(result.isPass, isTrue);
    final legacy = result.legacyContext!;
    final base = result.finalNarrativeRequest!;
    final readingId = (scenario['input'] as Map)['readingId'] as String;
    final spread = sessionFromEvidence(scenario).spread;

    NarrativeTarotShadowParityReport check(TarotNarrativeRequest n) =>
        NarrativeTarotShadowParity.compare(
          legacy: legacy,
          narrative: n,
          readingId: readingId,
          sessionSpread: spread,
        );

    final first = base.cards.first;
    expect(
      check(_mutate(base, cards: [
        for (final c in base.cards)
          _card(c, canonicalCardId: c == first ? 'major_21' : null),
      ])).canonicalCardId,
      isFalse,
    );
    expect(
      check(_mutate(base, cards: [
        for (final c in base.cards)
          _card(c, isReversed: c == first ? !c.isReversed : null),
      ])).reversal,
      isFalse,
    );
    expect(
      check(_mutate(base, cards: [
        for (final c in base.cards)
          _card(c, positionIndex: c == first ? 99 : null),
      ])).positionIndex,
      isFalse,
    );
    expect(
      check(_mutate(base, cards: [
        for (final c in base.cards)
          _card(c, positionKey: c == first ? 'mutated_key' : null),
      ])).positionKey,
      isFalse,
    );
    expect(
      check(_mutate(base, question: QuestionGrounding(
        rawText: 'MUTATED_QUESTION_6E',
        topic: base.question.topic,
        kind: base.question.kind,
        hasRealQuestion: true,
      ))).question,
      isFalse,
    );
    expect(check(_mutate(base, languageCode: 'tr')).locale, isFalse);
    expect(
      check(_mutate(base, spreadId: 'classical.sevenCard')).spread,
      isFalse,
    );
  });
}
