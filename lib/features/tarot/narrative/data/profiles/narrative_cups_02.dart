/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

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
    'Without balance, meeting can become imbalance, projection, or hasty union.',
    'Встреча может стать дисбалансом, проекцией или поспешным союзом.',
  ),
  tension: L10nTriple(
    'Yakınlaşma çekimi ile henüz içmeme ihtiyacı birlikte hissedilir.',
    'The pull toward closeness coexists with the need not to drink yet.',
    'Тяга к близости соседствует с нуждой ещё не пить.',
  ),
  desire: L10nTriple(
    'Kişi, karşılıklı bir duygusal alışverişi güvenle denemek isteyebilir.',
    'Here the reach is to try mutual emotional exchange in safety.',
    'Может хотеться безопасно попробовать взаимный эмоциональный обмен.',
  ),
  fear: L10nTriple(
    'Tek taraflı kalmak, yanlış okumak veya acele bağlanmak kaygı yaratabilir.',
    'Remaining one-sided, misreading, or bonding too fast may cause unease.',
    'Тревогу может вызывать односторонность, неверное прочтение или слишком быстрая связь.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda karşılıklılık yoklanır; sunuyu içme zorunluluğundan ayırmayı ister.',
    'Reciprocity is tested in a bond; it asks to separate offer from obligation to drink.',
    'В связи проверяется взаимность; карта просит отделить предложение от обязанности пить.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, acele birleşmeden önce iki tarafın da gerçekten sunduğunu karşılaştırmaya yaslanır.',
    'The choice leans on comparing what each side truly offers before a hasty merge.',
    'Выбор опирается на сравнение того, что реально предлагает каждая сторона, до поспешного слияния.',
  ),
  actionDirection: L10nTriple(
    'Sunulan kadehi görün, karşılıklılığı karşılaştırın; henüz acele içmeyin.',
    'See the offered cup, compare reciprocity; do not drink in haste yet.',
    'Увидьте предложенную чашу, сравните взаимность; ещё не пейте второпях.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sakin bir karşılıklılık, iki kadehi acele birleşmeden buluşturur.',
      'Calm reciprocity brings two cups together without forcing a merge.',
      'Спокойная взаимность сводит две чаши, не форсируя слияние.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['twoCups', 'reciprocity', 'offeredCup'],
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
    keywordIds: ['imbalance', 'projection', 'hastyUnion'],
  ),
  symbolTags: [
    NarrativeSymbolTags.union,
    NarrativeSymbolTags.choice,
    NarrativeSymbolTags.belonging,
  ],
  profileRevision: 1,
);
