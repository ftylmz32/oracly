/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords05 = NarrativeCardProfile(
  canonicalCardId: 'swords_05',
  coreMeaning: L10nTriple(
    'Kazanılmış gibi duran boş bir kesiyi anlatır; söz savaşında neşe yoktur.',
    'A hollow cut that looks like winning; there is no joy in a war of words.',
    'Говорит о пустом разрезе, похожем на победу; в войне слов радости нет.',
  ),
  light: L10nTriple(
    'Kılıcı indirmek, puan saymayı bırakarak ilişkiyi koruyabilir.',
    'Lowering the sword can protect the bond by stopping the scorekeeping.',
    'Опустить меч может сберечь связь, перестав вести счёт.',
  ),
  shadow: L10nTriple(
    'Haklılık incitmeyi, intikamı veya yalnız kalmayı büyütmeye kayabilir.',
    'Rightness turns brittle when it becomes amplifying hurt, revenge, or being left alone.',
    'Правота может усиливать ранение, месть или одинокое оставление.',
  ),
  tension: L10nTriple(
    'Kazanma isteği ile bağın maliyetini görmeme riski çekişir.',
    'The wish to win contends with the risk of not seeing the cost to the bond.',
    'Желание победить спорит с риском не видеть цену для связи.',
  ),
  desire: L10nTriple(
    'Kişi, tartışmada üstün çıkmayı veya son sözü almayı isteyebilir.',
    'Coming out ahead in an argument — or taking the last word — may pull strongly.',
    'Может хотеться выйти впереди в споре или взять последнее слово.',
  ),
  fear: L10nTriple(
    'Kaybetmek, aşağılanmak veya yalnız kalmak kaygı yaratabilir.',
    'Losing, humiliation, or being left alone may cause unease.',
    'Тревогу может вызывать поражение, унижение или остаться одному.',
  ),
  relationshipDynamic: L10nTriple(
    'Haklı olmak bir bağı incitmeye başlayabilir; birini düşman ilan etmek, yalnızca puan tutmaktan çok farklı bir eylemdir.',
    'Being right can start to hurt a bond, and calling someone an enemy is a very different act from simply keeping score.',
    'Правота может начать ранить связь, и объявить кого-то врагом — совсем другое действие, чем просто вести счёт.',
  ),
  decisionDynamic: L10nTriple(
    'Bu sözlerin ilişkiye maliyeti, teknik olarak kimin kazandığından daha önemlidir.',
    'What these words cost the relationship matters more here than who technically wins.',
    'Цена этих слов для отношений значит здесь больше, чем то, кто формально победил.',
  ),
  actionDirection: L10nTriple(
    'Tartışmayı durdurun ve kılıcı indirin; puanın sayılmadan kalmasına izin verin.',
    'Pause the argument and lower the sword, letting the score stay uncounted.',
    'Приостановите спор и опустите меч, позволяя счёту остаться неподсчитанным.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'İndirilen kılıç, boş zaferi ilişki maliyetinden ayırır.',
      'A lowered sword separates hollow winning from relational cost.',
      'Опущенный меч отделяет пустую победу от цены отношений.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['hollowWin', 'warOfWords', 'hurting'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Haklılık intikama, aşağılık hissine veya yalnızlığa kayabilir.',
      'Rightness may slide into revenge, humiliation-feeling, or aloneness.',
      'Правота может стать местью, ощущением унижения или одиночеством.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: ['humiliation', 'revenge', 'beingLeft'],
  ),
  symbolTags: [
    NarrativeSymbolTags.friction,
    NarrativeSymbolTags.judgment,
    NarrativeSymbolTags.accountability,
  ],
  profileRevision: 1,
);
