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
    'A mind traveling on water; not yet harbor, but a calm crossing.',
    'Говорит об уме, идущем по воде; ещё не гавань, а спокойный переход.',
  ),
  light: L10nTriple(
    'Ölçülü taşıma, geçişi kaçışa çevirmeden ilerletebilir.',
    'Measured carrying can advance the crossing without turning it into escape.',
    'Сдержанное несение может продвигать переход, не превращая его в бегство.',
  ),
  shadow: L10nTriple(
    'Geçiş kaçışa, bütün geçmişi yüklemeye veya varamama korkusuna kayabilir.',
    'Crossing turns brittle when it becomes escape, loading the whole past, or fear of not arriving.',
    'Переход может стать бегством, грузом всего прошлого или страхом не прибыть.',
  ),
  tension: L10nTriple(
    'İlerleme arzusu ile geçmişin tamamını tekneye almama ihtiyacı birlikte durur.',
    'The wish to move on coexists with the need not to load the whole past into the boat.',
    'Желание двигаться дальше соседствует с нуждой не грузить всё прошлое в лодку.',
  ),
  desire: L10nTriple(
    'Kişi, yorgun bir durulukla daha sakin bir kıyıya geçmek isteyebilir.',
    'Quietly, one may seek to cross toward a calmer shore with tired clarity.',
    'Может хотеться перейти к более спокойному берегу с усталой ясностью.',
  ),
  fear: L10nTriple(
    'Geçidin kaçış olması veya hiç varamamak kaygı yaratabilir.',
    'The passage being only escape, or never arriving, may cause unease.',
    'Тревогу может вызывать то, что проход — лишь бегство, или неприбытие.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi bir geçiş dönemini birlikte yaşayabilir; burada sadece kaçmak, bir şeyleri gerçekten ileri taşımaktan farklı görünür.',
    'Two people can move through a crossing period together, where simply escaping looks different from actually carrying things forward.',
    'Двое могут вместе пройти через период перехода, где простое бегство выглядит иначе, чем действительное движение вперёд.',
  ),
  decisionDynamic: L10nTriple(
    'Gerçekten taşınmaya değer olanı ayıklamak, elde olan her yükü almaktan daha önemlidir.',
    'Sorting out what is actually worth carrying forward matters more than taking on every available load.',
    'Разобраться, что действительно стоит нести вперёд, важнее, чем брать на себя любую доступную ношу.',
  ),
  actionDirection: L10nTriple(
    'Hâlâ işinize yarayanı taşıyın ve geçmişin geri kalanını tekneye yüklemek yerine kıyıda bırakın.',
    'Carry what still serves you and leave the rest of the past on the shore rather than loading it into the boat.',
    'Несите то, что всё ещё вам служит, а остальное прошлое оставьте на берегу, а не грузите в лодку.',
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
      'Geçiş varışı kaçış olarak kaçınabilir veya bütün geçmişi yükleyerek tekneyi varamama korkusuyla saptırabilir.',
      'Crossing may avoid arrival as escape, or misdirect the boat by loading the whole past until fear of not arriving steers.',
      'Переход может избегать прибытия как бегство или сбить лодку, грузя всё прошлое, пока страх неприбытия ведёт.',
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
