/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands09 = NarrativeCardProfile(
  canonicalCardId: 'wands_09',
  coreMeaning: L10nTriple(
    'Korunan son kıvılcımı anlatır; bitmiş bir yol değildir.',
    'Here the field is the last guarded spark; the path is not finished.',
    'Говорит о последней охраняемой искре; путь ещё не окончен.',
  ),
  light: L10nTriple(
    'Nöbet tutan dayanıklılık, kalkanı düşürmeden dinlenmeye alan açabilir.',
    'Endurance on watch can make room for rest without dropping the shield.',
    'Стойкость на дозоре может открыть место отдыху, не бросая щит.',
  ),
  shadow: L10nTriple(
    'Nöbet, tükenmişlik, şüphe veya yalnız savaş anlatısına kayabilir.',
    'Pushed too far, the watch yields exhaustion, doubt, or a lone-war story.',
    'Дозор может стать истощением, сомнением или повестью одинокой войны.',
  ),
  tension: L10nTriple(
    'Dinlenme ihtiyacı ile kalkanı bırakmama zorunluluğu birlikte hissedilir.',
    'The need to rest coexists with the sense that the shield cannot be dropped.',
    'Нужда отдохнуть соседствует с чувством, что щит нельзя бросить.',
  ),
  desire: L10nTriple(
    'Kişi, yorgun olsa da son ateşini kaybetmeden ayakta kalmak isteyebilir.',
    'The energy leans toward trying to stay standing without losing the last fire, even while tired.',
    'Может хотеться устоять, не теряя последний огонь, даже в усталости.',
  ),
  fear: L10nTriple(
    'Çökmek, kimseye güvenememek veya son kıvılcığı da kaybetmek kaygı yaratabilir.',
    'Collapsing, trusting no one, or losing even the last spark may cause unease.',
    'Тревогу может вызывать страх обвала, недоверия ко всем или утраты даже последней искры.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda yorgun bir sadakat belirebilir; nöbeti yalnız savaş saymamayı önerir.',
    'Tired loyalty may appear in a bond; it asks not to treat watchfulness as lone war.',
    'В связи может явиться усталая верность; карта предлагает не читать дозор как одинокую войну.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, hâlâ korunması gereken ile bırakılabilecek yükü ayırt etmeyi ister.',
    'The choice asks to distinguish what still needs guarding from load that can be set down.',
    'Выбор просит отличить то, что ещё нужно охранять, от ноши, которую можно опустить.',
  ),
  actionDirection: L10nTriple(
    'Dinlenin, kalkanı koruyun; yalnız savaş ilan etmeyin.',
    'Rest, keep the shield; do not declare a lone war.',
    'Отдохните, сохраните щит; не объявляйте одинокую войну.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sessiz dayanıklılık, son kıvılcımı bitmiş saymadan nöbette tutar.',
      'Quiet endurance keeps the last spark on watch without calling it finished.',
      'Тихая стойкость держит последнюю искру на дозоре, не называя её концом.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['lastFire', 'watch', 'endurance'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Nöbet dayanıklılık ve şüphede incelenebilir veya özel bir yalnız savaş anlatısına içe çekilebilir.',
      'The watch may thin into deficient endurance and doubt, or internalize into a private lone-war story.',
      'Дозор может истончиться до недостаточной стойкости и сомнения или уйти внутрь в частную повесть одинокой войны.',
    ),
    transforms: [
      ReversedTransformKind.deficiency,
      ReversedTransformKind.internalization,
    ],
    keywordIds: ['exhaustion', 'doubt', 'loneWar'],
  ),
  symbolTags: [
    NarrativeSymbolTags.endurance,
    NarrativeSymbolTags.restraint,
    NarrativeSymbolTags.courage,
  ],
  profileRevision: 1,
);
