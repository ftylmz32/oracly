/// Maps ritual card ids onto the localized 78-card catalogue.
library;

import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/l10n_triple.dart';
import 'oracly_tarot_card.dart';
import 'oracly_tarot_deck.dart';

abstract final class OraclyTarotBridge {
  OraclyTarotBridge._();

  static OraclyTarotCard? byRitualId(int id) {
    if (id >= 0 && id <= 21) {
      return OraclyTarotDeck.byId('major_${id.toString().padLeft(2, '0')}');
    }
    final minor = id - 22;
    if (minor < 0 || minor >= 56) return null;
    final suit = switch (minor ~/ 14) {
      0 => 'cups',
      1 => 'pentacles',
      2 => 'swords',
      _ => 'wands',
    };
    final n = (minor % 14) + 1;
    return OraclyTarotDeck.byId('${suit}_${n.toString().padLeft(2, '0')}');
  }

  static String meaning(int id, {required bool reversed, String? language}) {
    final card = byRitualId(id);
    if (card == null) return '';
    final code = AppLocale.normalize(language);
    return reversed
        ? card.challengeMeaning.of(code)
        : card.symbolicMeaning.of(code);
  }

  static List<String> keywords(int id, {String? language}) {
    final card = byRitualId(id);
    if (card == null) return const [];
    return card.uprightKeywords.of(AppLocale.normalize(language));
  }

  static String love(int id, {String? language}) =>
      _field(id, (c) => c.loveMeaning, language);

  static String career(int id, {String? language}) =>
      _field(id, (c) => c.careerMeaning, language);

  static String personal(int id, {String? language}) =>
      _field(id, (c) => c.personalMeaning, language);

  static String _field(
    int id,
    L10nTriple Function(OraclyTarotCard) pick,
    String? language,
  ) {
    final card = byRitualId(id);
    if (card == null) return '';
    return pick(card).of(AppLocale.normalize(language));
  }
}
