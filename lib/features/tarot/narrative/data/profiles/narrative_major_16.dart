/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor16 = NarrativeCardProfile(
  canonicalCardId: 'major_16',
  coreMeaning: L10nTriple(
    'Dayanıksız bir yapının sarsılmasıyla saklı gerçeğin ve gerekli değişimin açığa çıkmasını anlatır.',
    'An unstable structure shaking enough to expose truth and necessary change.',
    'Карта говорит о потрясении непрочной структуры, открывающем скрытую правду и необходимую перемену.',
  ),
  light: L10nTriple(
    'Ani açıklık, uzun süredir korunamayan bir düzeni dürüstçe yeniden kurma fırsatı verebilir.',
    'Sudden clarity can offer a chance to rebuild honestly what could no longer be sustained.',
    'Внезапная ясность дает возможность честно перестроить то, что больше нельзя было поддерживать.',
  ),
  shadow: L10nTriple(
    'Sarsıntı, güven duygusunu dağıtabilir ve her şeyi aynı anda çözme baskısı yaratabilir.',
    'Upheaval can scatter security and create pressure to solve everything at once.',
    'Потрясение может разрушить чувство опоры и создать давление решить все немедленно.',
  ),
  tension: L10nTriple(
    'Kaybın şoku ile açığa çıkan gerçeğin özgürleştirici yanı birlikte hissedilir.',
    'The shock of loss coexists with the freeing quality of what has been revealed.',
    'Шок утраты соседствует с освобождающим качеством открывшейся правды.',
  ),
  desire: L10nTriple(
    'Kişi, yanılsamadan uzak, gerçek koşullara dayanabilen sağlam bir temel isteyebilir.',
    'Solid ground able to withstand reality without illusion may be wanted.',
    'Может возникнуть желание обрести прочную основу, выдерживающую реальность без иллюзий.',
  ),
  fear: L10nTriple(
    'Kontrolün ansızın kaybolması veya tanıdık yapının geri gelmemesi ürkütebilir.',
    'Sudden loss of control or the familiar structure never returning may feel frightening.',
    'Может пугать внезапная потеря контроля или невозможность вернуть знакомую структуру.',
  ),
  relationshipDynamic: L10nTriple(
    'Gizlenen çatlağı görünür kılar; savunmadan önce güvenliği ve dürüstlüğü yeniden kurmayı ister.',
    'It exposes a hidden fracture and asks for safety and honesty before defense.',
    'Карта выявляет скрытую трещину и предлагает восстановить безопасность и честность до защиты позиций.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, çöken varsayımı kurtarmak yerine geride kalan sağlam unsurları belirlemelidir.',
    'The decision should identify what remains sound rather than rescue a collapsed assumption.',
    'Решение должно определить, что осталось надежным, вместо спасения разрушенного предположения.',
  ),
  actionDirection: L10nTriple(
    'Önce güvenliği sağlayın, hasarı adlandırın ve yalnız taşıyabilecek temeli yeniden kurun.',
    'Secure immediate safety, name the damage, and rebuild only on what can hold.',
    'Сначала обеспечьте безопасность, назовите ущерб и стройте заново лишь на прочном основании.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sarsıcı açıklık, sahte güveni dağıtarak daha dürüst bir yeniden yapılanma başlatır.',
      'Disruptive clarity dissolves false security and begins a more honest reconstruction.',
      'Потрясающая ясность разрушает ложную опору и начинает более честное восстановление.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['upheaval', 'truth', 'breakthrough'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Çatlak içeride büyüyebilir, sarsıntı ertelenebilir veya değişimden kaçınılabilir.',
      'The fracture may grow privately, upheaval be delayed, or necessary change avoided.',
      'Трещина может расти внутри, потрясение — откладываться, а необходимая перемена — избегаться.',
    ),
    transforms: [
      ReversedTransformKind.internalization,
      ReversedTransformKind.avoidance,
    ],
    keywordIds: ['resistance', 'instability', 'avoidance'],
  ),
  symbolTags: [
    NarrativeSymbolTags.upheaval,
    NarrativeSymbolTags.truth,
    NarrativeSymbolTags.breakthrough,
  ],
  profileRevision: 1,
);
