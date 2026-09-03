/// Overlay localized deck / meta / symbolism / insight onto card-detail UI.
library;

import '../../../../../core/l10n/l10n.dart';
import '../../../deck/oracly_tarot_deck.dart';
import 'card_detail_insights.dart';
import 'card_detail_meta.dart';
import 'card_detail_models.dart';
import 'card_detail_symbols.dart';

abstract final class CardDetailLocale {
  CardDetailLocale._();

  static String _deckId(int id) =>
      "major_${id.toString().padLeft(2, '0')}";

  static List<String> keywords(CardDetailContent content) {
    final card = OraclyTarotDeck.byId(_deckId(content.id));
    if (card == null) return content.keywords;
    return card.uprightKeywords.of(OraclyL10n.code);
  }

  static String meaning({
    required int cardId,
    required CardMeaningSections sections,
    required String key,
  }) {
    final card = OraclyTarotDeck.byId(_deckId(cardId));
    if (card == null) return sections.textForKey(key);
    final triple = switch (key) {
      'general' || 'upright' => card.symbolicMeaning,
      'reversed' || 'shadow' => card.challengeMeaning,
      'love' => card.loveMeaning,
      'career' => card.careerMeaning,
      'money' => card.moneyMeaning,
      'personality' || 'spiritual' => card.personalMeaning,
      'advice' || 'health' => card.guidanceMeaning,
      _ => null,
    };
    return triple?.of(OraclyL10n.code) ?? sections.textForKey(key);
  }

  static String element(CardDetailContent content) =>
      CardDetailMeta.element(content.element);

  static String planet(CardDetailContent content) =>
      CardDetailMeta.planet(content.planet);

  static String zodiac(CardDetailContent content) =>
      CardDetailMeta.zodiac(content.zodiac);

  static List<CardSymbolEntry> symbols({
    required int cardId,
    required List<CardSymbolEntry> base,
  }) {
    final copies = CardDetailSymbols.of(cardId);
    if (copies == null || copies.length != base.length) {
      return base;
    }
    final code = OraclyL10n.code;
    return [
      for (var i = 0; i < base.length; i++)
        CardSymbolEntry(
          name: copies[i].name.of(code),
          icon: base[i].icon,
          description: copies[i].description.of(code),
        ),
    ];
  }

  /// Localized catalogue insight. Missing overlay → empty (never wrong language).
  static String aiInsight(CardDetailContent content) {
    final triple = CardDetailInsights.of(content.id);
    if (triple == null) return '';
    return triple.of(OraclyL10n.code);
  }
}
