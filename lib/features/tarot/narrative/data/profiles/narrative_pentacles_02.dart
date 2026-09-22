/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles02 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_02',
  coreMeaning: L10nTriple(
    'İki ağırlık arasında ritmi anlatır; hiçbirini seçmemek değil, pratik denge tutmaktır.',
    'It speaks of rhythm between two weights; not choosing none, but holding practical balance.',
    'Говорит о ритме между двумя тяжестями; не об отказе выбирать, а о практическом равновесии.',
  ),
  light: L10nTriple(
    'Kaynakları sırayla taşımak, ikisini de düşürmeden akışı bozmayabilir.',
    'Carrying resources in turn may keep the flow intact without dropping either.',
    'Нести ресурсы по очереди может сохранить течение, не роняя ни то ни другое.',
  ),
  shadow: L10nTriple(
    'Jonglörlük dağılmaya, kararsızlığa veya her şeyi aynı anda tutmaya kayabilir.',
    'Juggling may slide into scatter, indecision, or gripping everything at once.',
    'Жонглирование может стать рассеянием, нерешительностью или хваткой всего сразу.',
  ),
  tension: L10nTriple(
    'İkisini de koruma isteği ile birini bırakma korkusu çekişir.',
    'The wish to keep both contends with the fear of releasing one.',
    'Желание удержать оба спорит со страхом отпустить одно.',
  ),
  desire: L10nTriple(
    'Kişi, iki yükümlülüğü kırılmadan taşımayı isteyebilir.',
    'There may be a wish to carry two obligations without breaking either.',
    'Может хотеться нести два обязательства, не ломая ни одно.',
  ),
  fear: L10nTriple(
    'Birinin düşmesi veya ritmin bozulması kaygı yaratabilir.',
    'One side falling, or the rhythm breaking, may cause unease.',
    'Тревогу может вызывать падение одной стороны или сбой ритма.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda karşılıklı yük paylaşımı gerekebilir; kilitlenmeyi dengeden ayırmayı ister.',
    'Shared load-carrying may be needed in a bond; it asks to separate locking from balance.',
    'В связи может понадобиться делить нагрузку; карта просит отделить запирание от равновесия.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, tek yolu zorlamak yerine iki ağırlığın tempo değişimini tartar.',
    'The choice weighs tempo shifts between two weights rather than forcing one path.',
    'Выбор взвешивает смену темпа между двумя тяжестями, а не навязывает один путь.',
  ),
  actionDirection: L10nTriple(
    'Hangi kaynağın sırada olduğunu görün; ritmi koruyun, ikisini birden sıkmayın.',
    'See which resource is next in turn; keep the rhythm, do not grip both at once.',
    'Увидьте, какой ресурс следующий по очереди; держите ритм, не сжимайте оба сразу.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Canlı bir ritim, iki ağırlığı düşürmeden taşır.',
      'A living rhythm carries two weights without dropping them.',
      'Живой ритм несёт две тяжести, не роняя их.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['twoWeights', 'practicalBalance', 'juggle'],
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
    keywordIds: ['scatter', 'indecision', 'overGrip'],
  ),
  symbolTags: [
    NarrativeSymbolTags.balance,
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.timing,
  ],
  profileRevision: 1,
);
