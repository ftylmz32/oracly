/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeMajor11 = NarrativeCardProfile(
  canonicalCardId: 'major_11',
  coreMeaning: L10nTriple(
    'Gerçekleri ölçülü biçimde tartmayı, seçimlerin sonuçlarını ve hesap verebilirliği temsil eder.',
    'It represents weighing facts carefully, recognizing consequences, and remaining accountable.',
    'Карта означает внимательное взвешивание фактов, признание последствий и ответственность.',
  ),
  light: L10nTriple(
    'Dürüst değerlendirme, karmaşık bir durumda adil ve tutarlı bir zemin kurabilir.',
    'Honest assessment can establish fair, consistent ground within a complex situation.',
    'Честная оценка может создать справедливую и последовательную основу в сложной ситуации.',
  ),
  shadow: L10nTriple(
    'Doğruluk arayışı, bağlamı görmeyen sert yargıya veya kusursuzluk talebine dönüşebilir.',
    'The pursuit of correctness can become harsh judgment or a demand for perfection.',
    'Стремление к правильности может превратиться в суровый приговор или требование совершенства.',
  ),
  tension: L10nTriple(
    'Nesnel ölçütler ile insani koşulların incelikleri arasında denge kurulması gerekir.',
    'Balance must be found between objective standards and the nuances of human circumstances.',
    'Необходимо найти равновесие между объективными нормами и тонкостями человеческих обстоятельств.',
  ),
  desire: L10nTriple(
    'Kişi, durumun açıkça görülmesini ve emeğin hakkaniyetle karşılık bulmasını isteyebilir.',
    'A need for the situation to be seen clearly and effort treated fairly can become visible.',
    'Может хотеться ясного признания ситуации и справедливой оценки вложенного труда.',
  ),
  fear: L10nTriple(
    'Yanlış anlaşılmak, haksız sonuçla karşılaşmak veya kendi payıyla yüzleşmek korkutabilir.',
    'Being misunderstood, facing an unfair outcome, or confronting one\'s part may feel difficult.',
    'Может пугать непонимание, несправедливый итог или встреча с собственной долей ответственности.',
  ),
  relationshipDynamic: L10nTriple(
    'Karşılıklılık ve sorumluluğu görünür kılar; her iki tarafın deneyimine yer açar.',
    'It makes reciprocity and responsibility visible while allowing room for both experiences.',
    'Карта проявляет взаимность и ответственность, оставляя место опыту обеих сторон.',
  ),
  decisionDynamic: L10nTriple(
    'Kanıtı varsayımdan ayırmak ve sonuçları açıkça üstlenmek, burada haklı görünmekten daha önemlidir.',
    'Separating evidence from assumption, and owning the consequences plainly, matters more here than being seen as right.',
    'Отделить факты от предположений и открыто принять последствия значит здесь больше, чем выглядеть правым.',
  ),
  actionDirection: L10nTriple(
    'Bilinenleri sıralayın, kendi payınızı kabul edin ve aynı ölçütü herkese uygulayın.',
    'List what is known, acknowledge your part, and apply the same standard to everyone.',
    'Перечислите известные факты, признайте свою роль и примените одинаковую меру ко всем.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Açık ölçütler ve dürüst sorumluluk, dengeli bir değerlendirmeyi mümkün kılar.',
      'Clear standards and honest responsibility make a balanced evaluation possible.',
      'Ясные критерии и честная ответственность делают возможной взвешенную оценку.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.balance,
      NarrativeKeywordIds.truth,
      NarrativeKeywordIds.accountability,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yargı çarpılabilir, sorumluluk ertelenebilir veya denge tek taraflı kurulabilir.',
      'Judgment may distort, accountability may be delayed, or balance may become one-sided.',
      'Суждение может исказиться, ответственность — отложиться, а равновесие — стать односторонним.',
    ),
    transforms: [
      ReversedTransformKind.distortion,
      ReversedTransformKind.avoidance,
    ],
    keywordIds: [
      NarrativeKeywordIds.bias,
      NarrativeKeywordIds.denial,
      NarrativeKeywordIds.imbalance,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.balance,
    NarrativeSymbolTags.truth,
    NarrativeSymbolTags.accountability,
  ],
  profileRevision: 1,
);
