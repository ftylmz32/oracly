/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

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
    'İki kişi arasındaki küçük bir ilerleme, kimseyi erken taçlandırmadan fark edilmeyi hak eder.',
    'A small advance between two people is worth noticing without either one being crowned for it too soon.',
    'Небольшое продвижение между двумя людьми стоит заметить, не коронуя за него никого раньше времени.',
  ),
  decisionDynamic: L10nTriple(
    'Görünür büyümeyi sürdüren adımlar, burada erken bir zafer ilan etmekten daha değerlidir.',
    'Steps that sustain visible growth matter more here than declaring an early victory.',
    'Шаги, поддерживающие заметный рост, здесь важнее, чем раннее объявление победы.',
  ),
  actionDirection: L10nTriple(
    'Ufuktaki ilk büyümeyi fark edin ve onu bir taç saymadan önce olgunlaşmasına izin verin.',
    'Notice the first growth on the horizon and let it mature before treating it as a crown.',
    'Заметьте первый рост на горизонте и дайте ему созреть, прежде чем считать его венцом.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sabırlı bakış, ilk görünür büyümeyi hasat sanmadan canlı tutar.',
      'Patient attention keeps first visible growth alive without mistaking it for harvest.',
      'Терпеливое внимание держит первый видимый рост живым, не принимая его за урожай.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.renewal,
      NarrativeKeywordIds.perspective,
      NarrativeKeywordIds.opening,
    ],
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
    keywordIds: [
      NarrativeKeywordIds.impatience,
      NarrativeKeywordIds.scatter,
      NarrativeKeywordIds.boast,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.hope,
    NarrativeSymbolTags.vitality,
    NarrativeSymbolTags.direction,
  ],
  profileRevision: 1,
);
