/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

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
    'İki kişi arasındaki mesafe bilinçli bir ayrılışa dönüşebilir; böyle bir ayrılış, arkasında kalanı yakmak yerine dürüstçe daha fazlasını arar.',
    'Distance between two people can turn into a conscious leaving, one that searches honestly for more instead of burning what is behind it.',
    'Дистанция между людьми может стать осознанным уходом — таким, что честно ищет большего, вместо того чтобы сжигать оставленное позади.',
  ),
  decisionDynamic: L10nTriple(
    'Bu anın sınadığı şey, yalnızca bir mola değil, gerçekten aktif bir ayrılışın gerekip gerekmediğidir.',
    'What this moment tests is whether an active leaving is actually required, rather than a mere pause.',
    'Этот момент проверяет, действительно ли нужен активный уход, а не просто пауза.',
  ),
  actionDirection: L10nTriple(
    'Geride bıraktığınızı fark edin ve köprüyü yakmadan sizi ileri taşıyacak bir yön seçin.',
    'Notice what you are leaving behind and choose a heading that carries you forward without burning the bridge.',
    'Заметьте, что вы оставляете позади, и выберите курс, который несёт вас вперёд, не сжигая мост.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bilinçli bir ayrılış, kadehi yakmadan daha derin bir arayışa çevirir.',
      'Conscious leaving turns from the cup toward a deeper search without burning.',
      'Сознательный уход поворачивает от чаши к более глубокому поиску без сожжения.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.withdrawal,
      NarrativeKeywordIds.inquiry,
      NarrativeKeywordIds.change,
    ],
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
    keywordIds: [NarrativeKeywordIds.escape, NarrativeKeywordIds.inquiry],
  ),
  symbolTags: [
    NarrativeSymbolTags.release,
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.threshold,
  ],
  profileRevision: 1,
);
