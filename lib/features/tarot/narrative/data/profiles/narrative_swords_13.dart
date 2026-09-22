/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords13 = NarrativeCardProfile(
  canonicalCardId: 'swords_13',
  coreMeaning: L10nTriple(
    'Gerçeği nazik tutan zihni anlatır; daha az hisseden bir rol değil, insanî sınır ve ayırt etme alanıdır.',
    'A mind that holds truth kindly; not a role that feels less, but a field of humane boundary and discernment.',
    'Говорит об уме, держащем правду мягко; не о роли, что чувствует меньше, а о поле человечной границы и различения.',
  ),
  light: L10nTriple(
    'Dürüst sınır, keserek söylemeden netliği koruyabilir.',
    'An honest boundary can protect clarity without speaking by cutting.',
    'Честная граница может беречь ясность, не говоря раня.',
  ),
  shadow: L10nTriple(
    'Netlik soğuk yargıya, mesafe silahına veya acı dile kayabilir.',
    'Cold verdict, distance-as-weapon, or bitter tongue appears when Clarity dominates.',
    'Ясность может стать холодным приговором, дистанцией-оружием или горьким языком.',
  ),
  tension: L10nTriple(
    'Doğru söyleme arzusu ile keserek konuşmama ihtiyacı birlikte durur.',
    'The wish to speak truly coexists with the need not to speak by cutting.',
    'Желание говорить правду соседствует с нуждой не говорить, раня.',
  ),
  desire: L10nTriple(
    'Kişi, hem keskin hem koruyan bir dil istemek isteyebilir.',
    'Speech that is both sharp and protecting may be longed for.',
    'Может хотеться речи и острой, и защищающей.',
  ),
  fear: L10nTriple(
    'Soğumak, sınır kaybetmek veya gerçeğin incitmesi kaygı yaratabilir.',
    'Growing cold, losing boundary, or truth wounding may cause unease.',
    'Тревогу может вызывать охлаждение, утрата границы или ранение правдой.',
  ),
  relationshipDynamic: L10nTriple(
    'Bir bağ içinde dürüst bir sınır dile getirilebilir; net kalmak, soğumayı gerektirmez.',
    'An honest boundary can be spoken inside a bond, and staying clear does not require turning cold.',
    'Внутри связи можно озвучить честную границу, и оставаться ясным не значит становиться холодным.',
  ),
  decisionDynamic: L10nTriple(
    'Kimseyi utandırmadan sunulan adil bir ayırt etme, burada sert bir hükümden daha ağır basar.',
    'Fair discernment, offered without shaming anyone, carries more weight here than a harsh verdict.',
    'Честное различение, предложенное без стыда, значит здесь больше, чем суровый приговор.',
  ),
  actionDirection: L10nTriple(
    'Sınırı dürüstçe belirtin ve ağırlığı gerçeğin taşımasına izin verin, söyleniş biçimindeki bir keskinliğin değil.',
    'State the boundary honestly and let truth carry the weight, rather than an edge in how it is said.',
    'Честно обозначьте границу и пусть вес несёт правда, а не резкость в том, как она сказана.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'İnsanî bir netlik, gerçeği soğutmadan tutar.',
      'Humane clarity holds truth without cooling it into coldness.',
      'Человечная ясность держит правду, не охлаждая её до холода.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['honestBoundary', 'sharpKindness', 'clearWord'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Netlik, sınırı insanî tutan sıcaklığı yitirebilir, ya da temiz bir çizgi keskin bir savunmaya burkulabilir.',
      'Clarity may lose the warmth that keeps a boundary humane, or a clean line may be twisted into a cutting defense.',
      'Ясность может утратить тепло, которое делает границу человечной, или чистая линия может быть искривлена в режущую защиту.',
    ),
    transforms: [
      ReversedTransformKind.deficiency,
      ReversedTransformKind.distortion,
    ],
    keywordIds: ['coldVerdict', 'distanceWeapon', 'bitterTongue'],
  ),
  symbolTags: [
    NarrativeSymbolTags.clarity,
    NarrativeSymbolTags.judgment,
    NarrativeSymbolTags.restraint,
  ],
  profileRevision: 1,
);
