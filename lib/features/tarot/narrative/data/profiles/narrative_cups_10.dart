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
    'A calm full table — shared belonging in a circle, not a forever claim.',
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
    'Someone may want to share a calm table within a real circle of belonging.',
    'Может хотеться жить спокойным общим столом внутри реального круга.',
  ),
  fear: L10nTriple(
    'Çemberin dağılması veya neşenin zorunlu görünmesi kaygı yaratabilir.',
    'The circle breaking, or joy looking obligatory, may cause unease.',
    'Тревогу может вызывать распад круга или вид обязательной радости.',
  ),
  relationshipDynamic: L10nTriple(
    'Duygusal esenlik, paylaşılan bir alanda birlikte tutulabilir; birden fazla kişinin sığdığı ortak bir çember kültürüdür.',
    'Emotional wellbeing may be held together in a shared field — a circle with room for more than one person.',
    'Эмоциональное благополучие может удерживаться вместе в общем поле — культуре круга, где есть место больше чем одному.',
  ),
  decisionDynamic: L10nTriple(
    'Önemli olan, bu ortak çemberin insanlarını zaman içinde gerçekten taşıyıp taşıyamayacağıdır, bugün yalnızca uyumlu görünüp görünmediği değil.',
    'What matters is whether this shared circle can actually hold its people over time, not whether it merely looks harmonious today.',
    'Важно, способен ли этот общий круг по-настоящему удерживать своих людей во времени, а не то, выглядит ли он гармоничным сегодня.',
  ),
  actionDirection: L10nTriple(
    'Sofrayı kurun ve çemberi koruyun; sıcaklığın, o an için düzenlenmiş bir dekordan değil, kalıcı bir şeyden gelmesine izin verin.',
    'Set the table and tend the circle, letting its warmth come from something lasting rather than from scenery arranged for the occasion.',
    'Накройте стол и берегите круг, позволяя его теплу исходить из чего-то прочного, а не из декораций, устроенных ради случая.',
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
