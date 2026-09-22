/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords14 = NarrativeCardProfile(
  canonicalCardId: 'swords_14',
  coreMeaning: L10nTriple(
    'İlkeyle duran kılıcı anlatır; kontrol eden bir rol değil, sorumlu ve sakin yargı alanıdır.',
    'It speaks of a sword that stands on principle; not a role that controls, but a field of accountable calm judgment.',
    'Говорит о мече, стоящем на принципе; не о роли, что контролирует, а о поле ответственного спокойного суждения.',
  ),
  light: L10nTriple(
    'Ölçülü ilke, kalbi dışarıda bırakmadan zihin omurgası verebilir.',
    'Measured principle can give a mind-spine without leaving the heart outside.',
    'Сдержанный принцип может дать хребет ума, не оставляя сердце вовне.',
  ),
  shadow: L10nTriple(
    'İlke katılığa, kalpsiz kurala veya mesafe putuna kayabilir.',
    'Principle may slide into rigidity, heartless rule, or an idol of distance.',
    'Принцип может стать жёсткостью, бессердечным правилом или кумиром дистанции.',
  ),
  tension: L10nTriple(
    'Adil karar arzusu ile insanı ezmeme ihtiyacı birlikte durur.',
    'The wish for fair decision coexists with the need not to crush a person.',
    'Желание справедливого решения соседствует с нуждой не давить человека.',
  ),
  desire: L10nTriple(
    'Kişi, soğuk değil duru bir omurga istemek isteyebilir.',
    'There may be a wish for a spine that is clear, not cold.',
    'Может хотеться хребта ясного, не холодного.',
  ),
  fear: L10nTriple(
    'İlkenin insanı ezmesi veya omurganın dağılması kaygı yaratabilir.',
    'Principle crushing a person, or the spine scattering, may cause unease.',
    'Тревогу может вызывать давление принципа на человека или рассеяние хребта.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda ilke ve netlik öne çıkabilir; kontrolü sorumlu yargıdan ayırmayı ister.',
    'Principle and clarity may come forward in a bond; it asks to separate control from accountable judgment.',
    'В связи могут выйти принцип и ясность; карта просит отделить контроль от ответственного суждения.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, hükümden önce yer bırakarak adil ölçüyü netleştirir.',
    'The choice clarifies fair measure by leaving room before judgment.',
    'Выбор проясняет справедливую меру, оставляя место до суждения.',
  ),
  actionDirection: L10nTriple(
    'İlkeyi tutun; kalbi dışarıda bırakmayın, hükümden önce yer bırakın.',
    'Hold the principle; do not leave the heart outside — leave room before judgment.',
    'Держите принцип; не оставляйте сердце вовне — оставьте место до суждения.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sorumlu bir ilke, zihin omurgasını soğutmadan tutar.',
      'Accountable principle holds the mind-spine without freezing it cold.',
      'Ответственный принцип держит хребет ума, не замораживая его холодом.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['principle', 'calmJudgement', 'mindSpine'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'İlke katılığa, kalpsiz kurala veya mesafe putuna kayabilir.',
      'Principle may slide into rigidity, heartless rule, or an idol of distance.',
      'Принцип может стать жёсткостью, бессердечным правилом или кумиром дистанции.',
    ),
    transforms: [
      ReversedTransformKind.deficiency,
      ReversedTransformKind.distortion,
    ],
    keywordIds: ['rigidity', 'heartlessRule', 'distanceIdol'],
  ),
  symbolTags: [
    NarrativeSymbolTags.accountability,
    NarrativeSymbolTags.judgment,
    NarrativeSymbolTags.structure,
  ],
  profileRevision: 1,
);
