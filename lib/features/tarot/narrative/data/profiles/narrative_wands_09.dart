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
    'The last guarded spark; the path is not finished.',
    'Говорит о последней охраняемой искре; путь ещё не окончен.',
  ),
  light: L10nTriple(
    'Nöbet tutan dayanıklılık, kalkanı düşürmeden dinlenmeye alan açabilir.',
    'Endurance on watch can make room for rest without dropping the shield.',
    'Стойкость на дозоре может открыть место отдыху, не бросая щит.',
  ),
  shadow: L10nTriple(
    'Nöbet, tükenmişlik, şüphe veya yalnız savaş anlatısına kayabilir.',
    'The watch can tip into exhaustion, doubt, or a lone-war story.',
    'Дозор может стать истощением, сомнением или повестью одинокой войны.',
  ),
  tension: L10nTriple(
    'Dinlenme ihtiyacı ile kalkanı bırakmama zorunluluğu birlikte hissedilir.',
    'The need to rest coexists with the sense that the shield cannot be dropped.',
    'Нужда отдохнуть соседствует с чувством, что щит нельзя бросить.',
  ),
  desire: L10nTriple(
    'Kişi, yorgun olsa da son ateşini kaybetmeden ayakta kalmak isteyebilir.',
    'Staying standing without losing the last fire — even while tired — may be the aim.',
    'Может хотеться устоять, не теряя последний огонь, даже в усталости.',
  ),
  fear: L10nTriple(
    'Çökmek, kimseye güvenememek veya son kıvılcığı da kaybetmek kaygı yaratabilir.',
    'Collapsing, trusting no one, or losing even the last spark may cause unease.',
    'Тревогу может вызывать страх обвала, недоверия ко всем или утраты даже последней искры.',
  ),
  relationshipDynamic: L10nTriple(
    'İnsanlar arasında yorgun bir sadakat belirebilir; tetikte kalmak, tek başına verilen bir savaş gibi hissettirmek zorunda değildir.',
    'A tired kind of loyalty can show up between people, and staying watchful does not have to feel like a war fought alone.',
    'Между людьми может проявиться усталая верность; бдительность не обязана ощущаться как война в одиночку.',
  ),
  decisionDynamic: L10nTriple(
    'Hâlâ korunması gereken ile artık bırakılabilecek yükü birbirinden ayırmak değerlidir.',
    'What still needs guarding and what load can finally be set down are worth telling apart.',
    'Стоит отличить то, что всё ещё нужно охранять, от ноши, которую уже можно опустить.',
  ),
  actionDirection: L10nTriple(
    'Kalkanı bırakmadan dinlenin ve bunun tek başına yürütülen bir savaş olmasına son verin.',
    'Rest without dropping the shield, and let this stop being a war fought alone.',
    'Отдохните, не выпуская щит из рук, и перестаньте вести эту войну в одиночку.',
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
