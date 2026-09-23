/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativePentacles11 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_11',
  coreMeaning: L10nTriple(
    'Maddenin öğrencisini anlatır; tüccar değil, pratikle öğrenen meraklı bir eldir.',
    'A student hand of matter; not a merchant, but curiosity learning by practice.',
    'Говорит об ученической руке вещества; не о торговце, а о любопытстве, учащемся практикой.',
  ),
  light: L10nTriple(
    'Denemek, ustalık iddiası kurmadan el becerisini açabilir.',
    'Trying can open hand-skill without claiming mastery.',
    'Пробовать может открыть умение руки без притязания на мастерство.',
  ),
  shadow: L10nTriple(
    'Merak, acele satmaya, yüzeysel taklide veya öğrenmeyi ertelemeye kayabilir.',
    'Curiosity turns brittle when it becomes rushing to sell, shallow imitation, or postponing learning.',
    'Любопытство может стать спешкой продать, поверхностным подражанием или откладыванием учения.',
  ),
  tension: L10nTriple(
    'Öğrenme arzusu ile henüz hazır görünmeme kaygısı birlikte durur.',
    'The wish to learn coexists with unease about not yet looking ready.',
    'Желание учиться соседствует с тревогой ещё не выглядеть готовым.',
  ),
  desire: L10nTriple(
    'Kişi, pratik bir yolla maddenin dilini kavramak isteyebilir.',
    'Grasping the language of matter through practice may be the quiet aim.',
    'Может хотеться схватить язык вещества через практику.',
  ),
  fear: L10nTriple(
    'Acemi görünmek veya yanlış öğrenmek kaygı yaratabilir.',
    'Looking like a beginner, or learning wrongly, may cause unease.',
    'Тревогу может вызывать выглядеть новичком или учиться неверно.',
  ),
  relationshipDynamic: L10nTriple(
    'Pratik bir merak, iki kişi arasında bir kapı olabilir; kendini satmak ile sadece bir öğrenci olmak arasında gerçek bir fark vardır.',
    'A practical curiosity can become a door between two people, and there is a real difference between selling oneself and simply being a student.',
    'Практическое любопытство может стать дверью между двумя людьми, и есть настоящая разница между тем, чтобы себя продавать, и тем, чтобы просто быть учеником.',
  ),
  decisionDynamic: L10nTriple(
    'Gerçekten denemeye değer olan, herhangi bir sonuç satılmadan önce ilgiyi hak eder.',
    'What is actually worth trying deserves attention before any outcome gets sold.',
    'То, что действительно стоит попробовать, заслуживает внимания раньше, чем какой-либо результат будет продан.',
  ),
  actionDirection: L10nTriple(
    'Pratik yaparak öğrenin ve küçük bir deneme yapın; çok erken tüccar rolüne girmek yerine öğrenci kalarak.',
    'Learn through practice and make one small trial, staying a student rather than playing merchant too soon.',
    'Учитесь через практику и сделайте одно небольшое испытание, оставаясь учеником, а не играя слишком рано в торговца.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Öğrenen el, haberciliği tüccarlık sanmadan tutar.',
      'The learning hand holds the messenger role without mistaking it for merchant.',
      'Учащаяся рука держит роль вестника, не принимая её за торговца.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.learning,
      NarrativeKeywordIds.curiosity,
      NarrativeKeywordIds.messenger,
    ],
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
    keywordIds: [
      NarrativeKeywordIds.haste,
      NarrativeKeywordIds.display,
      NarrativeKeywordIds.delay,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.curiosity,
    NarrativeSymbolTags.craft,
    NarrativeSymbolTags.teaching,
  ],
  profileRevision: 1,
);
