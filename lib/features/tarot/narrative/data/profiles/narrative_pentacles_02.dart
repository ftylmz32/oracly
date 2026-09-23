/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativePentacles02 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_02',
  coreMeaning: L10nTriple(
    'İki ağırlık arasında ritmi anlatır; hiçbirini seçmemek değil, pratik denge tutmaktır.',
    'Rhythm between two weights names holding practical balance; it refuses choosing none.',
    'Говорит о ритме между двумя тяжестями; не об отказе выбирать, а о практическом равновесии.',
  ),
  light: L10nTriple(
    'Kaynakları sırayla taşımak, ikisini de düşürmeden akışı bozmayabilir.',
    'Carrying resources in turn may keep the flow intact without dropping either.',
    'Нести ресурсы по очереди может сохранить течение, не роняя ни то ни другое.',
  ),
  shadow: L10nTriple(
    'Jonglörlük dağılmaya, kararsızlığa veya her şeyi aynı anda tutmaya kayabilir.',
    'Juggling turns brittle when it becomes scatter, indecision, or gripping everything at once.',
    'Жонглирование может стать рассеянием, нерешительностью или хваткой всего сразу.',
  ),
  tension: L10nTriple(
    'İkisini de koruma isteği ile birini bırakma korkusu çekişir.',
    'The wish to keep both contends with the fear of releasing one.',
    'Желание удержать оба спорит со страхом отпустить одно.',
  ),
  desire: L10nTriple(
    'Kişi, iki yükümlülüğü kırılmadan taşımayı isteyebilir.',
    'Carrying two obligations without breaking either may be the quiet demand.',
    'Может хотеться нести два обязательства, не ломая ни одно.',
  ),
  fear: L10nTriple(
    'Birinin düşmesi veya ritmin bozulması kaygı yaratabilir.',
    'One side falling, or the rhythm breaking, may cause unease.',
    'Тревогу может вызывать падение одной стороны или сбой ритма.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi ortak bir yükü sırayla taşımak zorunda kalabilir; burada sıkıca kavramak, gerçek dengeyi bulmaktan çok farklı görünür.',
    'Two people may need to trade off carrying a shared load, where holding on too tightly reads very differently from finding real balance.',
    'Двоим может понадобиться по очереди нести общую ношу, и крепко цепляться выглядит совсем иначе, чем найти настоящее равновесие.',
  ),
  decisionDynamic: L10nTriple(
    'Bu iki talep arasında tempo değiştirmek, burada her şeyi tek bir yola zorlamaktan daha iyi işler.',
    'Shifting tempo between these two demands works better here than forcing everything onto one path.',
    'Смена темпа между этими двумя требованиями здесь работает лучше, чем принуждать всё к одному пути.',
  ),
  actionDirection: L10nTriple(
    'Sırada hangi kaynağın olduğunu görün ve ritmin onu taşımasına izin verin; iki elinizi birden doldurup sıkmak yerine.',
    'See which resource is next in the turn and let the rhythm carry it, rather than gripping both hands full at once.',
    'Увидьте, какой ресурс следующий по очереди, и позвольте ритму его нести, вместо того чтобы сжимать обе руки разом.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Canlı bir ritim, iki ağırlığı düşürmeden taşır.',
      'A living rhythm carries two weights without dropping them.',
      'Живой ритм несёт две тяжести, не роняя их.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.coordination,
      NarrativeKeywordIds.balance,
      NarrativeKeywordIds.focus,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Denge dağılmaya, kararsızlığa veya aşırı sıkmaya kayabilir.',
      'Balance may slide into scatter, indecision, or over-gripping.',
      'Равновесие может стать рассеянием, нерешительностью или чрезмерной хваткой.',
    ),
    transforms: [
      ReversedTransformKind.distortion,
      ReversedTransformKind.excess,
    ],
    keywordIds: [
      NarrativeKeywordIds.scatter,
      NarrativeKeywordIds.indecision,
      NarrativeKeywordIds.control,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.balance,
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.timing,
  ],
  profileRevision: 1,
);
