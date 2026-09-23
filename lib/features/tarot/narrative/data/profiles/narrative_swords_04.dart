/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeSwords04 = NarrativeCardProfile(
  canonicalCardId: 'swords_04',
  coreMeaning: L10nTriple(
    'Kının içindeki kılıcı anlatır; savaş bitmiş gibi değil, zihin için bir aradır.',
    'The sword in its sheath; not as if war ended, but an interval for the mind.',
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
    'A longing to lay a tired mind in a brief sheath-interval may surface.',
    'Может хотеться уложить усталый ум в краткий промежуток ножен.',
  ),
  fear: L10nTriple(
    'Molanın sonsuz çekilişe dönüşmesi veya düşüncenin hiç dinlenmemesi kaygı yaratabilir.',
    'The pause becoming endless withdrawal, or thought never resting, may cause unease.',
    'Тревогу может вызывать превращение паузы в вечный уход или мысль без отдыха.',
  ),
  relationshipDynamic: L10nTriple(
    'Sessiz bir ara, iki kişinin tam da ihtiyacı olan şey olabilir; dinlenmek, birbirinden kaybolmakla aynı şey değildir.',
    'A quiet interval can be exactly what two people need, and resting is not the same as disappearing from each other.',
    'Тихий промежуток может быть именно тем, что нужно двоим, и отдых — не то же самое, что исчезновение друг для друга.',
  ),
  decisionDynamic: L10nTriple(
    'Bilinçli bir zihin molası, burada gece kaygısından çıkan herhangi bir sonuçtan daha iyi işler.',
    'A conscious pause of the mind serves better here than any conclusion reached out of night worry.',
    'Сознательная пауза ума служит здесь лучше, чем любой вывод, сделанный из ночной тревоги.',
  ),
  actionDirection: L10nTriple(
    'Kılıcın kınında dinlenmesine izin verin, ama kaybolmak yerine ulaşılabilir kalın.',
    'Let the sword rest in its sheath while you stay reachable rather than vanishing.',
    'Позвольте мечу отдохнуть в ножнах, оставаясь при этом на связи, а не исчезая.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ölçülü bir kın, zihni savaş bitmeden dinlendirir.',
      'A measured sheath rests the mind without claiming war is over.',
      'Сдержанные ножны дают отдых уму, не объявляя войну оконченной.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [NarrativeKeywordIds.pause, NarrativeKeywordIds.restraint],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Mola hayattan kaçış uykusuna kayabilir veya dönüşü uyuşma çökene dek erteleyebilir.',
      'The pause may avoid life as escape-sleep, or delay return until numbness settles.',
      'Пауза может избегать жизни как сон-бегство или откладывать возвращение, пока не осядет онемение.',
    ),
    transforms: [ReversedTransformKind.avoidance, ReversedTransformKind.delay],
    keywordIds: [
      NarrativeKeywordIds.escape,
      NarrativeKeywordIds.delay,
      NarrativeKeywordIds.withdrawal,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.pause,
    NarrativeSymbolTags.silence,
    NarrativeSymbolTags.restraint,
  ],
  profileRevision: 1,
);
