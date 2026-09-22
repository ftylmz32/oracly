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
    'It speaks of a mind that holds truth kindly; not a role that feels less, but a field of humane boundary and discernment.',
    'Говорит об уме, держащем правду мягко; не о роли, что чувствует меньше, а о поле человечной границы и различения.',
  ),
  light: L10nTriple(
    'Dürüst sınır, keserek söylemeden netliği koruyabilir.',
    'An honest boundary can protect clarity without speaking by cutting.',
    'Честная граница может беречь ясность, не говоря раня.',
  ),
  shadow: L10nTriple(
    'Netlik soğuk yargıya, mesafe silahına veya acı dile kayabilir.',
    'Clarity may slide into cold verdict, distance-as-weapon, or bitter tongue.',
    'Ясность может стать холодным приговором, дистанцией-оружием или горьким языком.',
  ),
  tension: L10nTriple(
    'Doğru söyleme arzusu ile keserek konuşmama ihtiyacı birlikte durur.',
    'The wish to speak truly coexists with the need not to speak by cutting.',
    'Желание говорить правду соседствует с нуждой не говорить, раня.',
  ),
  desire: L10nTriple(
    'Kişi, hem keskin hem koruyan bir dil istemek isteyebilir.',
    'There may be a wish for speech that is both sharp and protecting.',
    'Может хотеться речи и острой, и защищающей.',
  ),
  fear: L10nTriple(
    'Soğumak, sınır kaybetmek veya gerçeğin incitmesi kaygı yaratabilir.',
    'Growing cold, losing boundary, or truth wounding may cause unease.',
    'Тревогу может вызывать охлаждение, утрата границы или ранение правдой.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda dürüst bir sınır konuşulabilir; soğukluğu insanî netlikten ayırmayı ister.',
    'An honest boundary may be spoken in a bond; it asks to separate coldness from humane clarity.',
    'В связи может быть сказана честная граница; карта просит отделить холодность от человечной ясности.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, utandırmadan adil ayırt etmeye yaslanır.',
    'The choice leans on fair discernment without shaming.',
    'Выбор опирается на честное различение без стыда.',
  ),
  actionDirection: L10nTriple(
    'Sınırı dürüstçe belirtin; doğru söyleyin, keserek söylemeyin.',
    'State the boundary honestly; speak truly, do not speak by cutting.',
    'Скажите границу честно; говорите правду, не говорите, раня.',
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
      'Netlik soğuk yargıya, mesafe silahına veya acı dile kayabilir.',
      'Clarity may slide into cold verdict, distance-as-weapon, or bitter tongue.',
      'Ясность может стать холодным приговором, дистанцией-оружием или горьким языком.',
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
