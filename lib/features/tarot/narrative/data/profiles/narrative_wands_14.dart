/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeWands14 = NarrativeCardProfile(
  canonicalCardId: 'wands_14',
  coreMeaning: L10nTriple(
    'Ateşi bir yöne çağıran sorumlu duruşu anlatır; yakarak yönetmek değildir.',
    'Not ruling by burning; the meaning is a responsible stance that calls fire into a heading.',
    'Говорит об ответственной позе, зовущей огонь в курс; не о правлении сжиганием.',
  ),
  light: L10nTriple(
    'Dışa verilen net yön, başkalarının ateşini söndürmeden vizyonu toplayabilir.',
    'Clear outward heading can gather vision without putting out others\' fire.',
    'Ясный внешний курс может собрать видение, не гася чужой огонь.',
  ),
  shadow: L10nTriple(
    'Yön, baskıya, egoya veya dinlememeye kayabilir.',
    'Heading may slide into pressure, ego, or not listening.',
    'Курс может стать давлением, эго или неслушанием.',
  ),
  tension: L10nTriple(
    'Liderlik isteği ile hem yön verip hem dinleme sorumluluğu birlikte durur.',
    'The wish to lead coexists with the duty both to give heading and to listen.',
    'Желание вести соседствует с долгом и давать курс, и слушать.',
  ),
  desire: L10nTriple(
    'Kişi, iradesini başkalarını yakmadan anlamlı bir yöne bağlamak isteyebilir.',
    'Binding will to a meaningful heading without burning others may be sought.',
    'Может хотеться связать волю с осмысленным курсом, не сжигая других.',
  ),
  fear: L10nTriple(
    'Etkisini kaybetmek, yalnız kalmak veya yönün baskıya dönüşmesi kaygı yaratabilir.',
    'Losing influence, standing alone, or heading becoming pressure may cause unease.',
    'Тревогу может вызывать утрата влияния, одиночество или превращение курса в давление.',
  ),
  relationshipDynamic: L10nTriple(
    'Bir bağ içinde net bir yön teklif edilebilir; bir teklif, dayatılan bir şeyden farklı kalır.',
    'A clear heading can be offered within a bond, and an offer stays different from something imposed.',
    'Внутри связи может быть предложено ясное направление, и предложение остаётся не тем же самым, что навязывание.',
  ),
  decisionDynamic: L10nTriple(
    'Vizyon, burada hesap verebilir bir niyete bağlı kaldığında ve dinlemeye yer bıraktığında değer taşır.',
    'Vision matters here when it stays tied to accountable intent and room to keep listening.',
    'Видение здесь имеет значение, если остаётся связанным с ответственным намерением и не исключает готовности слушать.',
  ),
  actionDirection: L10nTriple(
    'Net bir yön verin ve sorumluluğun nerede olduğunu adlandırın; başkalarını yakarak değil, yön göstererek liderlik edin.',
    'Give a clear heading and name where responsibility sits, leading through direction rather than through burning others.',
    'Дайте ясное направление и назовите, где лежит ответственность, — ведите через курс, а не через то, что обжигаете других.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sorumlu bir yön, ateşi dışarıda toplayarak baskısız bir rota sunar.',
      'Responsible direction gathers fire outwardly into a heading offered without pressure.',
      'Ответственное направление собирает огонь вовне в курс, предложенный без давления.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.direction,
      NarrativeKeywordIds.spark,
      NarrativeKeywordIds.perspective,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yön baskıya, egoya veya dinlememeye dönüşebilir.',
      'Heading may become pressure, ego, or refusal to listen.',
      'Курс может стать давлением, эго или отказом слушать.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: [
      NarrativeKeywordIds.externalDemand,
      NarrativeKeywordIds.boast,
      NarrativeKeywordIds.notListening,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.direction,
    NarrativeSymbolTags.accountability,
    NarrativeSymbolTags.will,
  ],
  profileRevision: 1,
);
