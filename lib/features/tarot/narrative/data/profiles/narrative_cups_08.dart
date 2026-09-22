/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups08 = NarrativeCardProfile(
  canonicalCardId: 'cups_08',
  coreMeaning: L10nTriple(
    'Geride bırakılan kadeh ve daha derin arayışı anlatır; aktif ayrılış alanıdır, durgunluk değil.',
    'A cup left behind and a deeper search; a field of active leaving, not pause.',
    'Говорит об оставленной чаше и более глубоком поиске; поле активного ухода, не паузы.',
  ),
  light: L10nTriple(
    'Ayrılış, yakmadan dönerek daha doğru bir yön bulmaya alan açabilir.',
    'Leaving can make room to find a truer heading by turning back without burning.',
    'Уход может дать место найти более верный курс, обернувшись без сожжения.',
  ),
  shadow: L10nTriple(
    'Ayrılış yakarak gitmeye, kaçışa veya yarım bırakılmış arayışa kayabilir.',
    'Departing by burning, escape, or a half-abandoned search can appear when Leaving goes too far.',
    'Уход может стать уходом сожжением, бегством или наполовину брошенным поиском.',
  ),
  tension: L10nTriple(
    'Geride bırakma gereği ile yakmadan dönme imkanı birlikte durur.',
    'The need to leave behind coexists with the chance to turn back without burning.',
    'Нужда оставить позади соседствует с возможностью обернуться без сожжения.',
  ),
  desire: L10nTriple(
    'Kişi, artık yetmeyen duygusal zemini dürüstçe terk etmek isteyebilir.',
    'Honest leave-taking may be sought — to leave an emotional ground that no longer holds, honestly.',
    'Может хотеться честно оставить эмоциональную почву, которая больше не держит.',
  ),
  fear: L10nTriple(
    'Yanlış bırakmak veya geri dönememek kaygı yaratabilir.',
    'Leaving wrongly, or being unable to return, may cause unease.',
    'Тревогу может вызывать неверный уход или невозможность вернуться.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda mesafe bilinçli bir ayrılışa kayabilir; yakmayı arayıştan ayırmayı ister.',
    'Distance in a bond may become conscious leaving; it asks to separate burning from searching.',
    'Дистанция в связи может стать сознательным уходом; карта просит отделить сожжение от поиска.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, duraklamaktan farklı olarak aktif bir ayrılışın gerekip gerekmediğini yoklar.',
    'The choice tests whether active leaving—not mere pause—is required.',
    'Выбор проверяет, нужен ли активный уход — а не просто пауза.',
  ),
  actionDirection: L10nTriple(
    'Geride bırakılanı fark edin, yönü seçin; yakarak gitmeyin.',
    'Notice what is left behind, choose a heading; do not leave by burning.',
    'Заметьте оставленное, выберите курс; не уходите сожжением.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bilinçli bir ayrılış, kadehi yakmadan daha derin bir arayışa çevirir.',
      'Conscious leaving turns from the cup toward a deeper search without burning.',
      'Сознательный уход поворачивает от чаши к более глубокому поиску без сожжения.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['cupLeft', 'deeperSearch', 'turning'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ayrılış yakarak gitmeye sapabilir veya dürüst arayışın ifadesini yarıda keserek engelleyebilir.',
      'Leaving may misdirect into dramatic burning, or block honest search by abandoning it halfway.',
      'Уход может сбиться в драматическое сожжение или заблокировать честный поиск, бросив его на середине.',
    ),
    transforms: [
      ReversedTransformKind.misdirection,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: ['burnLeave', 'escape', 'halfSearch'],
  ),
  symbolTags: [
    NarrativeSymbolTags.release,
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.threshold,
  ],
  profileRevision: 1,
);
