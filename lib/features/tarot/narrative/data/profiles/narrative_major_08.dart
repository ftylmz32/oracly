/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor08 = NarrativeCardProfile(
  canonicalCardId: 'major_08',
  coreMeaning: L10nTriple(
    'Yoğun dürtülerle savaşmadan, şefkatli cesaret ve özdenetimle ilişki kurmayı anlatır.',
    'It concerns meeting intense impulses with compassionate courage and restraint rather than combat.',
    'Карта говорит о встрече с сильными импульсами через сострадательную смелость и самообладание, а не борьбу.',
  ),
  light: L10nTriple(
    'Yumuşak bir kararlılık, zor duyguları bastırmadan taşıyabilecek alan yaratabilir.',
    'Gentle resolve can create room to hold difficult feelings without suppressing them.',
    'Мягкая решимость может создать место для трудных чувств без их подавления.',
  ),
  shadow: L10nTriple(
    'Dayanıklılık beklentisi, incinmeyi inkâr etmeye veya sürekli güçlü görünmeye dönüşebilir.',
    'The expectation of resilience can become denial of hurt or a need to appear strong.',
    'Ожидание стойкости может превратиться в отрицание боли или необходимость всегда казаться сильным.',
  ),
  tension: L10nTriple(
    'İçgüdüyü serbest bırakmak ile onu bilinçli biçimde yönlendirmek arasında denge aranır.',
    'Balance is sought between releasing instinct and guiding it consciously.',
    'Ищется равновесие между свободой инстинкта и его осознанным направлением.',
  ),
  desire: L10nTriple(
    'Kişi, sertleşmeden dayanabilmek ve kendi yoğunluğuna güvenmek isteyebilir.',
    'Enduring without hardening — and trusting one\'s own intensity — may be the quiet aim.',
    'Может хотеться выдерживать трудности без ожесточения и доверять собственной силе чувств.',
  ),
  fear: L10nTriple(
    'Duyguların kontrolden çıkması veya kırılganlığın zayıflık sayılması korkutabilir.',
    'Emotions becoming unmanageable or vulnerability being mistaken for weakness may feel frightening.',
    'Может пугать потеря управления чувствами или восприятие уязвимости как слабости.',
  ),
  relationshipDynamic: L10nTriple(
    'Sabırlı güven verir; gücü üstünlük yerine güvenli yakınlık kurmak için kullanır.',
    'It offers patient trust and uses strength to create safe closeness rather than dominance.',
    'Карта дает терпеливое доверие и направляет силу на безопасную близость, а не превосходство.',
  ),
  decisionDynamic: L10nTriple(
    'Burada yön gösteren şeyin en sakin cesaret olması, en güçlü tepkinin olmasından daha iyi işler.',
    'Quiet courage serves better as a guide here than whatever reaction happens to be strongest.',
    'Спокойная смелость служит здесь лучшим ориентиром, чем самая сильная реакция.',
  ),
  actionDirection: L10nTriple(
    'Tepkiyi yavaşlatın, duyguyu adlandırın ve gücünüzü ölçülü bir sınırda kullanın.',
    'Slow the reaction, name the feeling, and use your strength through a measured boundary.',
    'Замедлите реакцию, назовите чувство и проявите силу через соразмерную границу.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Şefkatle yönetilen cesaret, yoğun enerjiyi sakin ve dayanıklı bir güce dönüştürür.',
      'Courage guided by compassion turns intensity into calm, enduring strength.',
      'Смелость, направляемая состраданием, превращает напряжение в спокойную и стойкую силу.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['courage', 'compassion', 'restraint'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Güç içeri çekilebilir, tükenebilir ya da bastırılmış dürtü olarak sertçe taşabilir.',
      'Strength may withdraw, diminish, or erupt harshly from suppressed instinct.',
      'Сила может уйти внутрь, ослабнуть или резко прорваться из подавленного инстинкта.',
    ),
    transforms: [
      ReversedTransformKind.internalization,
      ReversedTransformKind.deficiency,
    ],
    keywordIds: ['selfDoubt', 'suppression', 'strain'],
  ),
  symbolTags: [
    NarrativeSymbolTags.courage,
    NarrativeSymbolTags.compassion,
    NarrativeSymbolTags.restraint,
  ],
  profileRevision: 1,
);
