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
    'İki kişi arasındaki tempo hızlanabilir; ama hız tek başına yakınlık anlamına gelmez.',
    'The pace between two people can quicken, though speed on its own is not the same as closeness.',
    'Темп между двумя людьми может ускориться, но скорость сама по себе — ещё не близость.',
  ),
  decisionDynamic: L10nTriple(
    'Her sinyalin peşinden koşmak, hangi okun gerçekten önemli olduğunu ayırt etmek kadar işe yaramaz.',
    'Chasing every signal helps less than telling which arrow actually matters.',
    'Гнаться за каждым сигналом менее полезно, чем понять, какая стрела действительно важна.',
  ),
  actionDirection: L10nTriple(
    'Akışın sürmesine izin verin ve havadaki her oku kovalamak yerine önemli olanı seçin.',
    'Let the flow move, and pick out what matters instead of chasing every arrow in the air.',
    'Позвольте потоку течь и выберите важное, вместо того чтобы гнаться за каждой стрелой в воздухе.',
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
