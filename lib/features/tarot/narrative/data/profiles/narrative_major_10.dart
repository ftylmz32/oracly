/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor10 = NarrativeCardProfile(
  canonicalCardId: 'major_10',
  coreMeaning: L10nTriple(
    'Koşulların döngüsel değişimini ve her şeyin aynı ölçüde kontrol edilemeyeceğini hatırlatır.',
    'It recalls the cyclical movement of conditions and that not everything is equally controllable.',
    'Карта напоминает о цикличности обстоятельств и о том, что не все поддается одинаковому контролю.',
  ),
  light: L10nTriple(
    'Değişimi tanımak, yeni koşullara daha esnek ve zamanında karşılık vermeyi sağlar.',
    'Recognizing change allows a more flexible and timely response to new conditions.',
    'Признание перемен помогает гибче и своевременнее отвечать новым обстоятельствам.',
  ),
  shadow: L10nTriple(
    'Akış fikri, sorumluluğu şansa bırakmanın veya edilgen beklemenin bahanesi olabilir.',
    'The idea of flow can excuse leaving responsibility to chance or waiting passively.',
    'Идея потока может стать оправданием пассивного ожидания или передачи ответственности случаю.',
  ),
  tension: L10nTriple(
    'Etkileyebildiğimiz alan ile kabul etmemiz gereken değişkenlik birbirine dokunur.',
    'What we can influence meets the variability we must learn to accept.',
    'То, на что мы можем влиять, встречается с изменчивостью, которую приходится принимать.',
  ),
  desire: L10nTriple(
    'Kişi, sıkışmış bir düzenin hareketlenmesini ve yeni bir fırsat alanı açılmasını isteyebilir.',
    'There may be a wish for a stuck pattern to move and open space for opportunity.',
    'Может хотеться, чтобы застывшая схема сдвинулась и освободила место для возможности.',
  ),
  fear: L10nTriple(
    'Dengenin ansızın bozulması veya elverişli zamanın kaçırılması kaygı yaratabilir.',
    'A sudden shift in balance or missing a useful moment may cause concern.',
    'Тревогу могут вызывать внезапное нарушение равновесия или упущенный подходящий момент.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağın dönemsel ritmini görünür kılar; geçici değişimi kalıcı hüküm saymamayı önerir.',
    'It reveals a bond\'s changing rhythm and cautions against treating a phase as a final verdict.',
    'Карта показывает меняющийся ритм связи и советует не принимать временный этап за окончательный вывод.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, zamanlamayı okumayı ve değişebilecek unsurlar için esnek pay bırakmayı ister.',
    'The decision asks for attention to timing and room for variables that may shift.',
    'Решение требует учитывать время и оставлять пространство для меняющихся факторов.',
  ),
  actionDirection: L10nTriple(
    'Değişeni adlandırın, etki alanınızı seçin ve yeni veriye göre yaklaşımınızı güncelleyin.',
    'Name what is changing, choose your sphere of influence, and update your approach with new information.',
    'Назовите происходящие перемены, определите область влияния и обновляйте подход по новым данным.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Döngünün hareketi, uyum ve doğru zamanlamayla yeni bir geçiş alanı açar.',
      'The movement of the cycle opens a new passage through adaptability and timing.',
      'Движение цикла открывает новый переход через гибкость и чувство времени.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['cycles', 'change', 'timing'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Değişim gecikebilir, döngü dirençle uzayabilir veya hareket yanlış okunabilir.',
      'Change may be delayed, a cycle prolonged by resistance, or movement misread.',
      'Перемены могут задержаться, цикл — продлиться из-за сопротивления, а движение — быть неверно понятым.',
    ),
    transforms: [ReversedTransformKind.delay, ReversedTransformKind.distortion],
    keywordIds: ['resistance', 'delay', 'instability'],
  ),
  symbolTags: [
    NarrativeSymbolTags.cycles,
    NarrativeSymbolTags.change,
    NarrativeSymbolTags.timing,
  ],
  profileRevision: 1,
);
