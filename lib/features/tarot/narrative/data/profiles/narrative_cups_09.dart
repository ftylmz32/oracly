/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups09 = NarrativeCardProfile(
  canonicalCardId: 'cups_09',
  coreMeaning: L10nTriple(
    'Dolu kadehi sahnelenmiş mutluluk değil, kişisel yeterlilik olarak anlatır.',
    'A full cup as personal enough, not staged happiness.',
    'Говорит о полной чаше как о личной достаточности, не о показном счастье.',
  ),
  light: L10nTriple(
    'İçerdeki yeter, sergilenmeden tadıldığında dingin bir doyum bırakabilir.',
    'Inner enough, when tasted rather than displayed, can leave quiet satisfaction.',
    'Внутреннее достаточное, когда его вкушают, а не показывают, может оставить тихое удовлетворение.',
  ),
  shadow: L10nTriple(
    'Doyum şişmeye, yalnız zafere veya sergilenmiş mutluluğa kayabilir.',
    'Satisfaction can tip into inflation, lone victory, or happiness put on display.',
    'Удовлетворение может стать раздутостью, одиночной победой или показным счастьем.',
  ),
  tension: L10nTriple(
    'Kişisel yeteri koruma ile paylaşım sahnesine çıkmama ihtiyacı birlikte durur.',
    'Protecting personal enough coexists with the need not to climb a sharing stage.',
    'Защита личной достаточности соседствует с нуждой не выходить на сцену обмена.',
  ),
  desire: L10nTriple(
    'Kişi, duygusal bir doluluğu kendi içinde sakinçe tatmak isteyebilir.',
    'Calm emotional fullness within oneself may be what is sought.',
    'Может хотеться спокойно вкусить эмоциональную полноту внутри себя.',
  ),
  fear: L10nTriple(
    'Doluluğun kaybolması veya yalnız kalmış bir zafer gibi görünmesi kaygı yaratabilir.',
    'Fullness vanishing, or looking like a lonely victory, may cause unease.',
    'Тревогу может вызывать исчезновение полноты или вид одиночной победы.',
  ),
  relationshipDynamic: L10nTriple(
    'Kişi, kendi duygusal doyumunu bağa getirebilir; ilişkiyi o doyumu üretmek için kullanmak zorunda kalmaz.',
    'One may bring personal emotional contentment into connection without needing the bond to manufacture that worth.',
    'Человек может принести в связь личную эмоциональную наполненность, не требуя, чтобы связь сама производила эту ценность.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, sahne etkisinden çok içerdeki gerçek doyumu yoklar.',
    'The choice tests real inner satisfaction more than stage effect.',
    'Выбор проверяет реальное внутреннее удовлетворение больше, чем сценический эффект.',
  ),
  actionDirection: L10nTriple(
    'Dolu kadehi tadın, yeteri koruyun; sergilemeyin.',
    'Taste the full cup, protect enough; do not display it.',
    'Вкусите полную чашу, берегите достаточное; не выставляйте её напоказ.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'İçerdeki yeter, dolu kadehi sahne olmadan dingin tutar.',
      'Inner enough keeps the full cup calm without making a stage of it.',
      'Внутренняя достаточность держит полную чашу спокойной, не превращая её в сцену.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['fullCup', 'innerEnough', 'quietTaste'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Doyum sergilemede şişebilir veya paylaşımı davet etmeyen özel bir zafere çekilebilir.',
      'Satisfaction may swell into excess display, or retreat privately into a lone victory that no longer invites sharing.',
      'Удовлетворение может раздуться в показной избыток или уйти внутрь в одиночную победу, уже не зовущую делиться.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.privateInternal,
    ],
    keywordIds: ['inflation', 'loneVictory', 'display'],
  ),
  symbolTags: [
    NarrativeSymbolTags.joy,
    NarrativeSymbolTags.abundance,
    NarrativeSymbolTags.solitude,
  ],
  profileRevision: 1,
);
