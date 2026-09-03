/// Card-detail meta + symbolism localization (TR / EN / RU).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_catalogue.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_locale.dart';

final _trChars = RegExp(r'[ğüşıöçĞÜŞİÖÇ]');

bool _hasTurkish(String s) => _trChars.hasMatch(s);

void main() {
  tearDown(() => OraclyL10n.bind(AppLocale.tr));

  final content = CardDetailCatalogue.forId(0);

  test('TR meta and symbolism stay canonical Turkish', () {
    OraclyL10n.bind(AppLocale.tr);
    expect(CardDetailLocale.element(content), 'Hava');
    expect(CardDetailLocale.planet(content), 'Uranüs');
    expect(CardDetailLocale.zodiac(content), 'Kova');
    final symbols = CardDetailLocale.symbols(
      cardId: content.id,
      base: content.symbols,
    );
    expect(symbols, isNotEmpty);
    expect(symbols.first.name, 'Beyaz Köpek');
    expect(symbols.first.description, contains('Sadakat'));
  });

  test('EN card-detail meta and symbolism have no Turkish fallback', () {
    OraclyL10n.bind(AppLocale.en);
    expect(CardDetailLocale.element(content), 'Air');
    expect(CardDetailLocale.planet(content), 'Uranus');
    expect(CardDetailLocale.zodiac(content), 'Aquarius');
    expect(_hasTurkish(CardDetailLocale.element(content)), isFalse);
    expect(_hasTurkish(CardDetailLocale.planet(content)), isFalse);
    expect(_hasTurkish(CardDetailLocale.zodiac(content)), isFalse);

    final symbols = CardDetailLocale.symbols(
      cardId: content.id,
      base: content.symbols,
    );
    expect(symbols.first.name, 'White Dog');
    for (final s in symbols) {
      expect(_hasTurkish(s.name), isFalse, reason: s.name);
      expect(_hasTurkish(s.description), isFalse, reason: s.description);
    }
  });

  test('RU card-detail meta and symbolism have no Turkish fallback', () {
    OraclyL10n.bind(AppLocale.ru);
    expect(CardDetailLocale.element(content), 'Воздух');
    expect(CardDetailLocale.planet(content), 'Уран');
    expect(CardDetailLocale.zodiac(content), 'Водолей');
    expect(_hasTurkish(CardDetailLocale.element(content)), isFalse);
    expect(_hasTurkish(CardDetailLocale.planet(content)), isFalse);
    expect(_hasTurkish(CardDetailLocale.zodiac(content)), isFalse);

    final symbols = CardDetailLocale.symbols(
      cardId: content.id,
      base: content.symbols,
    );
    expect(symbols.first.name, isNot(equals('Beyaz Köpek')));
    expect(_hasTurkish(symbols.first.name), isFalse);
    for (final s in symbols) {
      expect(_hasTurkish(s.name), isFalse, reason: s.name);
      expect(_hasTurkish(s.description), isFalse, reason: s.description);
    }
  });

  test('all major cards localize meta and symbolism for EN', () {
    OraclyL10n.bind(AppLocale.en);
    for (final card in CardDetailCatalogue.all) {
      expect(_hasTurkish(CardDetailLocale.element(card)), isFalse);
      expect(_hasTurkish(CardDetailLocale.planet(card)), isFalse);
      expect(_hasTurkish(CardDetailLocale.zodiac(card)), isFalse);
      final symbols = CardDetailLocale.symbols(
        cardId: card.id,
        base: card.symbols,
      );
      expect(symbols.length, card.symbols.length);
      for (final s in symbols) {
        expect(_hasTurkish(s.name), isFalse, reason: 'card ${card.id} ${s.name}');
        expect(
          _hasTurkish(s.description),
          isFalse,
          reason: 'card ${card.id} ${s.description}',
        );
      }
    }
  });
}
