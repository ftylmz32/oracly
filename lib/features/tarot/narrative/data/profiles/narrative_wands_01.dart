/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands01 = NarrativeCardProfile(
  canonicalCardId: 'wands_01',
  coreMeaning: L10nTriple(
    'Henüz biçim almamış bir iradenin ilk kıvılcımını ve taze bir başlangıç ısısını anlatır.',
    'It speaks of a first spark of will not yet shaped, and the heat of a fresh beginning.',
    'Говорит о первой искре ещё несформированной воли и тепле свежего начала.',
  ),
  light: L10nTriple(
    'Küçük tutulan niyet, zorlamadan canlı bir hareket alanı açabilir.',
    'Intent kept small can open lively motion without forcing a blaze.',
    'Малое намерение может открыть живое движение, не раздувая пожар.',
  ),
  shadow: L10nTriple(
    'Kıvılcım, plansız yangına veya savrulmuş bir coşkuya kayabilir.',
    'The spark may slide into planless fire or scattered excitement.',
    'Искра может стать пожаром без плана или рассеянным восторгом.',
  ),
  tension: L10nTriple(
    'Hemen eyleme geçme isteği ile kıvılcımı koruma ihtiyacı birlikte durur.',
    'The urge to act at once sits beside the need to protect the spark.',
    'Желание сразу действовать соседствует с нуждой сберечь искру.',
  ),
  desire: L10nTriple(
    'Kişi, içeride uyanan ısıyı gerçek bir başlangıca çevirmek isteyebilir.',
    'There may be a wish to turn inner heat into a real beginning.',
    'Может хотеться превратить внутренний жар в настоящее начало.',
  ),
  fear: L10nTriple(
    'Kıvılcığın sönmesi veya fazla alevle boğulması kaygı yaratabilir.',
    'There may be concern that the spark will dull or smother in excess flame.',
    'Может тревожить, что искра угаснет или захлебнётся избыточным пламенем.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağa taze cesaret getirir; alevi dayatmadan karşılıklı ısıyı yoklamayı ister.',
    'It brings fresh courage to a bond while asking warmth to be tested, not imposed.',
    'Приносит в связь свежую смелость и предлагает проверять тепло, а не навязывать его.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, büyük vaat yerine küçük ve sürdürülebilir bir niyetle güçlenir.',
    'The choice strengthens through a small, sustainable intent rather than a grand promise.',
    'Выбор крепнет малым устойчивым намерением, а не громким обещанием.',
  ),
  actionDirection: L10nTriple(
    'Kıvılcığı fark edin, küçük tutun; söndürmeyin ve savurmayın.',
    'Notice the spark, keep it small; do not snuff it, and do not fling it.',
    'Заметьте искру, держите её малой; не гасите и не разбрасывайте.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ölçülü bir irade, henüz biçimsiz kıvılcımı canlı ve yönetilebilir tutar.',
      'Measured will keeps an unshaped spark alive and workable.',
      'Сдержанная воля удерживает несформированную искру живой и управляемой.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['spark', 'intent', 'motion'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Başlangıç ısısı sönükleşebilir, dağılabilir ya da sürekli ertelenmeye kayabilir.',
      'Beginning heat may dull, scatter, or slide into endless deferral.',
      'Тепло начала может угаснуть, рассеяться или уйти в бесконечное откладывание.',
    ),
    transforms: [
      ReversedTransformKind.delay,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: ['dulling', 'scatter', 'defer'],
  ),
  symbolTags: [
    NarrativeSymbolTags.creation,
    NarrativeSymbolTags.vitality,
    NarrativeSymbolTags.will,
  ],
  profileRevision: 1,
);
