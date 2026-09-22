/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles09 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_09',
  coreMeaning: L10nTriple(
    'Emeğin yeterliliğini anlatır; vitrin değil, bağımsız yeterlik alanıdır.',
    'The center is enough-ness from one\'s labor — a field of independent sufficiency, rather than a shop window.',
    'Говорит о достаточности от своего труда; не о витрине, а о поле самостоятельной достаточности.',
  ),
  light: L10nTriple(
    'Yeterliyi tanımak, sürekli daha fazlasını kanıtlamadan sükûnet getirebilir.',
    'Recognizing enough can bring quiet without proving more and more.',
    'Узнать достаточное может принести покой без доказательства всё большего.',
  ),
  shadow: L10nTriple(
    'Yeterlik, gösterişe, yalnızlığa kapanmaya veya paylaşmayı reddetmeye kayabilir.',
    'Display, shutting into solitude, or refusing to share appears when Sufficiency dominates.',
    'Достаточность может стать показом, замыканием в одиночестве или отказом делиться.',
  ),
  tension: L10nTriple(
    'Kendi emeğiyle yetinme isteği ile başkalarına açık kalma ihtiyacı çekişir.',
    'The wish to rest in one\'s own labor contends with the need to stay open to others.',
    'Желание покоиться в своём труде спорит с нуждой оставаться открытым другим.',
  ),
  desire: L10nTriple(
    'Kişi, elindekiyle huzurlu ve bağımsız durmayı isteyebilir.',
    'Standing at peace and independent with what is in hand may be sought.',
    'Может хотеться стоять спокойно и самостоятельно с тем, что в руке.',
  ),
  fear: L10nTriple(
    'Yetersiz görünmek veya yalnız kalmak kaygı yaratabilir.',
    'Looking insufficient, or being left alone, may cause unease.',
    'Тревогу может вызывать выглядеть недостаточным или остаться одному.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda kişisel yeterlik alanı belirebilir; vitrini sükûnetten ayırmayı ister.',
    'A field of personal sufficiency may appear in a bond; it asks to separate display from quiet.',
    'В связи может явиться поле личной достаточности; карта просит отделить показ от покоя.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, ortak mirastan ayrı, kişinin kendi emeğinde neyin yeterli olduğunu netleştirir.',
    'The choice clarifies what is enough in one\'s own labor, apart from shared legacy.',
    'Выбор проясняет, чего достаточно в собственном труде, отдельно от общего наследия.',
  ),
  actionDirection: L10nTriple(
    'Nelerin yeterli olduğunu adlandırın; vitrin kurmayın, yeterliği hissedin.',
    'Name what is already enough; do not build a shop window — feel the sufficiency.',
    'Назовите, чего уже достаточно; не стройте витрину — почувствуйте достаточность.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bağımsız yeterlik, emeği gösterişten ayrı tutar.',
      'Independent sufficiency holds labor apart from display.',
      'Самостоятельная достаточность держит труд отдельно от показа.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['enoughness', 'ownLabor', 'sufficiency'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yeterlik gösterişte şişebilir veya paylaşmayı reddeden yalnızlığa içten kapanabilir.',
      'Sufficiency may swell into excess display, or close privately into solitude that refuses to share.',
      'Достаточность может раздуться в показной избыток или замкнуться внутрь в одиночество, отказывающееся делиться.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.privateInternal,
    ],
    keywordIds: ['shopWindow', 'shutSolitude', 'refuseShare'],
  ),
  symbolTags: [
    NarrativeSymbolTags.abundance,
    NarrativeSymbolTags.solitude,
    NarrativeSymbolTags.stability,
  ],
  profileRevision: 1,
);
