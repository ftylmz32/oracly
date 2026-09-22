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
    'It speaks of a calm full table; not a forever claim, but a field of shared circle.',
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
    'There may be a wish to live a calm shared table inside a real circle.',
    'Может хотеться жить спокойным общим столом внутри реального круга.',
  ),
  fear: L10nTriple(
    'Çemberin dağılması veya neşenin zorunlu görünmesi kaygı yaratabilir.',
    'The circle breaking, or joy looking obligatory, may cause unease.',
    'Тревогу может вызывать распад круга или вид обязательной радости.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda ortak aidiyet softça büyüyebilir; kişisel yeterden ayırmayı ister.',
    'Shared belonging may grow softly in a bond; it asks to separate that from personal enough.',
    'В связи может мягко расти общая принадлежность; карта просит отделить её от личной достаточности.',
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
      'Sofrada ideal sahne, zorlanmış neşe veya gizlenen çatlaklar baskınlaşabilir.',
      'Ideal stage, forced joy, or hidden cracks may dominate the table.',
      'За столом могут возобладать идеальная сцена, вынужденная радость или скрытые трещины.',
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
