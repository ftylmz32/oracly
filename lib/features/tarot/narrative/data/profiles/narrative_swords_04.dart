/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords04 = NarrativeCardProfile(
  canonicalCardId: 'swords_04',
  coreMeaning: L10nTriple(
    'Kının içindeki kılıcı anlatır; savaş bitmiş gibi değil, zihin için bir aradır.',
    'Not as if war ended: the sword in its sheath as an interval for the mind.',
    'Говорит о мече в ножнах; не будто война кончилась, а о промежутке для ума.',
  ),
  light: L10nTriple(
    'Kısa bir mola, düşünceyi dinlendirerek daha sakin bir dönüş hazırlayabilir.',
    'A brief pause can rest thought and prepare a calmer return.',
    'Краткая пауза может дать отдых мысли и подготовить более спокойное возвращение.',
  ),
  shadow: L10nTriple(
    'Mola kaçış uykuya, ertelemeye veya uyuşmaya kayabilir.',
    'Escape-sleep, delay, or numbness appears when The pause dominates.',
    'Пауза может стать сном-бегством, отсрочкой или онемением.',
  ),
  tension: L10nTriple(
    'Dinlenme ihtiyacı ile hayattan kaybolmama isteği birlikte durur.',
    'The need to rest coexists with the wish not to disappear from life.',
    'Нужда в отдыхе соседствует с желанием не исчезнуть из жизни.',
  ),
  desire: L10nTriple(
    'Kişi, yorgun zihni kısa bir kın aralığında yatırmak isteyebilir.',
    'The longing is to lay a tired mind in a brief sheath-interval.',
    'Может хотеться уложить усталый ум в краткий промежуток ножен.',
  ),
  fear: L10nTriple(
    'Molanın sonsuz çekilişe dönüşmesi veya düşüncenin hiç dinlenmemesi kaygı yaratabilir.',
    'The pause becoming endless withdrawal, or thought never resting, may cause unease.',
    'Тревогу может вызывать превращение паузы в вечный уход или мысль без отдыха.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda sessiz bir ara gerekebilir; kaybolmayı dinlenmeden ayırmayı ister.',
    'A quiet interval may be needed in a bond; it asks to separate disappearing from rest.',
    'В связи может быть нужен тихий промежуток; карта просит отделить исчезновение от отдыха.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, gece kaygısından ayrı, bilinçli bir zihin molasına yaslanır.',
    'The choice leans on a conscious mind-pause, apart from night worry.',
    'Выбор опирается на сознательную паузу ума, отдельно от ночной тревоги.',
  ),
  actionDirection: L10nTriple(
    'Kınına koyun; kaybolmayın.',
    'Sheathe; do not disappear.',
    'Вложите в ножны; не исчезайте.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ölçülü bir kın, zihni savaş bitmeden dinlendirir.',
      'A measured sheath rests the mind without claiming war is over.',
      'Сдержанные ножны дают отдых уму, не объявляя войну оконченной.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['rest', 'mindPause', 'sheath'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Mola hayattan kaçış uykusuna kayabilir veya dönüşü uyuşma çökene dek erteleyebilir.',
      'The pause may avoid life as escape-sleep, or delay return until numbness settles.',
      'Пауза может избегать жизни как сон-бегство или откладывать возвращение, пока не осядет онемение.',
    ),
    transforms: [ReversedTransformKind.avoidance, ReversedTransformKind.delay],
    keywordIds: ['escapeSleep', 'defer', 'numbness'],
  ),
  symbolTags: [
    NarrativeSymbolTags.pause,
    NarrativeSymbolTags.silence,
    NarrativeSymbolTags.restraint,
  ],
  profileRevision: 1,
);
