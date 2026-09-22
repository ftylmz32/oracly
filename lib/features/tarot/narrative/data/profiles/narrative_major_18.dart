/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor18 = NarrativeCardProfile(
  canonicalCardId: 'major_18',
  coreMeaning: L10nTriple(
    'Belirsizlikte yükselen imgeleri, sezgileri ve korkuların algıyı nasıl biçimlendirdiğini anlatır.',
    'It concerns images and intuitions arising in uncertainty, and how fear shapes perception.',
    'Карта связана с образами и интуицией в неопределенности, а также с влиянием страха на восприятие.',
  ),
  light: L10nTriple(
    'Rüya dili ve hassas sezgi, mantığın henüz adlandıramadığı bir örüntüyü gösterebilir.',
    'Dream language and sensitive intuition can reveal a pattern reason has not yet named.',
    'Язык снов и тонкая интуиция могут показать узор, который разум еще не назвал.',
  ),
  shadow: L10nTriple(
    'Korku, eksik bilgiyi yanıltıcı öykülerle doldurup gerçekliği bulanıklaştırabilir.',
    'Fear can fill missing information with misleading stories and blur reality.',
    'Страх может заполнить пробелы обманчивыми историями и затуманить действительность.',
  ),
  tension: L10nTriple(
    'İçsel işarete kulak vermek ile onu kanıtlanmış gerçek sanmamak arasında dikkat gerekir.',
    'Care is needed between hearing an inner signal and treating it as proven fact.',
    'Нужна осторожность, чтобы услышать внутренний сигнал, но не принять его за доказанный факт.',
  ),
  desire: L10nTriple(
    'Kişi, karmaşık duyguların içinden güvenilir bir anlam ve yön bulmak isteyebilir.',
    'There may be a wish to find trustworthy meaning and direction within complex feelings.',
    'Может хотеться найти надежный смысл и направление среди сложных чувств.',
  ),
  fear: L10nTriple(
    'Aldanmak, gizli bir tehlikeyi kaçırmak veya kendi algısına güvenememek korkutabilir.',
    'Being deceived, missing a hidden risk, or distrusting one\'s perception may feel frightening.',
    'Может пугать обман, пропущенная скрытая опасность или недоверие к собственному восприятию.',
  ),
  relationshipDynamic: L10nTriple(
    'Yansıtma ve belirsizliği artırabilir; niyet okumak yerine deneyimi açıkça sormayı önerir.',
    'It can heighten projection and ambiguity, favoring direct inquiry over reading intentions.',
    'Карта усиливает проекции и неясность, предлагая прямой вопрос вместо угадывания намерений.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, sezgiyi not edip doğrulanabilir bilgiden ayrı tutmayı ve zaman tanımayı ister.',
    'The decision asks that intuition be noted, separated from verifiable information, and given time.',
    'Решение требует заметить интуицию, отделить ее от проверяемых данных и дать время.',
  ),
  actionDirection: L10nTriple(
    'Varsayımı yazın, gerçeği doğrulayın ve yoğun duyguda kesin hükmü erteleyin.',
    'Write down the assumption, verify the facts, and postpone certainty during intense emotion.',
    'Запишите предположение, проверьте факты и отложите окончательный вывод при сильных эмоциях.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Belirsizliğe dikkatle bakmak, sezgisel derinliği gerçeklik kontrolüyle birlikte tutar.',
      'Careful attention to uncertainty holds intuitive depth alongside reality testing.',
      'Внимание к неопределенности соединяет глубину интуиции с проверкой реальности.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['illusion', 'subconscious', 'uncertainty'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sis incelmeye başlayabilir, fakat korku hâlâ işaretleri çarpıtabilir veya içerde tutabilir.',
      'The fog may begin to thin, though fear can still distort or internalize signals.',
      'Туман может начать рассеиваться, хотя страх еще способен искажать или удерживать сигналы внутри.',
    ),
    transforms: [
      ReversedTransformKind.distortion,
      ReversedTransformKind.privateInternal,
    ],
    keywordIds: ['confusion', 'projection', 'fear'],
  ),
  symbolTags: [
    NarrativeSymbolTags.illusion,
    NarrativeSymbolTags.subconscious,
    NarrativeSymbolTags.uncertainty,
  ],
  profileRevision: 1,
);
