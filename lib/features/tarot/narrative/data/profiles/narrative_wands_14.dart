/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands14 = NarrativeCardProfile(
  canonicalCardId: 'wands_14',
  coreMeaning: L10nTriple(
    'Ateşi bir yöne çağıran sorumlu duruşu anlatır; yakarak yönetmek değildir.',
    'It speaks of a responsible stance that calls fire into a heading; not ruling by burning.',
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
    'There may be a wish to bind will to a meaningful heading without burning others.',
    'Может хотеться связать волю с осмысленным курсом, не сжигая других.',
  ),
  fear: L10nTriple(
    'Etkisini kaybetmek, yalnız kalmak veya yönün baskıya dönüşmesi kaygı yaratabilir.',
    'Losing influence, standing alone, or heading becoming pressure may cause unease.',
    'Тревогу может вызывать утрата влияния, одиночество или превращение курса в давление.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda net bir yön teklifi belirebilir; teklifi dayatmadan ayırmayı ister.',
    'A clear heading may be offered in a bond; it asks to separate offer from imposition.',
    'В связи может быть предложен ясный курс; карта просит отделить предложение от навязывания.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, vizyonu hesap verebilir bir niyete bağlar ve dinlemeyi dışlamaz.',
    'The choice binds vision to accountable intent and does not exclude listening.',
    'Выбор связывает видение с ответственным намерением и не исключает слушания.',
  ),
  actionDirection: L10nTriple(
    'Yön verin, sorumluluğu netleştirin; yakarak yönetmeyin.',
    'Give heading, clarify responsibility; do not rule by burning.',
    'Дайте курс, проясните ответственность; не правьте сжигая.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sorumlu bir yön, ateşi dışarıda toplayarak baskısız bir rota sunar.',
      'Responsible direction gathers fire outwardly into a heading offered without pressure.',
      'Ответственное направление собирает огонь вовне в курс, предложенный без давления.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['directingFire', 'responsibleSpark', 'vision'],
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
    keywordIds: ['pressure', 'ego', 'notListening'],
  ),
  symbolTags: [
    NarrativeSymbolTags.direction,
    NarrativeSymbolTags.accountability,
    NarrativeSymbolTags.will,
  ],
  profileRevision: 1,
);
