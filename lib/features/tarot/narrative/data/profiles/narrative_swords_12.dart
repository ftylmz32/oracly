/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeSwords12 = NarrativeCardProfile(
  canonicalCardId: 'swords_12',
  coreMeaning: L10nTriple(
    'Düşünceyi yola çıkaran kılıcı anlatır; hızlı zihin ve zorlayıcı iletişim alanıdır.',
    'A sword that takes thought on the road; a field of rapid mind and forceful speech.',
    'Говорит о мече, берущем мысль в дорогу; о поле быстрого ума и настойчивой речи.',
  ),
  light: L10nTriple(
    'Yönlü hız, rastgele kesmeden bir fikri ileri taşıyabilir.',
    'Directed speed can carry an idea forward without cutting at random.',
    'Направленная скорость может нести идею вперёд, не режа наугад.',
  ),
  shadow: L10nTriple(
    'Hız düşüncesiz hamleye, dinlememeye veya başkasını ezmeye kayabilir.',
    'Speed may slide into thoughtless move, not listening, or crushing another.',
    'Скорость может стать бездумным ходом, неслушанием или давлением на другого.',
  ),
  tension: L10nTriple(
    'İleri gitme arzusu ile rastgele kesmeme ihtiyacı çekişir.',
    'The wish to advance contends with the need not to cut at random.',
    'Желание двигаться вперёд спорит с нуждой не резать наугад.',
  ),
  desire: L10nTriple(
    'Kişi, duramayan bir argümanı ya da ani bir söz hamlesini ilerletmek isteyebilir.',
    'Quietly, one may seek to advance an argument that cannot wait, or a sudden verbal move.',
    'Может хотеться продвинуть довод, который не ждёт, или внезапный словесный ход.',
  ),
  fear: L10nTriple(
    'Geç kalmak veya hızın ilişkiyi sarsması kaygı yaratabilir.',
    'Being too late, or speed shaking the bond, may cause unease.',
    'Тревогу может вызывать опоздание или то, что скорость трясёт связь.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasında hızlı sözler uçuşabilir; gerçek dinlemek, bir noktayı zorla kabul ettirmekten farklı bir şeydir.',
    'Quick words can fly between two people, and real listening stays a different thing from forcing a point through.',
    'Между двумя людьми могут пролетать быстрые слова, и настоящее слушание — не то же самое, что продавливание своей точки зрения.',
  ),
  decisionDynamic: L10nTriple(
    'Ani bir hamleden önce yönü netleştirmek, o hamlenin hızından daha fazlasını korur.',
    'Clarifying direction before any sudden move saves more than the speed of that move itself.',
    'Прояснить направление до внезапного хода сохраняет больше, чем скорость самого этого хода.',
  ),
  actionDirection: L10nTriple(
    'Gerekiyorsa hızlı ilerleyin, ama en yakındakini kesmek yerine hükümden önce yer bırakın.',
    'Move at speed if you must, but leave room before judgment instead of cutting at whatever is nearest.',
    'Двигайтесь быстро, если нужно, но оставьте место до суждения, вместо того чтобы резать первое попавшееся.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yönlü bir hız, düşünceyi rastgele kesmeden taşır.',
      'Directed speed carries thought without random cutting.',
      'Направленная скорость несёт мысль без случайного резанья.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.momentum,
      NarrativeKeywordIds.communication,
      NarrativeKeywordIds.clarity,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Hız düşüncesiz hamlede taşabilir veya gücü dinlemek yerine ezmeye yöneltebilir.',
      'Speed may tip into excess thoughtless move, or misdirect force toward crushing instead of listening.',
      'Скорость может перейти в избыточный бездумный ход или сбить силу к давлению вместо слушания.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: [
      NarrativeKeywordIds.haste,
      NarrativeKeywordIds.harshSpeech,
      NarrativeKeywordIds.notListening,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.focus,
    NarrativeSymbolTags.will,
  ],
  profileRevision: 1,
);
