/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeCups07 = NarrativeCardProfile(
  canonicalCardId: 'cups_07',
  coreMeaning: L10nTriple(
    'Birçok kadehten hepsinin su taşımadığını anlatır; seçenek ve düş alanı, doyum değil.',
    'Many cups, not all holding water; a field of options and dream, not satisfaction.',
    'Говорит о многих чашах, не все из которых держат воду; поле вариантов и мечты, не удовлетворения.',
  ),
  light: L10nTriple(
    'Seçenekler görünürken, bir kadehe dokunmak düşü gerçeğe yaklaştırabilir.',
    'While options are visible, touching one cup can bring dream nearer to the real.',
    'Пока варианты видны, касание одной чаши может приблизить мечту к реальному.',
  ),
  shadow: L10nTriple(
    'Bakış yalnızca izlemeye, kaçış düşüne veya kararsızlığa kayabilir.',
    'Watching only, escape-dream, or indecision appears when Gaze dominates.',
    'Взгляд может стать только наблюдением, мечтой-бегством или нерешительностью.',
  ),
  tension: L10nTriple(
    'Çok olasılığın çekimi ile birini seçme ihtiyacı çekişir.',
    'The pull of many possibilities contends with the need to choose one.',
    'Притяжение многих возможностей спорит с нуждой выбрать одну.',
  ),
  desire: L10nTriple(
    'Kişi, hayali bozmadan gerçek bir seçeneğe dokunmak isteyebilir.',
    'Someone may long to touch a real option without shattering the dream.',
    'Может хотеться коснуться реального варианта, не разрушая мечту.',
  ),
  fear: L10nTriple(
    'Yanlış kadehi seçmek veya hiç dokunamamak kaygı yaratabilir.',
    'Choosing the wrong cup, or never touching any, may cause unease.',
    'Тревогу может вызывать выбор неверной чаши или невозможность коснуться ни одной.',
  ),
  relationshipDynamic: L10nTriple(
    'Umut bir başka kişiye ağır biçimde yaslandığında, kişisel bir düş, gerçekte olmadan çok önce karşılıklı bir gerçeklik gibi hissettirmeye başlayabilir.',
    'When hope leans heavily on another person, a private dream can start to feel like mutual reality long before it actually is.',
    'Когда надежда тяжело опирается на другого человека, личная мечта может начать ощущаться взаимной реальностью задолго до того, как ею действительно станет.',
  ),
  decisionDynamic: L10nTriple(
    'Hangi kadehin gerçekten su taşıdığını ayırt etmek, hepsini birden seyretmekten daha değerlidir.',
    'Telling which cup actually holds water matters more than watching all of them at once.',
    'Понять, какая чаша действительно держит воду, важнее, чем разглядывать их все разом.',
  ),
  actionDirection: L10nTriple(
    'Önünüzdeki seçenekleri görün ve yalnızca uzaktan izlemek yerine bir kadehe dokunmanıza izin verin.',
    'See the options laid out, and let yourself touch one cup instead of only watching from a distance.',
    'Увидьте разложенные варианты и позвольте себе коснуться одной чаши, а не только наблюдать издалека.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bilinçli bir dokunuş, çok kadeh arasından su taşıyanı ayırt eder.',
      'A conscious touch distinguishes which among many cups holds water.',
      'Осознанное касание различает среди многих чаш ту, что держит воду.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.overflow,
      NarrativeKeywordIds.choice,
      NarrativeKeywordIds.focus,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Seçenekler kaçış düşüne, kararsızlığa veya yanılsamaya kayabilir.',
      'Options may slide into escape-dream, indecision, or illusion.',
      'Варианты могут стать мечтой-бегством, нерешительностью или иллюзией.',
    ),
    transforms: [
      ReversedTransformKind.misdirection,
      ReversedTransformKind.delay,
    ],
    keywordIds: [
      NarrativeKeywordIds.escape,
      NarrativeKeywordIds.indecision,
      NarrativeKeywordIds.illusion,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.illusion,
    NarrativeSymbolTags.desire,
    NarrativeSymbolTags.choice,
  ],
  profileRevision: 1,
);
