/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups07 = NarrativeCardProfile(
  canonicalCardId: 'cups_07',
  coreMeaning: L10nTriple(
    'Birçok kadehten hepsinin su taşımadığını anlatır; seçenek ve düş alanı, doyum değil.',
    'It speaks of many cups, not all holding water; a field of options and dream, not satisfaction.',
    'Говорит о многих чашах, не все из которых держат воду; поле вариантов и мечты, не удовлетворения.',
  ),
  light: L10nTriple(
    'Seçenekler görünürken, bir kadehe dokunmak düşü gerçeğe yaklaştırabilir.',
    'While options are visible, touching one cup can bring dream nearer to the real.',
    'Пока варианты видны, касание одной чаши может приблизить мечту к реальному.',
  ),
  shadow: L10nTriple(
    'Bakış yalnızca izlemeye, kaçış düşüne veya kararsızlığa kayabilir.',
    'Gaze may slide into watching only, escape-dream, or indecision.',
    'Взгляд может стать только наблюдением, мечтой-бегством или нерешительностью.',
  ),
  tension: L10nTriple(
    'Çok olasılığın çekimi ile birini seçme ihtiyacı çekişir.',
    'The pull of many possibilities contends with the need to choose one.',
    'Притяжение многих возможностей спорит с нуждой выбрать одну.',
  ),
  desire: L10nTriple(
    'Kişi, hayali bozmadan gerçek bir seçeneğe dokunmak isteyebilir.',
    'There may be a wish to touch a real option without shattering the dream.',
    'Может хотеться коснуться реального варианта, не разрушая мечту.',
  ),
  fear: L10nTriple(
    'Yanlış kadehi seçmek veya hiç dokunamamak kaygı yaratabilir.',
    'Choosing the wrong cup, or never touching any, may cause unease.',
    'Тревогу может вызывать выбор неверной чаши или невозможность коснуться ни одной.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda umut öteye yüklenebilir; düşü karşılıklı gerçekten ayırmayı ister.',
    'Hope may be placed on the other; it asks to separate dream from mutual reality.',
    'Надежда может быть возложена на другого; карта просит отделить мечту от взаимной реальности.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, tüm kadehleri seyretmek yerine su taşıyanı ayırt etmeye yaslanır.',
    'The choice leans on telling which cup holds water, not on watching them all.',
    'Выбор опирается на различение чаши с водой, а не на наблюдение за всеми.',
  ),
  actionDirection: L10nTriple(
    'Seçenekleri görün, bir kadehe dokunun; yalnızca izlemeyin.',
    'See the options, touch one cup; do not only watch.',
    'Увидьте варианты, коснитесь одной чаши; не только наблюдайте.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bilinçli bir dokunuş, çok kadeh arasından su taşıyanı ayırt eder.',
      'A conscious touch distinguishes which among many cups holds water.',
      'Осознанное касание различает среди многих чаш ту, что держит воду.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['manyCups', 'options', 'touchOne'],
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
    keywordIds: ['escapeDream', 'indecision', 'mirage'],
  ),
  symbolTags: [
    NarrativeSymbolTags.illusion,
    NarrativeSymbolTags.desire,
    NarrativeSymbolTags.choice,
  ],
  profileRevision: 1,
);
