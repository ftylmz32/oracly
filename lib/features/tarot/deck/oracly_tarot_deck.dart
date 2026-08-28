/// Canonical 78-card ORACLY Tarot deck — data only, no UI.
library;

import 'catalog/oracly_tarot_cups.dart';
import 'catalog/oracly_tarot_major_00_10.dart';
import 'catalog/oracly_tarot_major_11_21.dart';
import 'catalog/oracly_tarot_pentacles.dart';
import 'catalog/oracly_tarot_swords.dart';
import 'catalog/oracly_tarot_wands.dart';
import 'oracly_tarot_card.dart';
import 'oracly_tarot_enums.dart';

abstract final class OraclyTarotDeck {
  OraclyTarotDeck._();

  static const expectedCount = 78;
  static const expectedMajor = 22;
  static const expectedMinor = 56;

  static List<OraclyTarotCard> get all => [
        ...kOraclyTarotMajor00to10,
        ...kOraclyTarotMajor11to21,
        ...kOraclyTarotWands,
        ...kOraclyTarotCups,
        ...kOraclyTarotSwords,
        ...kOraclyTarotPentacles,
      ];

  static List<OraclyTarotCard> get majorArcana =>
      all.where((c) => c.isMajor).toList(growable: false);

  static List<OraclyTarotCard> get minorArcana =>
      all.where((c) => c.isMinor).toList(growable: false);

  static OraclyTarotCard? byId(String id) {
    for (final card in all) {
      if (card.id == id) return card;
    }
    return null;
  }

  static List<OraclyTarotCard> bySuit(OraclyTarotSuit suit) =>
      all.where((c) => c.suit == suit).toList(growable: false);

  static List<String> get expectedIds => [
        for (var i = 0; i < expectedMajor; i++)
          'major_${i.toString().padLeft(2, '0')}',
        for (final suit in ['wands', 'cups', 'swords', 'pentacles'])
          for (var n = 1; n <= 14; n++)
            '${suit}_${n.toString().padLeft(2, '0')}',
      ];
}
