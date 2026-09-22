/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor20 = NarrativeCardProfile(
  canonicalCardId: 'major_20',
  coreMeaning: L10nTriple(
    'Geçmişi dürüstçe değerlendirip daha uyanık bir seçimle yeniden yönelmeyi anlatır.',
    'It speaks of reviewing the past honestly and choosing a more awake direction.',
    'Карта говорит о честном пересмотре прошлого и выборе более осознанного направления.',
  ),
  light: L10nTriple(
    'Açık bir öz değerlendirme, pişmanlığı öğrenmeye ve yenilenmiş sorumluluğa çevirebilir.',
    'Clear self-review can turn regret into learning and renewed responsibility.',
    'Ясная самооценка может превратить сожаление в урок и обновленную ответственность.',
  ),
  shadow: L10nTriple(
    'Uyanış çağrısı, kendini acımasızca yargılamaya veya geçmişi tekrar tekrar mahkûm etmeye dönüşebilir.',
    'The call to awaken can become merciless self-judgment or repeated condemnation of the past.',
    'Призыв к пробуждению может стать безжалостным самоосуждением или повторным приговором прошлому.',
  ),
  tension: L10nTriple(
    'Geçmişin sorumluluğunu almak ile onun tarafından tanımlanmamak arasında denge gerekir.',
    'Balance is needed between owning the past and refusing to be defined by it.',
    'Нужно равновесие между признанием прошлого и отказом позволить ему определять себя.',
  ),
  desire: L10nTriple(
    'Kişi, deneyimlerini bütünleyip daha anlamlı bir çağrıya karşılık vermek isteyebilir.',
    'There may be a wish to integrate experience and respond to a more meaningful calling.',
    'Может возникнуть желание объединить опыт и ответить на более значимый внутренний зов.',
  ),
  fear: L10nTriple(
    'Geç kalmış olmak, affedilmemek veya değişim fırsatını kaçırmak korkutabilir.',
    'Being too late, not being forgiven, or missing a chance to change may feel frightening.',
    'Может пугать опоздание, отсутствие прощения или упущенная возможность измениться.',
  ),
  relationshipDynamic: L10nTriple(
    'Geçmiş davranışları görünür kılar; suçlamadan sorumluluk ve onarım konuşmasını destekler.',
    'It makes past behavior visible and supports accountability and repair without blame.',
    'Карта проявляет прошлые поступки и поддерживает разговор об ответственности и восстановлении без обвинений.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, önceki dersleri inkâr etmeden bugünkü değerlerle yeni bir yanıt vermeyi ister.',
    'The decision asks for a new response rooted in present values without denying earlier lessons.',
    'Решение требует нового ответа из нынешних ценностей без отрицания прежних уроков.',
  ),
  actionDirection: L10nTriple(
    'Geçmişten bir dersi seçin, payınızı açıkça kabul edin ve bugün farklı davranın.',
    'Choose one lesson from the past, acknowledge your part plainly, and act differently today.',
    'Выберите один урок прошлого, прямо признайте свою роль и сегодня поступите иначе.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Dürüst bir uyanış, geçmişi yargı yerine öğrenme ve yenilenme kaynağı yapar.',
      'Honest awakening turns the past into a source of learning and renewal rather than judgment.',
      'Честное пробуждение превращает прошлое в источник обучения и обновления, а не приговора.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['awakening', 'accountability', 'renewal'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Çağrı ertelenebilir, öz yargı ağırlaşabilir veya gerekli değerlendirme içeride kalabilir.',
      'The call may be delayed, self-judgment intensify, or necessary reflection remain private.',
      'Зов может откладываться, самоосуждение усиливаться, а необходимое осмысление оставаться внутри.',
    ),
    transforms: [
      ReversedTransformKind.delay,
      ReversedTransformKind.privateInternal,
    ],
    keywordIds: ['selfJudgment', 'avoidance', 'doubt'],
  ),
  symbolTags: [
    NarrativeSymbolTags.awakening,
    NarrativeSymbolTags.accountability,
    NarrativeSymbolTags.renewal,
  ],
  profileRevision: 1,
);
