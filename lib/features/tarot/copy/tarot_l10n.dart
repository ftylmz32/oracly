/// Locale-aware tarot display names and reading fill-ins.
library;

import '../../../core/l10n/l10n.dart';
import '../domain/models/tarot_spread.dart';
import '../models/tarot_card.dart';

abstract final class TarotL10n {
  TarotL10n._();

  static String _t(String key) => OraclyL10n.t(key);

  static String fill(String key, [Map<String, String> vars = const {}]) {
    var out = _t(key);
    vars.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }

  static String cardName(int id, {String? fallback, String? language}) {
    final key = 'tarot.card.$id';
    final value = OraclyL10n.t(key, languageCode: language);
    if (value == key) return fallback ?? value;
    return value;
  }

  static String cardNameOf(TarotCard card) =>
      cardName(card.id, fallback: card.name);

  static String spreadFromStorage(String raw) {
    final type = TarotSpreadType.fromTitle(raw);
    return type == null ? raw : spread(type);
  }

  static String spread(TarotSpreadType type) => _t('tarot.spread.${type.name}');

  static String monthShort(int month) => _t('tarot.month.s.$month');

  static String monthLong(int month) => _t('tarot.month.l.$month');

  static String spreadBanner(TarotSpreadType type) =>
      _t('tarot.spread.${type.name}.banner');

  static String spreadReadingTitle(TarotSpreadType type) =>
      fill('tarot.spread.reading', {'spread': spread(type)});

  static String position(String key) => _t('tarot.pos.$key');

  static String suit(TarotSuit suit) => _t('tarot.suit.${suit.name}');

  static String orientation({required bool reversed}) =>
      reversed ? _t('tarot.reversed') : _t('tarot.upright');

  static String get deckName => _t('tarot.deck.classic');

  static String get deckDescription => _t('tarot.deck.classic.desc');

  static String get deckTag => _t('tarot.deck.classic.tag');

  static String get chooseDeck => _t('tarot.deck.choose');

  static String get genericGuidance => _t('tarot.guidance.generic');

  static String get keysLabel => _t('tarot.keys');

  static String get fallbackCards => _t('tarot.fallback.cards');

  static String get fallbackLoad => _t('tarot.fallback.load');
}
