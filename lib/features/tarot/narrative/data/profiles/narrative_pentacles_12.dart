/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles12 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_12',
  coreMeaning: L10nTriple(
    'Saban temposunu anlatır; öğrenme değil, kararlı ve yavaş ilerleyen çabadır.',
    'It speaks of field-tempo; not learning alone, but steadfast effort moving at a plough\'s pace.',
    'Говорит о темпе поля; не об одном учении, а о стойком усилии в темпе плуга.',
  ),
  light: L10nTriple(
    'Yavaş ve sürekli ilerlemek, acele yıkımdan daha dayanıklı iz bırakabilir.',
    'Moving slowly and steadily can leave a more durable trace than rushing to ruin.',
    'Двигаться медленно и устойчиво может оставить более прочный след, чем спешка к разрушению.',
  ),
  shadow: L10nTriple(
    'Sebat, katılığa, hız korkusuna veya hiç sapmamaya kayabilir.',
    'Steadfastness may slide into rigidity, fear of speed, or never turning aside.',
    'Стойкость может стать жёсткостью, страхом скорости или отказом свернуть.',
  ),
  tension: L10nTriple(
    'İstikrarlı gidiş isteği ile esneklik ihtiyacı çekişir.',
    'The wish for steady going contends with the need for flexibility.',
    'Желание устойчивого хода спорит с нуждой в гибкости.',
  ),
  desire: L10nTriple(
    'Kişi, yolun güvenilir ve kırılmadan sürmesini isteyebilir.',
    'There may be a wish for the road to hold reliable and unbroken.',
    'Может хотеться, чтобы дорога держалась надёжной и неразрывной.',
  ),
  fear: L10nTriple(
    'Yolun bozulması veya aceleyle kaymak kaygı yaratabilir.',
    'The road breaking, or slipping through haste, may cause unease.',
    'Тревогу может вызывать поломка пути или срыв от спешки.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda güvenilir tempo belirebilir; sebatı katılıktan ayırmayı ister.',
    'A reliable tempo may appear in a bond; it asks to separate steadfastness from rigidity.',
    'В связи может явиться надёжный темп; карта просит отделить стойкость от жёсткости.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, merak denemesinden ayrı, hangi adımın sürdürüleceğini netleştirir.',
    'The choice clarifies which step to keep, apart from a curiosity trial alone.',
    'Выбор проясняет, какой шаг держать, отдельно от одного лишь испытания любопытства.',
  ),
  actionDirection: L10nTriple(
    'Alan temposunda ilerleyin; katılığa düşmeyin, istikrarlı çabayı sürdürün.',
    'Advance at field-tempo; do not harden into rigidity — continue steady effort.',
    'Идите в темпе поля; не твердейте в жёсткость — продолжайте устойчивое усилие.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Kararlı tempo, çabayı acele ve katılıktan ayırır.',
      'Steadfast tempo separates effort from haste and from rigidity.',
      'Стойкий темп отделяет усилие от спешки и от жёсткости.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['slowRoad', 'fieldTempo', 'steadfastness'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sebat katılığa, hız korkusuna veya hiç sapmamaya kayabilir.',
      'Steadfastness may slide into rigidity, fear of speed, or never turning.',
      'Стойкость может стать жёсткостью, страхом скорости или отказом свернуть.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: ['rigidity', 'fearOfSpeed', 'noTurn'],
  ),
  symbolTags: [
    NarrativeSymbolTags.endurance,
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.stability,
  ],
  profileRevision: 1,
);
