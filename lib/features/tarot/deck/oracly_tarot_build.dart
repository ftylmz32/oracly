/// Compact card constructor — assets filled from id geometry.
library;

import '../../../core/l10n/l10n_triple.dart';
import 'oracly_tarot_assets.dart';
import 'oracly_tarot_card.dart';
import 'oracly_tarot_enums.dart';
import 'oracly_tarot_keywords.dart';
import 'oracly_tarot_meanings.dart';
import 'oracly_tarot_relations.dart';

OraclyTarotCard oraclyTarotCard({
  required String id,
  required int number,
  required OraclyTarotArcana arcana,
  required OraclyTarotSuit suit,
  required L10nTriple name,
  required OraclyTarotKeywords uprightKeywords,
  required OraclyTarotKeywords reversedKeywords,
  required OraclyTarotMeanings meanings,
  required OraclyTarotRelations relationshipWithOtherCards,
}) {
  return OraclyTarotCard(
    id: id,
    name: name,
    arcana: arcana,
    suit: suit,
    number: number,
    uprightKeywords: uprightKeywords,
    reversedKeywords: reversedKeywords,
    meanings: meanings,
    relationshipWithOtherCards: relationshipWithOtherCards,
    visualAsset: OraclyTarotAssets.visualFor(
      arcana: arcana,
      suit: suit,
      number: number,
    ),
  );
}
