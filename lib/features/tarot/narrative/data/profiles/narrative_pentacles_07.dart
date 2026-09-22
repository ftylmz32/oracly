/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles07 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_07',
  coreMeaning: L10nTriple(
    'Henüz olgunlaşmamış ekini anlatır; sabır ve gözden geçirme, erken toplamaktan ayrıdır.',
    'It speaks of a crop not yet ripe; patience and reassessment stand apart from premature harvest.',
    'Говорит о ещё не зрелом посеве; терпение и пересмотр отдельны от преждевременного сбора.',
  ),
  light: L10nTriple(
    'Beklemek, emeğin hâlâ hizmet edip etmediğini sessizce yoklamaya alan açabilir.',
    'Waiting can make room to quietly check whether the labor still serves.',
    'Ожидание может дать место тихо проверить, служит ли ещё труд.',
  ),
  shadow: L10nTriple(
    'Sabır, donuk bekleyişe, acele toplamaya veya hiç bakmamaya kayabilir.',
    'Patience may slide into frozen waiting, rushing to gather, or never looking again.',
    'Терпение может стать застывшим ожиданием, спешкой собрать или вовсе не смотреть снова.',
  ),
  tension: L10nTriple(
    'Olgunlaşmayı bekleme isteği ile henüz erken olup olmadığını bilme ihtiyacı çekişir.',
    'The wish to wait for ripeness contends with the need to know if it is still too soon.',
    'Желание ждать зрелости спорит с нуждой знать, не слишком ли ещё рано.',
  ),
  desire: L10nTriple(
    'Kişi, ektiğinin zamanında karşılık bulmasını isteyebilir.',
    'There may be a wish for what was sown to meet its time.',
    'Может хотеться, чтобы посеянное встретило своё время.',
  ),
  fear: L10nTriple(
    'Boşa beklemek veya erken koparmak kaygı yaratabilir.',
    'Waiting in vain, or pulling too early, may cause unease.',
    'Тревогу может вызывать напрасное ожидание или слишком ранний срыв.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda olgunlaşma süresi belirebilir; beklemeyi eylemsizlikten ayırmayı ister.',
    'A ripening span may appear in a bond; it asks to separate waiting from inaction.',
    'В связи может явиться срок созревания; карта просит отделить ожидание от бездействия.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, sabrı yeniden değerlendirmekten ayırır; erken toplamayı da donuk bekleyişten ayırır.',
    'The choice separates patience from reassessing; it also separates premature gathering from frozen waiting.',
    'Выбор отделяет терпение от пересмотра; также отделяет преждевременный сбор от застывшего ожидания.',
  ),
  actionDirection: L10nTriple(
    'Beklemenin hâlâ hizmet edip etmediğini yoklayın; erken toplamayın, kör beklemeyin.',
    'Check whether waiting still serves; do not harvest early, do not wait blindly.',
    'Проверьте, служит ли ещё ожидание; не собирайте рано, не ждите вслепую.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bilinçli sabır, ekini erken toplamaktan ve donuk bekleyişten ayırır.',
      'Conscious patience separates the crop from premature harvest and from frozen waiting.',
      'Сознательное терпение отделяет посев от преждевременного сбора и от застывшего ожидания.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['notYetRipe', 'cultivation', 'patience'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sabır donuk bekleyişe, acele toplamaya veya bakmamaya kayabilir.',
      'Patience may slide into frozen waiting, rushing to gather, or not looking.',
      'Терпение может стать застывшим ожиданием, спешкой собрать или несмотрением.',
    ),
    transforms: [ReversedTransformKind.delay, ReversedTransformKind.avoidance],
    keywordIds: ['frozenWait', 'prematurePull', 'blindDelay'],
  ),
  symbolTags: [
    NarrativeSymbolTags.timing,
    NarrativeSymbolTags.delay,
    NarrativeSymbolTags.endurance,
    NarrativeSymbolTags.pause,
  ],
  profileRevision: 1,
);
