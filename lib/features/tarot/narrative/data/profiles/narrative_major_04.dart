/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor04 = NarrativeCardProfile(
  canonicalCardId: 'major_04',
  coreMeaning: L10nTriple(
    'Sınırlar, düzen ve sorumluluk aracılığıyla güvenilir bir temel kurmayı temsil eder.',
    'It represents building a dependable foundation through boundaries, order, and responsibility.',
    'Карта означает создание надежной основы через границы, порядок и ответственность.',
  ),
  light: L10nTriple(
    'Açık çerçeveler, enerjiyi korur ve sürdürülebilir ilerlemeyi mümkün kılar.',
    'Clear frameworks protect energy and make sustainable progress possible.',
    'Ясные рамки берегут силы и делают устойчивое продвижение возможным.',
  ),
  shadow: L10nTriple(
    'Düzen ihtiyacı, esnekliği ve başkalarının sesini bastıran katılığa dönüşebilir.',
    'The need for order can harden into rigidity that suppresses flexibility and other voices.',
    'Потребность в порядке может стать жесткостью, подавляющей гибкость и чужие голоса.',
  ),
  tension: L10nTriple(
    'Kontrolü sürdürme arzusu ile değişen koşullara uyum sağlama gereği çekişir.',
    'The wish to maintain control contends with the need to adapt to changing conditions.',
    'Желание сохранять контроль спорит с необходимостью приспосабливаться к переменам.',
  ),
  desire: L10nTriple(
    'Kişi, neye dayanacağını bildiği sağlam ve öngörülebilir bir düzen isteyebilir.',
    'A solid, predictable order one can rely upon may be longed for.',
    'Может возникнуть желание обрести прочный и понятный порядок, на который можно опереться.',
  ),
  fear: L10nTriple(
    'Dağılmak, etkisini kaybetmek veya sorumluluğun ağırlığı altında kalmak korkutabilir.',
    'Disorder, loss of influence, or being overwhelmed by responsibility may feel threatening.',
    'Могут пугать хаос, утрата влияния или тяжесть ответственности.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağa güven ve netlik sunar; kuralların karşılıklı konuşularak oluşmasını ister.',
    'It offers security and clarity to a bond while asking that rules be mutually discussed.',
    'Карта дает связи надежность и ясность, предлагая обсуждать правила вместе.',
  ),
  decisionDynamic: L10nTriple(
    'Yetki sınırlarını, sorumlulukları ve uzun vadeli sonuçları netleştirmek, bu kararı gerçekten güçlendiren şeydir.',
    'Clarifying authority, responsibilities, and long-term consequences is what actually strengthens this decision.',
    'Ясное понимание полномочий, обязанностей и долгосрочных последствий — вот что на самом деле укрепляет это решение.',
  ),
  actionDirection: L10nTriple(
    'Temel kuralları yazın, gerçekçi sınırlar koyun ve gerektiğinde çerçeveyi gözden geçirin.',
    'Write down the essential rules, set realistic limits, and review the framework when needed.',
    'Зафиксируйте основные правила, установите реалистичные границы и при необходимости пересматривайте рамки.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Olgun otorite, güvenliği baskıyla değil tutarlılık ve hesap verebilirlikle kurar.',
      'Mature authority creates safety through consistency and accountability rather than force.',
      'Зрелая власть создает безопасность последовательностью и ответственностью, а не давлением.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['structure', 'authority', 'stability'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yapı, aşırı kontrol olarak katılaşabilir ya da gerekli sınırlar kurulamayabilir.',
      'Structure may harden into overcontrol, or necessary boundaries may fail to form.',
      'Структура может застыть в чрезмерном контроле либо нужные границы не будут созданы.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.deficiency,
    ],
    keywordIds: ['rigidity', 'control', 'instability'],
  ),
  symbolTags: [
    NarrativeSymbolTags.structure,
    NarrativeSymbolTags.authority,
    NarrativeSymbolTags.stability,
  ],
  profileRevision: 1,
);
