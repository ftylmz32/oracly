/// Phase 6C.2 — locale-consistent Signature Crossroads TEST-ONLY fixture.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_special_requests.dart';

void main() {
  test('signature fixture EN display names + profile text', () {
    final request = signatureManualRequest();
    expect(request.languageCode, 'en');
    expect(request.spread.cardCount, 5);
    final input = NarrativeTarotPromptSerializer.serialize(request);
    final cyrillic = RegExp(r'[А-Яа-яЁё]');
    for (final card in input.cards) {
      final deck = OraclyTarotDeck.byId(card.canonicalCardId)!;
      expect(card.displayName, deck.name.of('en'));
      expect(card.coreMeaning, isNotEmpty);
      expect(card.coreMeaning.contains(cyrillic), isFalse);
      expect(card.orientationExpression.contains(cyrillic), isFalse);
    }
  });
}
