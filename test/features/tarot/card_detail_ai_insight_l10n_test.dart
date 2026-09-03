/// Card-detail aiInsight localization (TR / EN / RU).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_catalogue.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_insights.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_locale.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_models.dart';

final _trChars = RegExp(r'[ğüşıöçĞÜŞİÖÇ]');

bool _hasTurkish(String s) => _trChars.hasMatch(s);

CardDetailContent _stub({required int id, String aiInsight = 'legacy TR only'}) {
  return CardDetailContent(
    id: id,
    name: 'x',
    displayNameTr: 'x',
    imageAsset: 'x',
    arcanaType: 'Major Arcana',
    element: 'Hava',
    planet: 'Ay',
    zodiac: 'Kova',
    number: id,
    keywords: const [],
    accentColor: const Color(0xFF000000),
    meanings: const CardMeaningSections(
      general: '',
      upright: '',
      reversed: '',
      love: '',
      career: '',
      money: '',
      spiritual: '',
      health: '',
      personality: '',
      shadow: '',
      advice: '',
    ),
    symbols: const [],
    aiInsight: aiInsight,
    relatedIds: const [],
    heroTag: 't',
  );
}

void main() {
  tearDown(() => OraclyL10n.bind(AppLocale.tr));

  final content = CardDetailCatalogue.forId(0);
  final canonicalTr = CardDetailInsights.of(0)!.tr;

  test('TR aiInsight remains unchanged from canonical catalogue overlay', () {
    OraclyL10n.bind(AppLocale.tr);
    expect(CardDetailLocale.aiInsight(content), canonicalTr);
    expect(CardDetailLocale.aiInsight(content), content.aiInsight);
    expect(CardDetailLocale.aiInsight(content), contains('Deli kartı'));
  });

  test('EN aiInsight has no Turkish fallback', () {
    OraclyL10n.bind(AppLocale.en);
    final text = CardDetailLocale.aiInsight(content);
    expect(text, isNotEmpty);
    expect(text, isNot(equals(canonicalTr)));
    expect(_hasTurkish(text), isFalse);
    expect(text.toLowerCase(), contains('fool'));
  });

  test('RU aiInsight has no Turkish fallback', () {
    OraclyL10n.bind(AppLocale.ru);
    final text = CardDetailLocale.aiInsight(content);
    expect(text, isNotEmpty);
    expect(text, isNot(equals(canonicalTr)));
    expect(_hasTurkish(text), isFalse);
    expect(text, isNot(contains('Deli')));
  });

  test('all live major-card aiInsight entries resolve for TR EN RU', () {
    for (final card in CardDetailCatalogue.all) {
      OraclyL10n.bind(AppLocale.tr);
      final tr = CardDetailLocale.aiInsight(card);
      OraclyL10n.bind(AppLocale.en);
      final en = CardDetailLocale.aiInsight(card);
      OraclyL10n.bind(AppLocale.ru);
      final ru = CardDetailLocale.aiInsight(card);
      expect(tr, isNotEmpty, reason: 'tr ${card.id}');
      expect(en, isNotEmpty, reason: 'en ${card.id}');
      expect(ru, isNotEmpty, reason: 'ru ${card.id}');
      expect(tr, card.aiInsight, reason: 'tr matches catalogue ${card.id}');
      expect(_hasTurkish(en), isFalse, reason: 'en ${card.id} $en');
      expect(_hasTurkish(ru), isFalse, reason: 'ru ${card.id} $ru');
      expect(en, isNot(equals(tr)));
      expect(ru, isNot(equals(tr)));
    }
  });

  test('missing overlay fails safe without showing catalogue TR in other locales', () {
    expect(CardDetailInsights.of(999), isNull);
    final orphan = _stub(id: 999, aiInsight: 'Sadece Türkçe metin ğüşıöç');
    OraclyL10n.bind(AppLocale.en);
    expect(CardDetailLocale.aiInsight(orphan), isEmpty);
    OraclyL10n.bind(AppLocale.ru);
    expect(CardDetailLocale.aiInsight(orphan), isEmpty);
    OraclyL10n.bind(AppLocale.tr);
    expect(CardDetailLocale.aiInsight(orphan), isEmpty);
  });
}
