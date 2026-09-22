/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands08 = NarrativeCardProfile(
  canonicalCardId: 'wands_08',
  coreMeaning: L10nTriple(
    'Havada giden okları anlatır; henüz varış veya tamamlanma değildir.',
    'Not yet arrival or completion; the meaning is arrows in air.',
    'Говорит о стрелах в воздухе; ещё не о прибытии и не о завершении.',
  ),
  light: L10nTriple(
    'Akışa izin vermek, haberi ve hareketi zorlamadan ilerletebilir.',
    'Allowing flow can advance news and motion without forcing them.',
    'Позволение потоку может продвинуть вести и движение без принуждения.',
  ),
  shadow: L10nTriple(
    'Hız, acele, dağılma veya her oku kovalama sabırsızlığına kayabilir.',
    'Speed may harden into haste, scatter, or impatience that chases every arrow.',
    'Скорость может стать спешкой, рассевом или нетерпением, гонящимся за каждой стрелой.',
  ),
  tension: L10nTriple(
    'Tempo artışı ile varış sandığı yanılsama aynı anda hissedilir.',
    'Rising tempo coexists with the illusion of already having arrived.',
    'Рост темпа соседствует с иллюзией, будто прибытие уже случилось.',
  ),
  desire: L10nTriple(
    'Kişi, tıkanmadan akan, net bir hareket ritmi isteyebilir.',
    'A clear rhythm of motion that does not clog may be sought.',
    'Может хотеться ясного ритма движения, который не засоряется.',
  ),
  fear: L10nTriple(
    'Geç kalmak, fırsatı kaçırmak veya akışı kontrol edememek kaygı yaratabilir.',
    'Being late, missing an opening, or failing to steer the flow may cause unease.',
    'Тревогу может вызывать страх опоздать, упустить отверстие или не удержать поток.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda tempo artabilir; her hızın yakınlık olmadığını hatırlatır.',
    'Tempo in a bond may rise; it reminds that not every speed is closeness.',
    'Темп связи может вырасти; карта напоминает: не всякая скорость — близость.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, her sinyale yetişmek yerine hangi okun gerçekten önemli olduğunu ayırır.',
    'The choice separates which arrow truly matters rather than chasing every signal.',
    'Выбор отделяет, какая стрела действительно важна, вместо погони за каждым сигналом.',
  ),
  actionDirection: L10nTriple(
    'Akışa izin verin, önemli olanı seçin; her oku kovalamayın.',
    'Allow the flow, choose what matters; do not chase every arrow.',
    'Позвольте потоку, выберите важное; не гонитесь за каждой стрелой.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ölçülü bir akış, havadaki okları varış sanmadan ilerletir.',
      'Measured flow advances arrows in air without mistaking them for arrival.',
      'Сдержанный поток продвигает стрелы в воздухе, не принимая их за прибытие.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['speed', 'news', 'flow'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Hareket aceleye, dağılmaya veya sabırsız kovalamaya dönüşebilir.',
      'Motion may become haste, scatter, or impatient chase.',
      'Движение может стать спешкой, рассевом или нетерпеливой погоней.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: ['haste', 'scatter', 'impatience'],
  ),
  symbolTags: [
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.timing,
    NarrativeSymbolTags.direction,
  ],
  profileRevision: 1,
);
