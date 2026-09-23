/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeMajor14 = NarrativeCardProfile(
  canonicalCardId: 'major_14',
  coreMeaning: L10nTriple(
    'Farklı unsurları acele etmeden karıştırıp sürdürülebilir bir orta yol oluşturmayı anlatır.',
    'Patiently blending different elements into a sustainable middle way.',
    'Карта говорит о терпеливом соединении разных элементов в устойчивый срединный путь.',
  ),
  light: L10nTriple(
    'Ölçülü uyarlama, karşıt görünen ihtiyaçların birlikte işlemesini mümkün kılabilir.',
    'Measured adjustment can allow seemingly opposite needs to work together.',
    'Соразмерная настройка позволяет, казалось бы, противоположным потребностям действовать вместе.',
  ),
  shadow: L10nTriple(
    'Denge arayışı, gerekli ayrımları silen belirsiz bir uzlaşmaya dönüşebilir.',
    'The search for balance can become vague compromise that erases necessary distinctions.',
    'Поиск равновесия может стать расплывчатым компромиссом, стирающим важные различия.',
  ),
  tension: L10nTriple(
    'Değişimi hızlandırma isteği ile doğal karışım süresine saygı arasında sabır gerekir.',
    'Patience is needed between accelerating change and respecting the natural pace of integration.',
    'Между ускорением перемен и уважением к естественному темпу соединения требуется терпение.',
  ),
  desire: L10nTriple(
    'Kişi, aşırılıklardan yorulmadan dengeli ve akışkan bir düzen kurmak isteyebilir.',
    'A need for a balanced, fluid rhythm free from exhausting extremes can become visible.',
    'Может хотеться ровного и гибкого ритма без изматывающих крайностей.',
  ),
  fear: L10nTriple(
    'Uyumun bozulması, aşırıya kaçmak veya parçaların birleşmemesi kaygı yaratabilir.',
    'Disrupted harmony, excess, or elements failing to combine may cause concern.',
    'Тревогу могут вызывать нарушение гармонии, крайности или неспособность частей соединиться.',
  ),
  relationshipDynamic: L10nTriple(
    'Farklı hızları uyumlar; iki tarafın da özünü kaybetmeden ortak ritim kurmasını destekler.',
    'It harmonizes different tempos and supports a shared rhythm without either side losing itself.',
    'Карта согласует разные темпы и помогает создать общий ритм без потери себя.',
  ),
  decisionDynamic: L10nTriple(
    'Birkaç küçük ayarın birleşen etkisi, burada tek bir dramatik hamleden daha değerlidir.',
    'The combined effect of several small adjustments is worth more here than one dramatic move.',
    'Совокупный эффект нескольких малых изменений значит здесь больше, чем один резкий шаг.',
  ),
  actionDirection: L10nTriple(
    'Oranı küçültün, bir değişkeni ayarlayın ve etkisini gözleyerek yeniden dengeleyin.',
    'Reduce the scale, adjust one variable, and rebalance after observing its effect.',
    'Уменьшите масштаб, настройте один фактор и восстановите равновесие после наблюдения.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sabırlı bütünleşme, farklı güçlerden sakin ve işlevsel bir bileşim oluşturur.',
      'Patient integration creates a calm, workable blend from different forces.',
      'Терпеливое объединение создает спокойное и действенное сочетание разных сил.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.balance,
      NarrativeKeywordIds.integration,
      NarrativeKeywordIds.restraint,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Karışım dengesizleşebilir, süreç aceleye gelebilir veya aşırılıklar yeniden belirginleşebilir.',
      'The blend may become uneven, the process rushed, or extremes become prominent again.',
      'Сочетание может стать неравномерным, процесс — поспешным, а крайности — снова усилиться.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.distortion,
    ],
    keywordIds: [
      NarrativeKeywordIds.imbalance,
      NarrativeKeywordIds.haste,
      NarrativeKeywordIds.scatter,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.balance,
    NarrativeSymbolTags.integration,
    NarrativeSymbolTags.alchemy,
  ],
  profileRevision: 1,
);
