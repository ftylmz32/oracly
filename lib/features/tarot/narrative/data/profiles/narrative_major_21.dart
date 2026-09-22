/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor21 = NarrativeCardProfile(
  canonicalCardId: 'major_21',
  coreMeaning: L10nTriple(
    'Bir döngünün bütünlenmesini, kazanılan deneyimin yerini bulmasını ve aidiyeti temsil eder.',
    'It represents a cycle becoming whole, experience finding its place, and a sense of belonging.',
    'Карта означает целостное завершение цикла, обретение опытом своего места и чувство принадлежности.',
  ),
  light: L10nTriple(
    'Tamamlanmayı tanımak, emeği onurlandırır ve sonraki eşiğe hafiflikle geçiş sağlar.',
    'Recognizing completion honors effort and allows a lighter passage toward the next threshold.',
    'Признание завершения чтит вложенный труд и облегчает переход к следующему порогу.',
  ),
  shadow: L10nTriple(
    'Kusursuz kapanış beklentisi, yeterince tamamlanmış olanı teslim etmeyi geciktirebilir.',
    'Expecting perfect closure can delay releasing what is already complete enough.',
    'Ожидание идеального завершения может задержать отпускание того, что уже достаточно закончено.',
  ),
  tension: L10nTriple(
    'Başarıyı sahiplenmek ile yeni döngünün bilinmezliğine geçmek arasında eşik oluşur.',
    'A threshold forms between owning an achievement and entering the uncertainty of a new cycle.',
    'Возникает порог между признанием достижения и входом в неизвестность нового цикла.',
  ),
  desire: L10nTriple(
    'Kişi, parçalarının uyumlu bir bütünde yer bulmasını ve emeğinin tamamlanmasını isteyebilir.',
    'The energy leans toward all parts to belong within a coherent whole and for work to conclude.',
    'Может хотеться, чтобы все части нашли место в целостности, а труд получил завершение.',
  ),
  fear: L10nTriple(
    'Bitirince boşlukla kalmak, ait olduğu yerden ayrılmak veya eksik görülmek korkutabilir.',
    'Finishing may bring fear of emptiness, leaving belonging, or being seen as incomplete.',
    'Завершение может пугать пустотой, уходом из привычной среды или ощущением незавершенности.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağın ortak yolunu onurlandırır; tamamlanmış döngüleri zorla sürdürmeden aidiyeti korur.',
    'It honors a shared journey and preserves belonging without forcing finished cycles to continue.',
    'Карта чтит общий путь и сохраняет принадлежность, не заставляя завершенные циклы продолжаться.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, yeterli bütünlüğü tanımayı ve açık kalan küçük parçaları bilinçle kapatmayı ister.',
    'The decision asks for recognizing sufficient wholeness and consciously closing minor loose ends.',
    'Решение требует признать достаточную целостность и осознанно завершить оставшиеся мелочи.',
  ),
  actionDirection: L10nTriple(
    'Tamamlananı adlandırın, katkıları onurlandırın ve bir sonraki adım için alan boşaltın.',
    'Name what is complete, honor the contributions, and clear space for what follows.',
    'Назовите завершенное, почтите вклад участников и освободите место для следующего шага.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bütünlenen deneyim, başarıyı aidiyet ve olgun bir kapanış duygusuyla birleştirir.',
      'Integrated experience joins achievement with belonging and a mature sense of closure.',
      'Целостный опыт соединяет достижение с принадлежностью и зрелым чувством завершения.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['completion', 'belonging', 'integration'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Kapanış gecikebilir, başarı içselleştirilemeyebilir veya son ayrıntılar süreci tutabilir.',
      'Closure may be delayed, achievement remain unabsorbed, or final details hold the process back.',
      'Завершение может задержаться, достижение — не усвоиться, а последние детали — удерживать процесс.',
    ),
    transforms: [
      ReversedTransformKind.delay,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: ['incompletion', 'delay', 'disconnection'],
  ),
  symbolTags: [
    NarrativeSymbolTags.completion,
    NarrativeSymbolTags.belonging,
    NarrativeSymbolTags.integration,
  ],
  profileRevision: 1,
);
