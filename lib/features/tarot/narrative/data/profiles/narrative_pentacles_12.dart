/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativePentacles12 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_12',
  coreMeaning: L10nTriple(
    'Saban temposunu anlatır; öğrenme değil, kararlı ve yavaş ilerleyen çabadır.',
    'The center is field-tempo — steadfast effort moving at a plough\'s pace, rather than learning alone.',
    'Говорит о темпе поля; не об одном учении, а о стойком усилии в темпе плуга.',
  ),
  light: L10nTriple(
    'Yavaş ve sürekli ilerlemek, acele yıkımdan daha dayanıklı iz bırakabilir.',
    'Moving slowly and steadily can leave a more durable trace than rushing to ruin.',
    'Двигаться медленно и устойчиво может оставить более прочный след, чем спешка к разрушению.',
  ),
  shadow: L10nTriple(
    'Sebat, katılığa, hız korkusuna veya hiç sapmamaya kayabilir.',
    'When unbalanced, Steadfastness becomes rigidity, fear of speed, or never turning aside.',
    'Стойкость может стать жёсткостью, страхом скорости или отказом свернуть.',
  ),
  tension: L10nTriple(
    'İstikrarlı gidiş isteği ile esneklik ihtiyacı çekişir.',
    'The wish for steady going contends with the need for flexibility.',
    'Желание устойчивого хода спорит с нуждой в гибкости.',
  ),
  desire: L10nTriple(
    'Kişi, yolun güvenilir ve kırılmadan sürmesini isteyebilir.',
    'A need for the road to hold reliable and unbroken can become visible.',
    'Может хотеться, чтобы дорога держалась надёжной и неразрывной.',
  ),
  fear: L10nTriple(
    'Yolun bozulması veya aceleyle kaymak kaygı yaratabilir.',
    'The road breaking, or slipping through haste, may cause unease.',
    'Тревогу может вызывать поломка пути или срыв от спешки.',
  ),
  relationshipDynamic: L10nTriple(
    'Güvenilir ve istikrarlı bir tempo bir bağa yerleşebilir; gerçekten gerektiğinde eğilecek yeri bırakan bir sebatla.',
    'A reliable, steady tempo can settle into a bond, staying steadfast in a way that still leaves room to bend when it truly matters.',
    'Надёжный, ровный темп может установиться в связи — стойкость такого рода, что всё же оставляет место согнуться, когда это действительно нужно.',
  ),
  decisionDynamic: L10nTriple(
    'Hangi adımın gerçekten korunmaya değer olduğu, burada geçici bir merak denemesinden daha önemlidir.',
    'Which step is actually worth keeping matters more here than any passing trial of curiosity.',
    'Какой шаг действительно стоит сохранить, здесь важнее любого мимолётного испытания любопытства.',
  ),
  actionDirection: L10nTriple(
    'Tarlanın kendi temposunda ilerleyin; istikrarlı çabanın katılığa dönüşmeden sürmesine izin vererek.',
    'Advance at the field\'s own tempo, letting steady effort continue without hardening into rigidity.',
    'Двигайтесь в собственном темпе поля, позволяя устойчивому усилию продолжаться, не застывая в жёсткость.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Kararlı tempo, çabayı acele ve katılıktan ayırır.',
      'Steadfast tempo separates effort from haste and from rigidity.',
      'Стойкий темп отделяет усилие от спешки и от жёсткости.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.pause,
      NarrativeKeywordIds.timing,
      NarrativeKeywordIds.stability,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sebat aşırı katılığa sertleşebilir veya sapmayı engelleyerek yolu esnetilemez kılabilir.',
      'Steadfastness may harden into excess rigidity, or block turning aside until the path cannot flex.',
      'Стойкость может затвердеть в избыточную жёсткость или заблокировать поворот, пока путь не перестанет гнуться.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: [NarrativeKeywordIds.rigidity, NarrativeKeywordIds.stability],
  ),
  symbolTags: [
    NarrativeSymbolTags.endurance,
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.stability,
  ],
  profileRevision: 1,
);
