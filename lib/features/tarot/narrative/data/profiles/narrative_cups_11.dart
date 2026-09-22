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
    'The center is a messenger of water — a field of learning emotional language, rather than the deep sea.',
    'Говорит о посланнике воды; не о глубоком море, а о поле изучения языка чувств.',
  ),
  light: L10nTriple(
    'Yumuşak merak, her duyguyu kehanete çevirmeden hissetmeye alan açabilir.',
    'Soft curiosity can make room to feel without turning every feeling into an oracle.',
    'Мягкое любопытство может дать место чувствовать, не превращая каждое чувство в оракул.',
  ),
  shadow: L10nTriple(
    'Merak aşırı duyarlılığa, kaçış düşüne veya her işareti abartmaya kayabilir.',
    'Curiosity can tip into over-sensitivity, escape into dream, or overreading every sign.',
    'Любопытство может стать сверхчувствительностью, мечтой-бегством или преувеличением каждого знака.',
  ),
  tension: L10nTriple(
    'Hisleri öğrenme arzusu ile onları kehanet saymama ihtiyacı birlikte durur.',
    'The wish to learn feelings coexists with the need not to treat them as prophecy.',
    'Желание изучать чувства соседствует с нуждой не считать их пророчеством.',
  ),
  desire: L10nTriple(
    'Kişi, duygusal dili utangaç ama açık bir merakla öğrenmek isteyebilir.',
    'Someone may want to learn emotional language with shy, open curiosity.',
    'Может хотеться изучать язык чувств с застенчивым открытым любопытством.',
  ),
  fear: L10nTriple(
    'Çok hissetmek veya duyguları yanlış okumak kaygı yaratabilir.',
    'Feeling too much, or misreading feelings, may cause unease.',
    'Тревогу может вызывать слишком сильное чувствование или неверное прочтение чувств.',
  ),
  relationshipDynamic: L10nTriple(
    'İnsanlar arasında yumuşak bir merak ortaya çıkabilir; her duygu, bir kehanet yerine kendi başına okunmaya değer.',
    'A soft curiosity can appear between people, and each feeling is worth reading on its own rather than as prophecy.',
    'Между людьми может появиться мягкое любопытство, и каждое чувство стоит читать само по себе, а не как пророчество.',
  ),
  decisionDynamic: L10nTriple(
    'Hâlâ öğrenilmekte olan duygusal dili fark etmek, burada derin bir kesinliğe ulaşmaktan daha değerlidir.',
    'Noticing the emotional language still being learned matters more here than reaching for deep certainty.',
    'Замечать ещё изучаемый язык чувств здесь важнее, чем стремиться к глубокой уверенности.',
  ),
  actionDirection: L10nTriple(
    'Kendinizi yumuşakça hissetmenize izin verin ve meraklı kalın; her duyguyu bir kehanet değil, bir bilgi olarak ele alın.',
    'Let yourself feel softly and stay curious, treating each feeling as information rather than an oracle.',
    'Позвольте себе чувствовать мягко и сохраняйте любопытство, воспринимая каждое чувство как сведение, а не как оракул.',
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
      'Duygu dili her hissi işaret sayacak kadar şişebilir, ya da hayal gücü gerçekten hissedileni öğrenmek yerine içe kaçış düşüne bükülebilir.',
      'Feeling-language may swell until every sensation is treated as a sign, or imagination may bend inward into dream instead of learning what is actually felt.',
      'Язык чувств может раздуться, пока каждое ощущение не станет знаком, или воображение может уйти внутрь в мечту вместо того, чтобы учиться тому, что действительно чувствуется.',
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
