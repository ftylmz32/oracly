/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords06 = NarrativeCardProfile(
  canonicalCardId: 'swords_06',
  coreMeaning: L10nTriple(
    'Suyun üstünde giden zihni anlatır; henüz liman değil, sakin bir geçiştir.',
    'It speaks of a mind traveling on water; not yet harbor, but a calm crossing.',
    'Говорит об уме, идущем по воде; ещё не гавань, а спокойный переход.',
  ),
  light: L10nTriple(
    'Ölçülü taşıma, geçişi kaçışa çevirmeden ilerletebilir.',
    'Measured carrying can advance the crossing without turning it into escape.',
    'Сдержанное несение может продвигать переход, не превращая его в бегство.',
  ),
  shadow: L10nTriple(
    'Geçiş kaçışa, bütün geçmişi yüklemeye veya varamama korkusuna kayabilir.',
    'Crossing may slide into escape, loading the whole past, or fear of not arriving.',
    'Переход может стать бегством, грузом всего прошлого или страхом не прибыть.',
  ),
  tension: L10nTriple(
    'İlerleme arzusu ile geçmişin tamamını tekneye almama ihtiyacı birlikte durur.',
    'The wish to move on coexists with the need not to load the whole past into the boat.',
    'Желание двигаться дальше соседствует с нуждой не грузить всё прошлое в лодку.',
  ),
  desire: L10nTriple(
    'Kişi, yorgun bir durulukla daha sakin bir kıyıya geçmek isteyebilir.',
    'There may be a wish to cross toward a calmer shore with tired clarity.',
    'Может хотеться перейти к более спокойному берегу с усталой ясностью.',
  ),
  fear: L10nTriple(
    'Geçidin kaçış olması veya hiç varamamak kaygı yaratabilir.',
    'The passage being only escape, or never arriving, may cause unease.',
    'Тревогу может вызывать то, что проход — лишь бегство, или неприбытие.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda bir geçiş dönemi belirebilir; kaçışı taşırmadan ayırmayı ister.',
    'A crossing period may appear in a bond; it asks to separate escape from carrying forward.',
    'В связи может явиться период перехода; карта просит отделить бегство от несения вперёд.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, her yükü almak yerine neyin gerçekten taşınacağını netleştirir.',
    'The choice clarifies what is truly carried rather than taking every load.',
    'Выбор проясняет, что действительно несут, а не берёт каждую ношу.',
  ),
  actionDirection: L10nTriple(
    'Taşıyın; bütün geçmişi tekneye yüklemeyin.',
    'Carry; do not load the whole past into the boat.',
    'Несите; не грузите всё прошлое в лодку.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sakin bir geçiş, zihni liman sanmadan ilerletir.',
      'A calm crossing moves the mind forward without mistaking it for harbor.',
      'Спокойный переход двигает ум вперёд, не принимая его за гавань.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['crossing', 'calmWater', 'carrying'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Geçiş kaçışa, geçmiş yüküne veya varamama korkusuna kayabilir.',
      'Crossing may slide into escape, past-load, or fear of not arriving.',
      'Переход может стать бегством, грузом прошлого или страхом не прибыть.',
    ),
    transforms: [
      ReversedTransformKind.avoidance,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: ['escape', 'pastCargo', 'arrivalFear'],
  ),
  symbolTags: [
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.change,
    NarrativeSymbolTags.release,
  ],
  profileRevision: 1,
);
