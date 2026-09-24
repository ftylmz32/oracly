/// Phase 6E.1 — independent multi-mismatch parity report accuracy.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_card_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_parity.dart';

import 'narrative_shadow_test_support.dart';

TarotNarrativeCardEvidence _card(
  TarotNarrativeCardEvidence c, {
  int? ritualCardId,
  String? canonicalCardId,
  bool? isReversed,
  String? positionKey,
}) {
  return TarotNarrativeCardEvidence(
    canonicalCardId: canonicalCardId ?? c.canonicalCardId,
    ritualCardId: ritualCardId ?? c.ritualCardId,
    isReversed: isReversed ?? c.isReversed,
    positionKey: positionKey ?? c.positionKey,
    positionIndex: c.positionIndex,
    displayName: c.displayName,
    profileSlice: c.profileSlice,
    imageAsset: c.imageAsset,
  );
}

TarotNarrativeRequest _withCards(
  TarotNarrativeRequest r,
  List<TarotNarrativeCardEvidence> cards,
) {
  return TarotNarrativeRequest(
    narrativeTarotVersion: r.narrativeTarotVersion,
    languageCode: r.languageCode,
    sessionId: r.sessionId,
    readingId: r.readingId,
    question: r.question,
    spread: r.spread,
    cards: cards,
    relationships: r.relationships,
    memory: r.memory,
    recurringCards: r.recurringCards,
    recurringThemes: r.recurringThemes,
    bounds: r.bounds,
  );
}

void main() {
  test('multi-mismatch parity reports all independent dimensions', () {
    final scenario = launchScenarios().firstWhere(
      (s) => s['id'] == 'three_contrast_exemplar_en',
    );
    final result = evaluateScenario(scenario);
    expect(result.isPass, isTrue);
    final base = result.finalNarrativeRequest!;
    final cards = [
      _card(base.cards[0], ritualCardId: 21, canonicalCardId: 'major_21'),
      _card(base.cards[1], isReversed: !base.cards[1].isReversed),
      _card(base.cards[2], positionKey: 'mutated_key'),
    ];
    final report = NarrativeTarotShadowParity.compare(
      legacy: result.legacyContext!,
      narrative: _withCards(base, cards),
      readingId: (scenario['input'] as Map)['readingId'] as String,
      sessionSpread: sessionFromEvidence(scenario).spread,
    );
    expect(report.ritualCardId, isFalse);
    expect(report.reversal, isFalse);
    expect(report.positionKey, isFalse);
    expect(report.overallPass, isFalse);
  });

  test('ritualCardId mutation is detected', () {
    final scenario = launchScenarios().firstWhere(
      (s) => s['id'] == 'three_contrast_exemplar_en',
    );
    final result = evaluateScenario(scenario);
    final base = result.finalNarrativeRequest!;
    final mutated = _withCards(base, [
      _card(base.cards.first, ritualCardId: 21, canonicalCardId: 'major_21'),
      ...base.cards.skip(1),
    ]);
    final report = NarrativeTarotShadowParity.compare(
      legacy: result.legacyContext!,
      narrative: mutated,
      readingId: (scenario['input'] as Map)['readingId'] as String,
      sessionSpread: sessionFromEvidence(scenario).spread,
    );
    expect(report.ritualCardId, isFalse);
    expect(report.canonicalCardId, isFalse);
    expect(report.overallPass, isFalse);
  });

  test('card-count mismatch falsifies all card dimensions', () {
    final scenario = launchScenarios().firstWhere(
      (s) => s['id'] == 'three_contrast_exemplar_en',
    );
    final result = evaluateScenario(scenario);
    final base = result.finalNarrativeRequest!;
    final report = NarrativeTarotShadowParity.compare(
      legacy: result.legacyContext!,
      narrative: _withCards(base, base.cards.take(1).toList()),
      readingId: (scenario['input'] as Map)['readingId'] as String,
      sessionSpread: sessionFromEvidence(scenario).spread,
    );
    expect(report.cardCount, isFalse);
    expect(report.ritualCardId, isFalse);
    expect(report.canonicalCardId, isFalse);
    expect(report.reversal, isFalse);
    expect(report.positionIndex, isFalse);
    expect(report.positionKey, isFalse);
    expect(report.overallPass, isFalse);
  });
}
