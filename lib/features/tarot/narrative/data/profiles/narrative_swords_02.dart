/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords02 = NarrativeCardProfile(
  canonicalCardId: 'swords_02',
  coreMeaning: L10nTriple(
    'İki kılıç arasında duran zihni anlatır; kilitli bir seçim duruşudur, sıkışmış hapis değil.',
    'A mind between two swords; a locked choice-stance, not a trapped prison.',
    'Говорит об уме между двумя мечами; о замкнутой позе выбора, не о тюрьме.',
  ),
  light: L10nTriple(
    'Gözler açıldığında, henüz vurmadan iki yolu görmek mümkün olur.',
    'When eyes open, both paths can be seen without striking yet.',
    'Когда глаза открыты, оба пути видны, ещё не нанося удара.',
  ),
  shadow: L10nTriple(
    'Duruş karar kaçışına, inkâra veya donmaya kayabilir.',
    'The stance may slide into flight from decision, denial, or freeze.',
    'Поза может стать бегством от решения, отрицанием или заморозкой.',
  ),
  tension: L10nTriple(
    'İki düşüncenin çekimi ile henüz seçmeme ihtiyacı birlikte hissedilir.',
    'The pull of two thoughts coexists with the need not to choose yet.',
    'Притяжение двух мыслей соседствует с нуждой ещё не выбирать.',
  ),
  desire: L10nTriple(
    'Kişi, körü körüne seçmeden önce her iki tarafı sakinçe görmek isteyebilir.',
    'A longing to see both sides calmly before choosing blindly may surface.',
    'Может хотеться спокойно увидеть обе стороны, прежде чем выбирать вслепую.',
  ),
  fear: L10nTriple(
    'Yanlış tarafı seçmek veya sonsuza dek kilitte kalmak kaygı yaratabilir.',
    'Picking the wrong side, or staying locked forever, may cause unease.',
    'Тревогу может вызывать выбор неверной стороны или вечный замок.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda bir durak belirebilir; seçim korkusunu görmeyi, vurmamayı ister.',
    'A pause may appear in a bond; it asks to see fear of choosing without striking.',
    'В связи может явиться пауза; карта просит видеть страх выбора, не нанося удара.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, acele hükmü erteleyerek iki seçeneği göz önünde tutmaya yaslanır.',
    'The choice leans on holding both options in view while deferring a hasty verdict.',
    'Выбор опирается на удержание обоих вариантов в виду, откладывая поспешный приговор.',
  ),
  actionDirection: L10nTriple(
    'Gözünüzü açın; henüz vurmak zorunda değilsiniz.',
    'Open your eyes; you do not have to strike yet.',
    'Откройте глаза; ещё не обязательно наносить удар.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Açık gözlü bir duruş, iki kılıcı vurmadan tutar.',
      'An open-eyed stance holds two swords without striking.',
      'Поза с открытыми глазами держит два меча, не нанося удара.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['stalemate', 'twoThoughts', 'closedEyes'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Duruş karardan kaçınmaya — inkâr veya kaçışla — kayabilir veya seçim donana dek erteleyebilir.',
      'The stance may avoid deciding through flight or denial, or delay until freeze replaces choice.',
      'Поза может избегать решения через бегство или отрицание, или откладывать, пока заморозка не заменит выбор.',
    ),
    transforms: [ReversedTransformKind.avoidance, ReversedTransformKind.delay],
    keywordIds: ['decisionFlight', 'denial', 'freeze'],
  ),
  symbolTags: [
    NarrativeSymbolTags.choice,
    NarrativeSymbolTags.pause,
    NarrativeSymbolTags.uncertainty,
  ],
  profileRevision: 1,
);
