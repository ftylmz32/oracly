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
    'It speaks of a mature vessel that holds feeling; not a role that feels more, but a field of holding and discerning.',
    'Говорит о зрелом сосуде, держащем чувство; не о роли, что чувствует больше, а о поле удержания и различения.',
  ),
  light: L10nTriple(
    'Şefkat, boğulmadan duyguları tutarak başkasına alan açabilir.',
    'Compassion can hold feelings without drowning and make room for another.',
    'Сострадание может удерживать чувства, не тоня, и давать место другому.',
  ),
  shadow: L10nTriple(
    'Tutma taşmaya, sınır yokluğuna veya kurtarma saplantısına kayabilir.',
    'Holding may slide into overflow, no boundary, or rescuing.',
    'Удержание может стать переполнением, отсутствием границ или спасательством.',
  ),
  tension: L10nTriple(
    'Şefkatle tutma arzusu ile boğulmama ve sınır koruma ihtiyacı birlikte durur.',
    'The wish to hold with compassion coexists with the need not to drown and to keep a boundary.',
    'Желание держать с состраданием соседствует с нуждой не тонуть и беречь границу.',
  ),
  desire: L10nTriple(
    'Kişi, duyguları olgun bir kabın dinginliğiyle taşımak isteyebilir.',
    'There may be a wish to carry feelings with the calm of a mature vessel.',
    'Может хотеться нести чувства спокойствием зрелого сосуда.',
  ),
  fear: L10nTriple(
    'Taşmak, sınır kaybetmek veya başkasının duygusunda boğulmak kaygı yaratabilir.',
    'Overflowing, losing boundary, or drowning in another\'s feeling may cause unease.',
    'Тревогу может вызывать переполнение, утрата границы или утопление в чужом чувстве.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda tutan bir şefkat belirebilir; kurtarmayı tutmadan ayırmayı ister.',
    'Holding compassion may appear in a bond; it asks to separate rescuing from holding.',
    'В связи может возникнуть удерживающее сострадание; карта просит отделить спасательство от удержания.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, her acıyı üstlenmeden duygunun nerede tutulacağını ayırt eder.',
    'The choice discerns where feeling is held without taking on every pain.',
    'Выбор различает, где удерживается чувство, не принимая на себя каждую боль.',
  ),
  actionDirection: L10nTriple(
    'Tutun, şefkati koruyun; boğulmayın ve kurtarmayın.',
    'Hold, protect compassion; do not drown, and do not rescue.',
    'Удерживайте, берегите сострадание; не тоните и не спасайте.',
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
