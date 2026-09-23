/// Phase 3D.1D — NarrativeEvidenceBuilder unit coverage.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';

final _ritual = <String, int>{
  for (var i = 0; i < 78; i++) OraclyTarotBridge.byRitualId(i)!.id: i,
};

NarrativeEvidenceInput _reading({
  required TarotSpreadType type,
  required List<(String id, bool rev)> cards,
  String lang = 'en',
  String? question,
  String? topic,
}) {
  final def = ClassicalSpreadSemantics.byLegacyTypeName(type.name);
  return NarrativeEvidenceInput(
    sessionId: 'sess',
    readingId: 'read',
    languageCode: lang,
    questionRaw: question,
    intentionTopic: topic,
    spreadType: type,
    cards: [
      for (var i = 0; i < cards.length; i++)
        NarrativeEvidenceCardInput(
          canonicalCardId: cards[i].$1,
          ritualCardId: _ritual[cards[i].$1]!,
          isReversed: cards[i].$2,
          positionKey: def.positions[i].positionKey,
          positionIndex: def.positions[i].index,
        ),
    ],
  );
}

void main() {
  test('single / three / five / seven / celtic valid builds', () {
    for (final type in TarotSpreadType.values) {
      final ids = OraclyTarotDeck.expectedIds.take(type.cardCount).toList();
      final req = NarrativeEvidenceBuilder.build(
        _reading(type: type, cards: [for (final id in ids) (id, false)]),
      );
      expect(req.cards, hasLength(type.cardCount));
      expect(req.spread.legacyTypeName, type.name);
      expect(req.bounds.maxRelationships, 12);
      expect(req.memory.included, isFalse);
      expect(req.recurringCards, isEmpty);
      expect(req.recurringThemes, isEmpty);
      expect(req.relationships.length, lessThanOrEqualTo(12));
    }
  });

  test('question kind integration', () {
    final base = [('major_00', false)];
    expect(
      NarrativeEvidenceBuilder.build(
        _reading(type: TarotSpreadType.single, cards: base, question: null),
      ).question.kind,
      QuestionKind.open,
    );
    expect(
      NarrativeEvidenceBuilder.build(
        _reading(
          type: TarotSpreadType.single,
          cards: base,
          question: 'Should I accept this offer?',
        ),
      ).question.kind,
      QuestionKind.decision,
    );
    expect(
      NarrativeEvidenceBuilder.build(
        _reading(
          type: TarotSpreadType.single,
          cards: base,
          question: 'How is this relationship evolving?',
        ),
      ).question.kind,
      QuestionKind.relationship,
    );
    expect(
      NarrativeEvidenceBuilder.build(
        _reading(
          type: TarotSpreadType.single,
          cards: base,
          question: 'Need guidance for my next step',
        ),
      ).question.kind,
      QuestionKind.guidance,
    );
  });

  test('language normalization + display names TR/EN/RU', () {
    final card = OraclyTarotDeck.byId('major_00')!;
    for (final entry in [
      ('en', 'en'),
      ('English', 'en'),
      ('en-US', 'en'),
      ('ru', 'ru'),
      ('Russian', 'ru'),
      ('ru-RU', 'ru'),
      ('tr', 'tr'),
      ('', 'tr'),
      ('xx', 'tr'),
    ]) {
      final req = NarrativeEvidenceBuilder.build(
        _reading(
          type: TarotSpreadType.single,
          cards: [('major_00', false)],
          lang: entry.$1,
        ),
      );
      expect(req.languageCode, entry.$2);
      expect(req.cards.single.displayName, card.name.of(entry.$2));
    }
  });

  test('profile slice / transforms / visual asset', () {
    final upright = NarrativeEvidenceBuilder.build(
      _reading(type: TarotSpreadType.single, cards: [('wands_01', false)]),
    );
    expect(upright.cards.single.profileSlice.transforms, isEmpty);
    expect(
      upright.cards.single.imageAsset,
      OraclyTarotDeck.byId('wands_01')!.visualAsset,
    );

    final reversed = NarrativeEvidenceBuilder.build(
      _reading(type: TarotSpreadType.single, cards: [('wands_01', true)]),
    );
    expect(reversed.cards.single.isReversed, isTrue);
    expect(reversed.cards.single.profileSlice.transforms, isNotEmpty);
  });

  test('78 ritual bridge parity', () {
    final seen = <String>{};
    for (var i = 0; i < 78; i++) {
      final card = OraclyTarotBridge.byRitualId(i);
      expect(card, isNotNull, reason: 'ritual $i');
      expect(seen.add(card!.id), isTrue);
    }
    expect(seen, OraclyTarotDeck.expectedIds.toSet());
    expect(OraclyTarotBridge.byRitualId(-1), isNull);
    expect(OraclyTarotBridge.byRitualId(78), isNull);
    expect(OraclyTarotBridge.byRitualId(999), isNull);
  });

  test('request version and bounds defaults', () {
    final req = NarrativeEvidenceBuilder.build(
      _reading(type: TarotSpreadType.single, cards: [('major_00', false)]),
    );
    expect(
      req.narrativeTarotVersion,
      TarotNarrativeRequest.currentNarrativeVersion,
    );
    expect(req.bounds.maxPriorReadingsScanned, 20);
    expect(req.bounds.maxRecurringOccurrencesListed, 5);
    expect(req.bounds.maxRelationships, 12);
    expect(req.bounds.maxMemoryChars, 800);
    expect(req.bounds.maxThemeLabels, 4);
  });
}
