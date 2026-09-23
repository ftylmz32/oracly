/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

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
    'Kişisel bir yeterlik hissi bir bağa girebilir; en inandırıcı hâli, karşı taraf için bir gösteriye dönüşmek yerine sessiz kaldığı zamandır.',
    'A sense of personal sufficiency can enter a bond, most convincingly when it stays quiet rather than turning into a display for the other person.',
    'Чувство личной достаточности может войти в связь — убедительнее всего тогда, когда оно остаётся тихим, а не превращается в показ для другого человека.',
  ),
  decisionDynamic: L10nTriple(
    'Kişinin kendi emeğinde neyin yeterli sayıldığı, ona bağlı ortak mirastan ayrı olarak adlandırılmaya değer.',
    'What counts as enough in one\'s own labor is worth naming separately from any shared legacy attached to it.',
    'То, что считается достаточным в собственном труде, стоит назвать отдельно от связанного с ним общего наследия.',
  ),
  actionDirection: L10nTriple(
    'Zaten yeterli olanı adlandırın ve onu sessizce hissetmenize izin verin; başkaları için bir vitrine dönüştürmeden.',
    'Name what is already enough and let yourself feel it quietly, without turning it into a shop window for others.',
    'Назовите то, чего уже достаточно, и позвольте себе тихо это почувствовать, не превращая это в витрину для других.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bağımsız yeterlik, emeği gösterişten ayrı tutar.',
      'Independent sufficiency holds labor apart from display.',
      'Самостоятельная достаточность держит труд отдельно от показа.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [NarrativeKeywordIds.enough, NarrativeKeywordIds.craft],
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
    keywordIds: [
      NarrativeKeywordIds.display,
      NarrativeKeywordIds.solitude,
      NarrativeKeywordIds.withdrawal,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.abundance,
    NarrativeSymbolTags.solitude,
    NarrativeSymbolTags.stability,
  ],
  profileRevision: 1,
);
