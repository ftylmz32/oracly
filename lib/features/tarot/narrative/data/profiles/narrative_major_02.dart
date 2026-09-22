/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor02 = NarrativeCardProfile(
  canonicalCardId: 'major_02',
  coreMeaning: L10nTriple(
    'Sessizlikte fark edilen ince bilgiyi ve henüz açıklanmamış olanla kalabilmeyi simgeler.',
    'It represents subtle knowledge noticed in silence and the ability to stay with what is unrevealed.',
    'Карта означает тонкое знание, замеченное в тишине, и способность оставаться рядом с нераскрытым.',
  ),
  light: L10nTriple(
    'İçsel dinleme, görünür kanıtların kaçırdığı bir ayrıntıyı fark ettirebilir.',
    'Inner listening can reveal a detail that visible evidence has missed.',
    'Внутреннее слушание может открыть деталь, упущенную видимыми доказательствами.',
  ),
  shadow: L10nTriple(
    'Gizem, açıklık kurmaktan kaçınmanın veya bilgiyi saklamanın perdesine dönüşebilir.',
    'Mystery can become a veil for avoiding clarity or withholding information.',
    'Тайна может стать завесой для ухода от ясности или сокрытия информации.',
  ),
  tension: L10nTriple(
    'Bilmek istemek ile cevabın kendi zamanında belirginleşmesini beklemek çatışır.',
    'The wish to know conflicts with letting an answer become clear in its own time.',
    'Желание знать сталкивается с готовностью позволить ответу проясниться в свое время.',
  ),
  desire: L10nTriple(
    'Kişi, dış seslerden uzaklaşıp kendi sessiz kavrayışına güvenmek isteyebilir.',
    'Stepping away from outside voices to trust quiet understanding may feel necessary.',
    'Может появиться желание отойти от внешних голосов и довериться тихому пониманию.',
  ),
  fear: L10nTriple(
    'Yanlış sezmek, önemli bir işareti kaçırmak veya gerçeğe erişememek kaygı yaratabilir.',
    'Misreading a feeling, missing a sign, or not reaching truth may cause unease.',
    'Тревогу может вызывать страх неверно понять чувство, пропустить знак или не узнать правду.',
  ),
  relationshipDynamic: L10nTriple(
    'Söylenmeyenleri hassaslaştırır; varsayım yerine nazik ve açık bir soru önerir.',
    'It heightens what is unspoken and favors a gentle, direct question over assumption.',
    'Карта обостряет невысказанное и предлагает мягкий прямой вопрос вместо догадок.',
  ),
  decisionDynamic: L10nTriple(
    'Karar öncesinde sessiz gözlem, eksik olan bilgiyi aceleyle doldurmaktan değerlidir.',
    'Before deciding, quiet observation matters more than hastily filling gaps in knowledge.',
    'Перед решением тихое наблюдение важнее поспешного заполнения пробелов в знании.',
  ),
  actionDirection: L10nTriple(
    'Alan açın, bedeninizin tepkisini dinleyin ve kesin olmayanı kesinmiş gibi adlandırmayın.',
    'Make space, notice your body\'s response, and do not label uncertainty as fact.',
    'Создайте пространство, прислушайтесь к телу и не называйте неопределенность фактом.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Alıcı bir sessizlik, sezgiyi sakin gözlemle birleştirerek derinlik kazandırır.',
      'Receptive silence deepens intuition by joining it with calm observation.',
      'Восприимчивая тишина углубляет интуицию, соединяя ее со спокойным наблюдением.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['silence', 'intuition', 'mystery'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'İç ses korkuyla karışabilir veya önemli bir kavrayış uzun süre içeride tutulabilir.',
      'The inner voice may mix with fear, or an important insight may remain unexpressed.',
      'Внутренний голос может смешаться со страхом, а важное понимание остаться невысказанным.',
    ),
    transforms: [
      ReversedTransformKind.internalization,
      ReversedTransformKind.distortion,
    ],
    keywordIds: ['secrecy', 'confusion', 'withdrawal'],
  ),
  symbolTags: [
    NarrativeSymbolTags.silence,
    NarrativeSymbolTags.intuition,
    NarrativeSymbolTags.mystery,
  ],
  profileRevision: 1,
);
