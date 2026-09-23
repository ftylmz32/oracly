/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeCups02 = NarrativeCardProfile(
  canonicalCardId: 'cups_02',
  coreMeaning: L10nTriple(
    'İki kadehin buluşmasını anlatır; evlilik kehaneti değildir, karşılıklılık alanıdır.',
    'Two cups meeting names a field of reciprocity; it refuses a marriage prophecy.',
    'Говорит о встрече двух чаш; не о пророчестве брака, а о поле взаимности.',
  ),
  light: L10nTriple(
    'Sunulan kadeh görüldüğünde, acele içmeden karşılıklılık yoklanabilir.',
    'When the offered cup is seen, reciprocity can be tested without drinking at once.',
    'Когда предложенная чаша замечена, взаимность можно проверить, не выпивая сразу.',
  ),
  shadow: L10nTriple(
    'Buluşma, dengesizliğe, yansıtıma veya acele birleşmeye kayabilir.',
    'When unbalanced, Meeting becomes imbalance, projection, or hasty union.',
    'Встреча может стать дисбалансом, проекцией или поспешным союзом.',
  ),
  tension: L10nTriple(
    'Yakınlaşma çekimi ile henüz içmeme ihtiyacı birlikte hissedilir.',
    'The pull toward closeness coexists with the need not to drink yet.',
    'Тяга к близости соседствует с нуждой ещё не пить.',
  ),
  desire: L10nTriple(
    'Kişi, karşılıklı bir duygusal alışverişi güvenle denemek isteyebilir.',
    'It can feel important to try mutual emotional exchange in safety.',
    'Может хотеться безопасно попробовать взаимный эмоциональный обмен.',
  ),
  fear: L10nTriple(
    'Tek taraflı kalmak, yanlış okumak veya acele bağlanmak kaygı yaratabilir.',
    'Remaining one-sided, misreading, or bonding too fast may cause unease.',
    'Тревогу может вызывать односторонность, неверное прочтение или слишком быстрая связь.',
  ),
  relationshipDynamic: L10nTriple(
    'Karşılıklılık burada sınanır; bir teklif, içme zorunluluğundan farklı kalır.',
    'Reciprocity gets tested here, and an offer stays different from an obligation to drink.',
    'Здесь проверяется взаимность, и предложение остаётся не тем же самым, что обязанность выпить.',
  ),
  decisionDynamic: L10nTriple(
    'Her iki tarafın gerçekten ne sunduğu, aceleyle birleşmeden önce karşılaştırılmaya değer.',
    'What each side truly offers is worth comparing before any hasty merge.',
    'То, что действительно предлагает каждая сторона, стоит сравнить, прежде чем спешить со слиянием.',
  ),
  actionDirection: L10nTriple(
    'Sunulan kadehi görün ve içindeki karşılıklılığı, aceleyle içmeden önce tartın.',
    'See the offered cup and weigh the reciprocity in it before drinking in haste.',
    'Увидьте предложенную чашу и взвесьте заключённую в ней взаимность, прежде чем пить второпях.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sakin bir karşılıklılık, iki kadehi acele birleşmeden buluşturur.',
      'Calm reciprocity brings two cups together without forcing a merge.',
      'Спокойная взаимность сводит две чаши, не форсируя слияние.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.intimacy,
      NarrativeKeywordIds.reciprocity,
      NarrativeKeywordIds.opening,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Karşılıklılık yansıtıma çarpılabilir veya acele birleşme aşırıya kaçabilir.',
      'Reciprocity may distort into projection, or excess may rush a merge before both cups are truly offered.',
      'Взаимность может исказиться в проекцию, а избыток — поторопить слияние, пока обе чаши ещё не предложены по-настоящему.',
    ),
    transforms: [
      ReversedTransformKind.distortion,
      ReversedTransformKind.excess,
    ],
    keywordIds: [
      NarrativeKeywordIds.imbalance,
      NarrativeKeywordIds.projection,
      NarrativeKeywordIds.haste,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.union,
    NarrativeSymbolTags.choice,
    NarrativeSymbolTags.belonging,
  ],
  profileRevision: 1,
);
