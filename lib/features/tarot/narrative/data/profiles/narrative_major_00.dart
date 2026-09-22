/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor00 = NarrativeCardProfile(
  canonicalCardId: 'major_00',
  coreMeaning: L10nTriple(
    'Yeni bir eşiğe, sonucu bilmeden ama öğrenmeye açık biçimde yaklaşmayı anlatır.',
    'Approaching a new threshold without certainty, yet with openness to learn.',
    'Эта карта говорит о приближении к новому порогу без уверенности, но с готовностью учиться.',
  ),
  light: L10nTriple(
    'Merak, alışılmış sınırların ötesinde taze bir deneyime alan açabilir.',
    'Curiosity can make room for a fresh experience beyond familiar boundaries.',
    'Любопытство может открыть место новому опыту за пределами привычных границ.',
  ),
  shadow: L10nTriple(
    'Özgürlük isteği, sonuçları hesaba katmayan dağınık bir atılıma dönüşebilir.',
    'The wish for freedom can become a scattered leap that overlooks consequences.',
    'Стремление к свободе может стать беспорядочным шагом без учета последствий.',
  ),
  tension: L10nTriple(
    'İlerleme arzusu ile zemini yoklama ihtiyacı aynı anda hissedilir.',
    'The urge to move forward coexists with the need to test the ground.',
    'Желание двигаться вперед соседствует с необходимостью проверить почву.',
  ),
  desire: L10nTriple(
    'Kişi, geçmiş tanımların yükü olmadan kendini yeniden deneyimlemek isteyebilir.',
    'One may long to meet oneself without the weight of old definitions.',
    'Может возникнуть желание почувствовать себя без груза прежних определений.',
  ),
  fear: L10nTriple(
    'İlk adımın saflığı altında, hazırlıksız kalma veya yönünü kaybetme kaygısı bulunabilir.',
    'Beneath the fresh start may sit a concern about being unprepared or losing direction.',
    'За свежим началом может скрываться тревога о неготовности или потере направления.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağ içinde canlılık getirir; yine de yakınlığın sorumluluğunu hafife almamayı hatırlatır.',
    'It brings freshness to a bond while asking that intimacy not be treated lightly.',
    'Карта приносит свежесть в связь, напоминая не относиться к близости легкомысленно.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, kusursuz güvence aramak yerine yeterli farkındalıkla denemeyi gerektirebilir.',
    'The choice may call for an informed experiment rather than perfect reassurance.',
    'Выбор может потребовать осознанной пробы, а не поиска безупречных гарантий.',
  ),
  actionDirection: L10nTriple(
    'Küçük bir adım atın, çevrenizi gözleyin ve öğrendikçe yönünüzü ayarlayın.',
    'Take one modest step, observe your surroundings, and adjust as you learn.',
    'Сделайте небольшой шаг, наблюдайте за обстановкой и уточняйте курс по мере опыта.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Açık zihin ve esneklik, bilinmeyenle canlı fakat ölçülü bir karşılaşmayı destekler.',
      'An open mind and flexibility support a lively yet measured encounter with the unknown.',
      'Открытость и гибкость поддерживают живую, но бережную встречу с неизвестным.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['threshold', 'curiosity', 'freedom'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Başlangıç enerjisi, tereddüt ya da düşüncesiz acele yüzünden yönünü bulamayabilir.',
      'Starting energy may lose direction through hesitation or an unconsidered rush.',
      'Энергия начала может сбиться с пути из-за колебаний или необдуманной спешки.',
    ),
    transforms: [
      ReversedTransformKind.avoidance,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: ['haste', 'scatter', 'avoidance'],
  ),
  symbolTags: [
    NarrativeSymbolTags.threshold,
    NarrativeSymbolTags.curiosity,
    NarrativeSymbolTags.freedom,
  ],
  profileRevision: 1,
);
