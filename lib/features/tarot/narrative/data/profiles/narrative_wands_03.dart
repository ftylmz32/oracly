/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands03 = NarrativeCardProfile(
  canonicalCardId: 'wands_03',
  coreMeaning: L10nTriple(
    'İlk görünür büyümeyi gösterir; henüz hasat ya da taç değildir.',
    'It shows first visible growth; not yet a harvest or a crown.',
    'Показывает первый видимый рост; ещё не урожай и не корона.',
  ),
  light: L10nTriple(
    'Emeğin sessiz işareti, ufku genişleten umutlu bir ısı yaratabilir.',
    'A quiet sign of effort can create hopeful heat that widens the horizon.',
    'Тихий знак усилия может создать обнадёживающий жар, расширяющий горизонт.',
  ),
  shadow: L10nTriple(
    'Büyüme, acele zafer hikâyesine, övünce veya dağınık hevese kayabilir.',
    'Early success can tip into a hasty victory story, boast, or scattered zeal.',
    'Рост может стать историей поспешной победы, похвальбой или рассеянным пылом.',
  ),
  tension: L10nTriple(
    'İlk meyveyi kutlama isteği ile sabırlı genişlemeyi sürdürme gereği çekişir.',
    'The wish to celebrate first fruit contends with the need to keep widening patiently.',
    'Желание отметить первый плод спорит с нуждой терпеливо продолжать расширение.',
  ),
  desire: L10nTriple(
    'Kişi, çabasının işlediğini görünür bir ilerleme olarak hissetmek isteyebilir.',
    'Quietly, one may seek to feel that effort is working as visible progress.',
    'Может хотеться почувствовать, что усилие работает как видимое продвижение.',
  ),
  fear: L10nTriple(
    'İlerleme durabilir, dağılabilir ya da başkalarının gözünde abartılmış görünebilir.',
    'Progress may stall, scatter, or look inflated in other people\'s eyes.',
    'Продвижение может остановиться, рассеяться или выглядеть раздутым в чужих глазах.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda küçük bir ilerleme hissedilebilir; taç giydirmeden ufku birlikte tutmayı önerir.',
    'A small advance may be felt in a bond; it favors holding the horizon together without crowning anyone.',
    'В связи может ощущаться малое продвижение; карта предлагает держать горизонт вместе, никого не коронуя.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, erken zafer ilan etmek yerine görünür büyümeyi sürdüren adımlara bakar.',
    'The choice looks to steps that sustain visible growth rather than declaring early victory.',
    'Выбор смотрит на шаги, поддерживающие видимый рост, а не на раннее объявление победы.',
  ),
  actionDirection: L10nTriple(
    'Ufka bakın, ilk büyümeyi fark edin; henüz kendinizi taçlandırmayın.',
    'Look to the horizon, notice first growth; do not crown yourself yet.',
    'Смотрите на горизонт, заметьте первый рост; ещё не коронуйте себя.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sabırlı bakış, ilk görünür büyümeyi hasat sanmadan canlı tutar.',
      'Patient attention keeps first visible growth alive without mistaking it for harvest.',
      'Терпеливое внимание держит первый видимый рост живым, не принимая его за урожай.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['growth', 'horizon', 'firstFruit'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'İlerleme sabırsızlığa, dağılmaya veya erken övünce dönüşebilir.',
      'Progress may turn into impatience, scatter, or early boast.',
      'Продвижение может стать нетерпением, рассевом или ранней похвальбой.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: ['impatience', 'scatter', 'boast'],
  ),
  symbolTags: [
    NarrativeSymbolTags.hope,
    NarrativeSymbolTags.vitality,
    NarrativeSymbolTags.direction,
  ],
  profileRevision: 1,
);
