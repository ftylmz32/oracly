/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeCups05 = NarrativeCardProfile(
  canonicalCardId: 'cups_05',
  coreMeaning: L10nTriple(
    'Dökülen kadehler ile ayakta kalanları birlikte anlatır; kayıp ve yas alanıdır.',
    'Spilled cups beside those still standing; a field of loss and mourning.',
    'Говорит о разлитых чашах рядом с ещё стоящими; поле утраты и скорби.',
  ),
  light: L10nTriple(
    'Yas tutulduğunda, dökülen görülür ve ayakta kalan da sayılabilir.',
    'When mourning is allowed, the spilled is seen and what still stands can be counted.',
    'Когда скорби дают место, разлитое видно, и ещё стоящее можно сосчитать.',
  ),
  shadow: L10nTriple(
    'Bakış yalnızca kayba kilitlenebilir; umutsuzluk veya inkâr baskınlaşabilir.',
    'Gaze may lock only on loss; despair or denial may dominate.',
    'Взгляд может зафиксироваться только на утрате; могут возобладать отчаяние или отрицание.',
  ),
  tension: L10nTriple(
    'Acıyı onurlandırma ihtiyacı ile ayakta kalanı da sayma gereği birlikte durur.',
    'The need to honor pain coexists with the duty to count what still stands.',
    'Нужда почтить боль соседствует с долгом сосчитать ещё стоящее.',
  ),
  desire: L10nTriple(
    'Kişi, kaybı yok saymadan yasını tamamlamak isteyebilir.',
    'Mourning may need room to finish without denying what was lost.',
    'Может хотеться завершить скорбь, не отрицая утрату.',
  ),
  fear: L10nTriple(
    'Acının bitmemesi veya kalanın da kaybolması kaygı yaratabilir.',
    'Pain not ending, or what remains also vanishing, may cause unease.',
    'Тревогу может вызывать нескончаемая боль или исчезновение и того, что ещё осталось.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasındaki kayıp keskin hissedilebilir; yas tutmak, aralarında kalanı saymaktan farklı bir şeydir.',
    'Loss between two people can feel sharp, and mourning stays different from counting what still remains between them.',
    'Утрата между двумя людьми может ощущаться остро; скорбь остаётся не тем же самым, что подсчёт оставшегося между ними.',
  ),
  decisionDynamic: L10nTriple(
    'Ayakta kalan da, dökülen kadar hesaba katılmayı hak eder.',
    'What still stands deserves as much accounting as what spilled.',
    'То, что ещё стоит, заслуживает не меньшего учёта, чем то, что разлилось.',
  ),
  actionDirection: L10nTriple(
    'Döküleni görün, yas tutun; ayakta kalanı da sayın.',
    'See the spilled, honor the mourning; also count what still stands.',
    'Увидьте разлитое, почтите скорбь; также сосчитайте ещё стоящее.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Dürüst bir yas, döküleni onurlandırırken ayakta kalanı da görünür kılar.',
      'Honest mourning honors the spilled while keeping what stands visible.',
      'Честная скорбь чтит разлитое, оставляя видимым и стоящее.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.overflow,
      NarrativeKeywordIds.grief,
      NarrativeKeywordIds.stability,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bakış dökülene aşırı kilitlenebilir veya ayakta kalana dönmeyi inkâr ederek kaçınabilir.',
      'Gaze may tip into excess fixation on what spilled, or avoid turning toward what still stands.',
      'Взгляд может чрезмерно зафиксироваться на разлитом или избегать поворота к тому, что ещё стоит.',
    ),
    transforms: [ReversedTransformKind.excess, ReversedTransformKind.avoidance],
    keywordIds: [NarrativeKeywordIds.despair, NarrativeKeywordIds.denial],
  ),
  symbolTags: [
    NarrativeSymbolTags.grief,
    NarrativeSymbolTags.ending,
    NarrativeSymbolTags.release,
  ],
  profileRevision: 1,
);
