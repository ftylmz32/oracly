/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeWands01 = NarrativeCardProfile(
  canonicalCardId: 'wands_01',
  coreMeaning: L10nTriple(
    'Henüz biçim almamış bir iradenin ilk kıvılcımını ve taze bir başlangıç ısısını anlatır.',
    'A first spark of will not yet shaped, and the heat of a fresh beginning.',
    'Говорит о первой искре ещё несформированной воли и тепле свежего начала.',
  ),
  light: L10nTriple(
    'Küçük tutulan niyet, zorlamadan canlı bir hareket alanı açabilir.',
    'Intent kept small can open lively motion without forcing a blaze.',
    'Малое намерение может открыть живое движение, не раздувая пожар.',
  ),
  shadow: L10nTriple(
    'Kıvılcım, plansız yangına veya savrulmuş bir coşkuya kayabilir.',
    'First fire can scatter into fire without a plan or scattered excitement.',
    'Искра может стать пожаром без плана или рассеянным восторгом.',
  ),
  tension: L10nTriple(
    'Hemen eyleme geçme isteği ile kıvılcımı koruma ihtiyacı birlikte durur.',
    'The urge to act at once sits beside the need to protect the spark.',
    'Желание сразу действовать соседствует с нуждой сберечь искру.',
  ),
  desire: L10nTriple(
    'Kişi, içeride uyanan ısıyı gerçek bir başlangıca çevirmek isteyebilir.',
    'A longing to turn inner heat into a real beginning may surface.',
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
    'Küçük ve sürdürülebilir bir niyet, burada büyük bir vaatten daha ağır basar.',
    'A small, sustainable intent carries more weight here than a grand promise.',
    'Небольшое, но стойкое намерение значит здесь больше, чем громкое обещание.',
  ),
  actionDirection: L10nTriple(
    'Kıvılcımı boğmadan ya da fazlasını yüklemeden, küçük kalıp kendini kanıtlamasına izin verin.',
    'Let the spark stay small and prove itself before you smother it or load it with more than it can hold.',
    'Дайте искре остаться малой и проявить себя, не гася её и не перегружая большим, чем она способна выдержать.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ölçülü bir irade, henüz biçimsiz kıvılcımı canlı ve yönetilebilir tutar.',
      'Measured will keeps an unshaped spark alive and workable.',
      'Сдержанная воля удерживает несформированную искру живой и управляемой.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.spark,
      NarrativeKeywordIds.agency,
      NarrativeKeywordIds.momentum,
    ],
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
    keywordIds: [
      NarrativeKeywordIds.withdrawal,
      NarrativeKeywordIds.scatter,
      NarrativeKeywordIds.delay,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.creation,
    NarrativeSymbolTags.vitality,
    NarrativeSymbolTags.will,
  ],
  profileRevision: 1,
);
