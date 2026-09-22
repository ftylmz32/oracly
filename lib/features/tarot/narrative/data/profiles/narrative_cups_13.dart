/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups13 = NarrativeCardProfile(
  canonicalCardId: 'cups_13',
  coreMeaning: L10nTriple(
    'Duyguyu tutan olgun kabı anlatır; daha çok hisseden bir rol değil, tutma ve ayırt etme alanıdır.',
    'A mature vessel that holds feeling; not a role that feels more, but a field of holding and discerning.',
    'Говорит о зрелом сосуде, держащем чувство; не о роли, что чувствует больше, а о поле удержания и различения.',
  ),
  light: L10nTriple(
    'Şefkat, boğulmadan duyguları tutarak başkasına alan açabilir.',
    'Compassion can hold feelings without drowning and make room for another.',
    'Сострадание может удерживать чувства, не тоня, и давать место другому.',
  ),
  shadow: L10nTriple(
    'Tutma taşmaya, sınır yokluğuna veya kurtarma saplantısına kayabilir.',
    'Holding can tip into overflow, vanished boundaries, or rescuing.',
    'Удержание может стать переполнением, отсутствием границ или спасательством.',
  ),
  tension: L10nTriple(
    'Şefkatle tutma arzusu ile boğulmama ve sınır koruma ihtiyacı birlikte durur.',
    'The wish to hold with compassion coexists with the need not to drown and to keep a boundary.',
    'Желание держать с состраданием соседствует с нуждой не тонуть и беречь границу.',
  ),
  desire: L10nTriple(
    'Kişi, duyguları olgun bir kabın dinginliğiyle taşımak isteyebilir.',
    'Quietly, one may seek to carry feelings with the calm of a mature vessel.',
    'Может хотеться нести чувства спокойствием зрелого сосуда.',
  ),
  fear: L10nTriple(
    'Taşmak, sınır kaybetmek veya başkasının duygusunda boğulmak kaygı yaratabilir.',
    'Overflowing, losing boundary, or drowning in another\'s feeling may cause unease.',
    'Тревогу может вызывать переполнение, утрата границы или утопление в чужом чувстве.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasında tutan bir şefkat gelişebilir; birini tutmak, onu kurtarmaya çalışmaktan farklı bir şeydir.',
    'A compassion that holds can grow between two people, and holding someone stays different from rescuing them.',
    'Между двумя людьми может расти удерживающее сострадание, и удерживать кого-то — не то же самое, что его спасать.',
  ),
  decisionDynamic: L10nTriple(
    'Duygunun nerede tutulabileceğini ayırt etmek, yoldan geçen her acıyı üstlenmekten daha değerlidir.',
    'Discerning where feeling can be held matters more than taking on every pain that passes by.',
    'Различить, где можно удержать чувство, важнее, чем брать на себя каждую проходящую боль.',
  ),
  actionDirection: L10nTriple(
    'Şefkatin sizden istediğini tutun, ama kendi zemininizi de koruyun; ne boğulun ne de kurtarmaya koşun.',
    'Hold what compassion asks of you while keeping your own footing, neither drowning in it nor rushing to rescue.',
    'Держите то, что просит от вас сострадание, но не теряйте собственную опору — не тоните и не бросайтесь спасать.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Olgun bir kap, duyguyu sınırla tutarak şefkati boğulmadan taşır.',
      'A mature vessel carries compassion by holding feeling with a boundary, without drowning.',
      'Зрелый сосуд несёт сострадание, удерживая чувство с границей, не тоня.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['matureVessel', 'compassion', 'holding'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Tutma kurtarma saplantısında taşabilir veya sınır eksikliğine incelenebilir.',
      'Holding may overflow in excess rescue, or thin into a deficiency of boundary.',
      'Удержание может переполниться избыточным спасательством или истончиться до дефицита границ.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.deficiency,
    ],
    keywordIds: ['overflow', 'noBoundary', 'rescuing'],
  ),
  symbolTags: [
    NarrativeSymbolTags.compassion,
    NarrativeSymbolTags.nurture,
    NarrativeSymbolTags.balance,
  ],
  profileRevision: 1,
);
