/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor12 = NarrativeCardProfile(
  canonicalCardId: 'major_12',
  coreMeaning: L10nTriple(
    'Zorlamayı bırakıp bekleme alanında yeni bir bakış açısının oluşmasına izin vermeyi anlatır.',
    'At the center: releasing force and allowing a new perspective to form within a pause.',
    'Карта говорит об отказе от давления и рождении нового взгляда в пространстве паузы.',
  ),
  light: L10nTriple(
    'Gönüllü duruş, daha önce görünmeyen bir anlamı fark etmek için bakışı değiştirebilir.',
    'A willing pause can shift perception enough to reveal previously unseen meaning.',
    'Добровольная остановка может изменить восприятие и показать прежде незаметный смысл.',
  ),
  shadow: L10nTriple(
    'Teslimiyet, eylemsizliği kutsamaya veya gereksiz fedakârlığı sürdürmeye dönüşebilir.',
    'Surrender can become glorified inaction or the continuation of needless sacrifice.',
    'Принятие может превратиться в оправдание бездействия или продолжение ненужной жертвы.',
  ),
  tension: L10nTriple(
    'Kontrolü bırakmak ile zamanı geldiğinde bilinçli hareket etmek arasında ayrım gerekir.',
    'A distinction is needed between releasing control and acting consciously when the time comes.',
    'Важно различать отпускание контроля и осознанное действие, когда приходит время.',
  ),
  desire: L10nTriple(
    'Kişi, sıkışmış duruma başka bir açıdan bakarak anlamlı bir çıkış bulmak isteyebilir.',
    'Part of this archetype longs to view an impasse differently and find a meaningful way through.',
    'Может хотеться взглянуть на тупик иначе и найти осмысленный путь через него.',
  ),
  fear: L10nTriple(
    'Askıda kalmak, emeğin boşa gitmesi veya iradenin etkisizleşmesi kaygı yaratabilir.',
    'Remaining suspended, wasting effort, or losing agency may cause unease.',
    'Тревогу могут вызывать зависание, напрасные усилия или утрата способности влиять.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda eski tepkiyi durdurur; diğerinin bakışına gerçekten yer açmayı önerir.',
    'It interrupts an old reaction in connection and invites genuine space for another viewpoint.',
    'Карта прерывает привычную реакцию в отношениях и предлагает место для чужого взгляда.',
  ),
  decisionDynamic: L10nTriple(
    'Karar hemen sonuçlanmak yerine varsayımların tersinden incelenmesine ihtiyaç duyabilir.',
    'Rather than immediate closure, the decision may need assumptions examined from the opposite angle.',
    'Вместо немедленного завершения решению может понадобиться взгляд на предположения с другой стороны.',
  ),
  actionDirection: L10nTriple(
    'Müdahaleyi kısa süre durdurun, bedel ile anlamı ayırın ve yeni açıyı not edin.',
    'Pause intervention briefly, separate cost from meaning, and note the new angle.',
    'Ненадолго прекратите вмешательство, отделите цену от смысла и зафиксируйте новый ракурс.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bilinçli bir askı hali, zorlamanın çözemediği şeyi farklı bakışla yumuşatır.',
      'Conscious suspension softens what force could not resolve by changing perspective.',
      'Осознанная пауза смягчает то, что не решалось усилием, благодаря иному взгляду.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['surrender', 'perspective', 'pause'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bekleyiş uzayabilir, fedakârlık anlamsızlaşabilir veya gerekli bırakış dirençle ertelenebilir.',
      'Waiting may drag on, sacrifice lose meaning, or necessary release be resisted.',
      'Ожидание может затянуться, жертва потерять смысл, а нужное отпускание встретить сопротивление.',
    ),
    transforms: [
      ReversedTransformKind.delay,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: ['stagnation', 'resistance', 'sacrifice'],
  ),
  symbolTags: [
    NarrativeSymbolTags.surrender,
    NarrativeSymbolTags.perspective,
    NarrativeSymbolTags.pause,
  ],
  profileRevision: 1,
);
