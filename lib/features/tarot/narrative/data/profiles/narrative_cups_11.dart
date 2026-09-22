/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups11 = NarrativeCardProfile(
  canonicalCardId: 'cups_11',
  coreMeaning: L10nTriple(
    'Suyun elçisini anlatır; derin deniz değil, duygusal dil öğrenme alanıdır.',
    'It speaks of a messenger of water; not the deep sea, but a field of learning emotional language.',
    'Говорит о посланнике воды; не о глубоком море, а о поле изучения языка чувств.',
  ),
  light: L10nTriple(
    'Yumuşak merak, her duyguyu kehanete çevirmeden hissetmeye alan açabilir.',
    'Soft curiosity can make room to feel without turning every feeling into an oracle.',
    'Мягкое любопытство может дать место чувствовать, не превращая каждое чувство в оракул.',
  ),
  shadow: L10nTriple(
    'Merak aşırı duyarlılığa, kaçış düşüne veya her işareti abartmaya kayabilir.',
    'Curiosity may slide into over-sensitivity, escape-dream, or overreading every sign.',
    'Любопытство может стать сверхчувствительностью, мечтой-бегством или преувеличением каждого знака.',
  ),
  tension: L10nTriple(
    'Hisleri öğrenme arzusu ile onları kehanet saymama ihtiyacı birlikte durur.',
    'The wish to learn feelings coexists with the need not to treat them as prophecy.',
    'Желание изучать чувства соседствует с нуждой не считать их пророчеством.',
  ),
  desire: L10nTriple(
    'Kişi, duygusal dili utangaç ama açık bir merakla öğrenmek isteyebilir.',
    'There may be a wish to learn emotional language with shy, open curiosity.',
    'Может хотеться изучать язык чувств с застенчивым открытым любопытством.',
  ),
  fear: L10nTriple(
    'Çok hissetmek veya duyguları yanlış okumak kaygı yaratabilir.',
    'Feeling too much, or misreading feelings, may cause unease.',
    'Тревогу может вызывать слишком сильное чувствование или неверное прочтение чувств.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda yumuşak bir merak belirebilir; her hissi kehanetten ayırmayı ister.',
    'Soft curiosity may appear in a bond; it asks to separate each feeling from prophecy.',
    'В связи может возникнуть мягкое любопытство; карта просит отделить каждое чувство от пророчества.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, derin kesinlikte değil, öğrenilen duygusal dilin farkında olmaya yaslanır.',
    'The choice leans on noticing learned emotional language, not on deep certainty.',
    'Выбор опирается на замечание изучаемого языка чувств, а не на глубокую уверенность.',
  ),
  actionDirection: L10nTriple(
    'Yumuşakça hissedin, merakı koruyun; her duyguyu kehanet yapmayın.',
    'Feel softly, protect curiosity; do not make every feeling an oracle.',
    'Чувствуйте мягко, берегите любопытство; не делайте каждое чувство оракулом.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Öğrenen bir merak, suyun elçisini derin deniz sanmadan tutar.',
      'Learning curiosity holds the messenger of water without mistaking it for the deep sea.',
      'Учащееся любопытство держит посланника воды, не принимая его за глубокое море.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['waterMessenger', 'softCuriosity', 'feelingLanguage'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Merak aşırı duyarlılığa, kaçış düşüne veya işaret abartısına kayabilir.',
      'Curiosity may slide into over-sensitivity, escape-dream, or sign exaggeration.',
      'Любопытство может стать сверхчувствительностью, мечтой-бегством или преувеличением знаков.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.distortion,
    ],
    keywordIds: ['overSensitivity', 'escapeDream', 'oracleFeeling'],
  ),
  symbolTags: [
    NarrativeSymbolTags.curiosity,
    NarrativeSymbolTags.intuition,
    NarrativeSymbolTags.mystery,
  ],
  profileRevision: 1,
);
