/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor17 = NarrativeCardProfile(
  canonicalCardId: 'major_17',
  coreMeaning: L10nTriple(
    'Zor bir dönemin ardından sakin umut, açıklık ve yön duygusunun yeniden belirmesini temsil eder.',
    'It represents quiet hope, openness, and renewed direction after a difficult period.',
    'Карта означает тихую надежду, открытость и возвращение направления после трудного периода.',
  ),
  light: L10nTriple(
    'Nazik bir güven, kesin sonuç vaat etmeden iyileşme için devam etme gücü verebilir.',
    'Gentle trust can support continued renewal without promising a certain outcome.',
    'Мягкое доверие поддерживает обновление, не обещая заранее определенного результата.',
  ),
  shadow: L10nTriple(
    'Umut, somut ihtiyacı görmeden yalnız iyi ihtimale tutunmaya dönüşebilir.',
    'Hope can become attachment to a positive possibility while practical needs go unseen.',
    'Надежда может стать привязанностью к хорошей возможности при игнорировании практических нужд.',
  ),
  tension: L10nTriple(
    'İnancı korumak ile mevcut kırılganlığı dürüstçe kabul etmek birlikte gerekir.',
    'Maintaining faith and honestly acknowledging present vulnerability are both required.',
    'Необходимо одновременно сохранять веру и честно признавать нынешнюю уязвимость.',
  ),
  desire: L10nTriple(
    'Kişi, yeniden güvenebileceği sade bir işaret ve ferah bir yön arayabilir.',
    'There may be a wish for a simple sign of trust and a spacious direction.',
    'Может хотеться простого знака, которому можно довериться, и свободного направления.',
  ),
  fear: L10nTriple(
    'Umutlanıp yeniden incinmek veya iyileşmenin yeterince hızlı olmaması kaygı yaratabilir.',
    'Hoping and being hurt again, or renewal moving slowly, may cause concern.',
    'Может тревожить страх снова надеяться и быть раненым либо медленное восстановление.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağa açıklık ve onarım ihtimali getirir; güvenin küçük tutarlı davranışlarla büyümesini ister.',
    'It brings openness and the possibility of repair, asking trust to grow through small consistent acts.',
    'Карта приносит открытость и возможность восстановления, предлагая растить доверие малыми последовательными поступками.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, korkudan küçülmeden fakat mevcut kaynakları abartmadan bir yön seçmeyi destekler.',
    'The choice supports direction without shrinking from fear or overstating available resources.',
    'Выбор поддерживает движение без подчинения страху и без преувеличения доступных ресурсов.',
  ),
  actionDirection: L10nTriple(
    'Size iyi gelen kaynağı belirleyin, küçük bir bakım adımı seçin ve süreklilik kurun.',
    'Identify what restores you, choose one small act of care, and make it steady.',
    'Определите, что вас восстанавливает, выберите небольшой шаг заботы и сделайте его постоянным.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sakin umut, açıklığı ve yenilenmeyi gerçekçi bir güvenle besler.',
      'Quiet hope nourishes openness and renewal through realistic trust.',
      'Тихая надежда питает открытость и обновление через реалистичное доверие.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['hope', 'guidance', 'renewal'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Umut içe çekilebilir, güven zayıflayabilir veya ilham somut adıma dönüşmeyebilir.',
      'Hope may turn inward, trust diminish, or inspiration fail to become action.',
      'Надежда может уйти внутрь, доверие ослабнуть, а вдохновение не перейти в действие.',
    ),
    transforms: [
      ReversedTransformKind.internalization,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: ['discouragement', 'doubt', 'disconnection'],
  ),
  symbolTags: [
    NarrativeSymbolTags.hope,
    NarrativeSymbolTags.guidance,
    NarrativeSymbolTags.renewal,
  ],
  profileRevision: 1,
);
