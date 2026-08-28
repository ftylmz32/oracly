/// Locale coverage and observational tone for the 78-card data layer.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n_triple.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_card.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';

const _forbidden = [
  'kesinlikle',
  'mutlaka olacak',
  'definitely will',
  'will definitely',
  'this will definitely',
  'обязательно произойдёт',
  'обязательно произойдет',
  'обязательно случится',
  'kesin olacak',
];

bool _localeOk(L10nTriple t) =>
    t.tr.trim().isNotEmpty && t.en.trim().isNotEmpty && t.ru.trim().isNotEmpty;

bool _trOk(OraclyTarotCard c) =>
    c.name.tr.trim().isNotEmpty &&
    c.meanings.fields.every((f) => f.tr.trim().isNotEmpty);

bool _enOk(OraclyTarotCard c) =>
    c.name.en.trim().isNotEmpty &&
    c.meanings.fields.every((f) => f.en.trim().isNotEmpty);

bool _ruOk(OraclyTarotCard c) =>
    c.name.ru.trim().isNotEmpty &&
    c.meanings.fields.every((f) => f.ru.trim().isNotEmpty);

void main() {
  final deck = OraclyTarotDeck.all;

  test('names and structured meanings exist in TR, EN, and RU', () {
    expect(deck.where(_trOk), hasLength(78));
    expect(deck.where(_enOk), hasLength(78));
    expect(deck.where(_ruOk), hasLength(78));
    for (final card in deck) {
      expect(_localeOk(card.name), isTrue, reason: card.id);
      expect(card.meanings.isComplete, isTrue, reason: card.id);
      expect(
        _localeOk(card.relationshipWithOtherCards.note),
        isTrue,
        reason: card.id,
      );
    }
    expect(deck.first.nameTr, 'Deli');
    expect(deck.first.nameEn, 'The Fool');
    expect(deck.first.nameRu, 'Шут');
  });

  test('copy stays observational — no certainty of outcome', () {
    for (final card in deck) {
      final blob = card.userFacingCopy.join('\n').toLowerCase();
      for (final phrase in _forbidden) {
        expect(
          blob.contains(phrase.toLowerCase()),
          isFalse,
          reason: '${card.id} contains "$phrase"',
        );
      }
    }
  });
}
