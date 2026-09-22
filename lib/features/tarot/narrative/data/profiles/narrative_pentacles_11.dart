/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles11 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_11',
  coreMeaning: L10nTriple(
    'Maddenin öğrencisini anlatır; tüccar değil, pratikle öğrenen meraklı bir eldir.',
    'It speaks of a student hand of matter; not a merchant, but curiosity learning by practice.',
    'Говорит об ученической руке вещества; не о торговце, а о любопытстве, учащемся практикой.',
  ),
  light: L10nTriple(
    'Denemek, ustalık iddiası kurmadan el becerisini açabilir.',
    'Trying can open hand-skill without claiming mastery.',
    'Пробовать может открыть умение руки без притязания на мастерство.',
  ),
  shadow: L10nTriple(
    'Merak, acele satmaya, yüzeysel taklide veya öğrenmeyi ertelemeye kayabilir.',
    'Curiosity may slide into rushing to sell, shallow imitation, or postponing learning.',
    'Любопытство может стать спешкой продать, поверхностным подражанием или откладыванием учения.',
  ),
  tension: L10nTriple(
    'Öğrenme arzusu ile henüz hazır görünmeme kaygısı birlikte durur.',
    'The wish to learn coexists with unease about not yet looking ready.',
    'Желание учиться соседствует с тревогой ещё не выглядеть готовым.',
  ),
  desire: L10nTriple(
    'Kişi, pratik bir yolla maddenin dilini kavramak isteyebilir.',
    'There may be a wish to grasp the language of matter through practice.',
    'Может хотеться схватить язык вещества через практику.',
  ),
  fear: L10nTriple(
    'Acemi görünmek veya yanlış öğrenmek kaygı yaratabilir.',
    'Looking like a beginner, or learning wrongly, may cause unease.',
    'Тревогу может вызывать выглядеть новичком или учиться неверно.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda pratik merak kapı olabilir; tüccarlığı öğrenciden ayırmayı ister.',
    'Practical curiosity may be a door in a bond; it asks to separate merchanting from the student.',
    'Практическое любопытство может быть дверью в связи; карта просит отделить торговлю от ученика.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, sonuç satmadan önce neyin deneneceğini netleştirir.',
    'The choice clarifies what to try before selling an outcome.',
    'Выбор проясняет, что пробовать, прежде чем продавать исход.',
  ),
  actionDirection: L10nTriple(
    'Pratikle öğrenin; satıcı olmayın, küçük bir deneme yapın.',
    'Learn by practice; do not play merchant — make one small trial.',
    'Учитесь практикой; не играйте торговца — сделайте одно малое испытание.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Öğrenen el, haberciliği tüccarlık sanmadan tutar.',
      'The learning hand holds the messenger role without mistaking it for merchant.',
      'Учащаяся рука держит роль вестника, не принимая её за торговца.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['studentHand', 'practicalCuriosity', 'matterMessenger'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Merak acele satmaya veya taklide sapabilir veya öğrenmeyi erteleyerek kaçınabilir.',
      'Curiosity may misdirect into rushing to sell or imitate, or avoid learning by postponing practice.',
      'Любопытство может сбиться в спешку продать или подражать, или избегать учения, откладывая практику.',
    ),
    transforms: [
      ReversedTransformKind.misdirection,
      ReversedTransformKind.avoidance,
    ],
    keywordIds: ['rushSell', 'shallowCopy', 'postponeLearn'],
  ),
  symbolTags: [
    NarrativeSymbolTags.curiosity,
    NarrativeSymbolTags.craft,
    NarrativeSymbolTags.teaching,
  ],
  profileRevision: 1,
);
