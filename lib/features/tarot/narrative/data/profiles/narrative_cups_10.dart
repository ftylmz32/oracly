/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups10 = NarrativeCardProfile(
  canonicalCardId: 'cups_10',
  coreMeaning: L10nTriple(
    'Sakin dolu sofrayı anlatır; sonsuzluk iddiası değil, paylaşılan çember alanıdır.',
    'What holds here is a calm full table: a field of shared circle, not a forever claim.',
    'Говорит о спокойном полном столе; не о вечной претензии, а о поле общего круга.',
  ),
  light: L10nTriple(
    'Ortak sofra kurulduğunda, sahne dekoru olmadan aidiyet softça tutulabilir.',
    'When a shared table is set, belonging can be held softly without stage scenery.',
    'Когда общий стол накрыт, принадлежность можно держать мягко, без сценических декораций.',
  ),
  shadow: L10nTriple(
    'Sofrada ideal sahne, zorlanmış neşe veya çatlakları gizleme belirebilir.',
    'An ideal stage, forced joy, or hiding cracks may appear at the table.',
    'За столом могут возникнуть идеальная сцена, вынужденная радость или сокрытие трещин.',
  ),
  tension: L10nTriple(
    'Paylaşılan aidiyet arzusu ile sonsuzluk sahnelemeden koruma ihtiyacı çekişir.',
    'The wish for shared belonging contends with the need to protect it from forever staging.',
    'Желание общей принадлежности спорит с нуждой уберечь её от постановки вечности.',
  ),
  desire: L10nTriple(
    'Kişi, gerçek bir çemberde sakin bir ortak sofrayı yaşamak isteyebilir.',
    'The longing is to live a calm shared table inside a real circle.',
    'Может хотеться жить спокойным общим столом внутри реального круга.',
  ),
  fear: L10nTriple(
    'Çemberin dağılması veya neşenin zorunlu görünmesi kaygı yaratabilir.',
    'The circle breaking, or joy looking obligatory, may cause unease.',
    'Тревогу может вызывать распад круга или вид обязательной радости.',
  ),
  relationshipDynamic: L10nTriple(
    'Duygusal esenlik, paylaşılan bir alanda birlikte tutulabilir; birden fazla kişinin sığdığı ortak bir çember kültürüdür.',
    'Emotional wellbeing may be held together in a shared field — a circle-culture with room for more than one person.',
    'Эмоциональное благополучие может удерживаться вместе в общем поле — культуре круга, где есть место больше чем одному.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, sahne dekoru yerine sofranın gerçekten taşıyıp taşımadığını yoklar.',
    'The choice tests whether the table truly holds, rather than scenery.',
    'Выбор проверяет, держит ли стол по-настоящему, а не декорации.',
  ),
  actionDirection: L10nTriple(
    'Sofrayı kurun, çemberi koruyun; sahne dekoru yapmayın.',
    'Set the table, protect the circle; do not stage scenery.',
    'Накройте стол, берегите круг; не устраивайте сценических декораций.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sakin bir çember, dolu sofrayı sonsuzluk iddiası olmadan tutar.',
      'A calm circle holds a full table without a forever claim.',
      'Спокойный круг держит полный стол без претензии на вечность.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['fullTable', 'sharedCircle', 'calmBelonging'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Aidiyet çatlakları gizleyen ideal sahneye çarpıtılabilir veya sofrada zorlanmış neşede şişebilir.',
      'Belonging may distort into an ideal stage that hides cracks, or swell into excess forced joy at the table.',
      'Принадлежность может исказиться в идеальную сцену, скрывающую трещины, или раздуться в избыточную вынужденную радость за столом.',
    ),
    transforms: [
      ReversedTransformKind.distortion,
      ReversedTransformKind.excess,
    ],
    keywordIds: ['idealStage', 'forcedJoy', 'hiddenCracks'],
  ),
  symbolTags: [
    NarrativeSymbolTags.belonging,
    NarrativeSymbolTags.union,
    NarrativeSymbolTags.joy,
  ],
  profileRevision: 1,
);
