/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands12 = NarrativeCardProfile(
  canonicalCardId: 'wands_12',
  coreMeaning: L10nTriple(
    'Hareket halindeki ateşi anlatır; varış noktası henüz ev değildir.',
    'Fire in motion; the destination is not yet home.',
    'Говорит об огне в движении; место прибытия ещё не дом.',
  ),
  light: L10nTriple(
    'İleri giden tutku, yakmadan yol açan canlı bir yön duygusu yaratabilir.',
    'Forward passion can create a lively sense of heading without burning the path.',
    'Страсть вперёд может создать живое чувство курса, не сжигая путь.',
  ),
  shadow: L10nTriple(
    'Yol, acele, dağınık tutku veya kaçış olarak giyinebilir.',
    'The road may dress as haste, scattered passion, or escape.',
    'Дорога может одеться спешкой, рассеянной страстью или бегством.',
  ),
  tension: L10nTriple(
    'İlerleme ateşi ile köklenme ayrı işini unutmama ihtiyacı çekişir.',
    'Forward fire contends with remembering that taking root is another task.',
    'Огонь вперёд спорит с памятью о том, что укоренение — другое дело.',
  ),
  desire: L10nTriple(
    'Kişi, duramayan bir ısıyı anlamlı bir yola dönüştürmek isteyebilir.',
    'Turning restless heat into a meaningful road may become important.',
    'Может хотеться превратить неспокойный жар в осмысленную дорогу.',
  ),
  fear: L10nTriple(
    'Yolda yanmak, hiçbir yere varmamak veya kaçıyor olmak kaygı yaratabilir.',
    'Burning on the road, arriving nowhere, or merely escaping may cause unease.',
    'Тревогу может вызывать страх сгореть в пути, никуда не прибыть или просто бежать.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda coşku belirebilir; geçerken yakmadan ilerlemeyi önerir.',
    'Ardor may appear in a bond; it favors going forward without burning as you pass.',
    'В связи может явиться пыл; карта предлагает идти вперёд, не сжигая по пути.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, hareketi kaçıştan ayırır ve yönü net bir hedefe bağlar.',
    'The choice separates motion from escape and binds heading to a clear aim.',
    'Выбор отделяет движение от бегства и связывает курс с ясной целью.',
  ),
  actionDirection: L10nTriple(
    'İlerleyin, yönü seçin; yakarak geçmeyin.',
    'Go forward, choose a heading; do not pass by burning.',
    'Идите вперёд, выберите курс; не проходите сжигая.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yönlü hareket, ateşi ev sanmadan canlı bir yolculuğa çevirir.',
      'Directed motion turns fire into lively travel without mistaking it for home.',
      'Направленное движение превращает огонь в живой путь, не принимая его за дом.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['journey', 'passion', 'forwardFire'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Hareket aceleye, dağınık tutkuya veya savaş arayışına kayabilir.',
      'Motion may slide into haste, scattered passion, or seeking battle.',
      'Движение может стать спешкой, рассеянной страстью или поиском битвы.',
    ),
    transforms: [
      ReversedTransformKind.misdirection,
      ReversedTransformKind.avoidance,
    ],
    keywordIds: ['haste', 'scatteredPassion', 'seekingBattle'],
  ),
  symbolTags: [
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.desire,
    NarrativeSymbolTags.direction,
  ],
  profileRevision: 1,
);
