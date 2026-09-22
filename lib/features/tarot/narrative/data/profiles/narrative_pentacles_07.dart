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
    'A crop not yet ripe; patience and reassessment stand apart from premature harvest.',
    'Говорит о ещё не зрелом посеве; терпение и пересмотр отдельны от преждевременного сбора.',
  ),
  light: L10nTriple(
    'Beklemek, emeğin hâlâ hizmet edip etmediğini sessizce yoklamaya alan açabilir.',
    'Waiting can make room to quietly check whether the labor still serves.',
    'Ожидание может дать место тихо проверить, служит ли ещё труд.',
  ),
  shadow: L10nTriple(
    'Sabır, donuk bekleyişe, acele toplamaya veya hiç bakmamaya kayabilir.',
    'Patience can harden into frozen waiting, a rush to gather too soon, or refusing to look again.',
    'Терпение может стать застывшим ожиданием, спешкой собрать или вовсе не смотреть снова.',
  ),
  tension: L10nTriple(
    'Olgunlaşmayı bekleme isteği ile henüz erken olup olmadığını bilme ihtiyacı çekişir.',
    'The wish to wait for ripeness contends with the need to know if it is still too soon.',
    'Желание ждать зрелости спорит с нуждой знать, не слишком ли ещё рано.',
  ),
  desire: L10nTriple(
    'Kişi, ektiğinin zamanında karşılık bulmasını isteyebilir.',
    'What was sown may need to meet its own time before harvest.',
    'Может хотеться, чтобы посеянное встретило своё время.',
  ),
  fear: L10nTriple(
    'Boşa beklemek veya erken koparmak kaygı yaratabilir.',
    'Waiting in vain, or pulling too early, may cause unease.',
    'Тревогу может вызывать напрасное ожидание или слишком ранний срыв.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasında bir olgunlaşma süresi uzayabilir; bilerek beklemek, hiçbir şey yapmamaktan çok farklı görünür.',
    'A span of ripening can stretch out between two people, and actively waiting reads very differently from simply doing nothing.',
    'Между двумя людьми может растянуться срок созревания, и осознанное ожидание выглядит совсем иначе, чем простое бездействие.',
  ),
  decisionDynamic: L10nTriple(
    'Burada sabır ve yeniden değerlendirme birbirine karşıt değildir; ne erken toplamak ne de donup beklemek ekine gerçekten hizmet eder.',
    'Patience and reassessment are not opposites here, and neither premature gathering nor frozen waiting actually serves the crop.',
    'Терпение и пересмотр здесь не противоречат друг другу, и ни преждевременный сбор, ни застывшее ожидание на самом деле не служат посеву.',
  ),
  actionDirection: L10nTriple(
    'Beklemenin hâlâ size hizmet edip etmediğini düzenli olarak kontrol edin; erken bir hasat ile gözü kapalı beklemek arasında bir yerde durarak.',
    'Check regularly whether the waiting still serves you, staying somewhere between an early harvest and waiting with your eyes closed.',
    'Регулярно проверяйте, служит ли вам ещё ожидание, оставаясь где-то между ранним сбором и ожиданием с закрытыми глазами.',
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
      'Sabır yeniden bakmadan donuk bekleyişe uzayabilir veya tarlaya bakmayı — bazen erken kopararak — kaçınmaya çevirebilir.',
      'Patience may delay into frozen waiting that never reassesses, or avoid the crop by not looking — and sometimes by pulling early to escape the wait.',
      'Терпение может растянуться в отсрочку без пересмотра или избегать поля, не глядя — а иногда срывая рано, чтобы уйти от ожидания.',
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
