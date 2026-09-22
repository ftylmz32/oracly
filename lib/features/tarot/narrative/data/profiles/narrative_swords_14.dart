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
    'A sword that stands on principle; not a role that controls, but a field of accountable calm judgment.',
    'Говорит о мече, стоящем на принципе; не о роли, что контролирует, а о поле ответственного спокойного суждения.',
  ),
  light: L10nTriple(
    'Ölçülü ilke, kalbi dışarıda bırakmadan zihin omurgası verebilir.',
    'Measured principle can give a mind-spine without leaving the heart outside.',
    'Сдержанный принцип может дать хребет ума, не оставляя сердце вовне.',
  ),
  shadow: L10nTriple(
    'İlke katılığa, kalpsiz kurala veya mesafe putuna kayabilir.',
    'Principle may harden into rigidity, heartless rule, or an idol of distance.',
    'Принцип может стать жёсткостью, бессердечным правилом или кумиром дистанции.',
  ),
  tension: L10nTriple(
    'Adil karar arzusu ile insanı ezmeme ihtiyacı birlikte durur.',
    'The wish for fair decision coexists with the need not to crush a person.',
    'Желание справедливого решения соседствует с нуждой не давить человека.',
  ),
  desire: L10nTriple(
    'Kişi, soğuk değil duru bir omurga istemek isteyebilir.',
    'A longing for a spine that is clear, not cold may surface.',
    'Может хотеться хребта ясного, не холодного.',
  ),
  fear: L10nTriple(
    'İlkenin insanı ezmesi veya omurganın dağılması kaygı yaratabilir.',
    'Principle crushing a person, or the spine scattering, may cause unease.',
    'Тревогу может вызывать давление принципа на человека или рассеяние хребта.',
  ),
  relationshipDynamic: L10nTriple(
    'Bir bağ içinde ilke ve netlik öne çıkabilir; hesap verebilir kalmak, kontrolü ele almakla aynı şey değildir.',
    'Principle and clarity can come forward inside a bond, and staying accountable is not the same as taking control.',
    'Внутри связи могут выйти на первый план принцип и ясность, и оставаться подотчётным — не то же самое, что брать контроль.',
  ),
  decisionDynamic: L10nTriple(
    'Hükümden önce yer bırakmak, burada gerçekten adil bir ölçüyü ortaya çıkaran şeydir.',
    'Leaving room before judgment is what actually produces a fair measure here.',
    'Именно то, что оставлено место до суждения, и рождает здесь справедливую меру.',
  ),
  actionDirection: L10nTriple(
    'İlkeyi sıkıca tutun, ama kalbi de onun içinde tutun; herhangi bir hüküm inmeden önce yer bırakarak.',
    'Hold the principle firmly while keeping the heart inside it, leaving room before any judgment lands.',
    'Твёрдо держите принцип, но не оставляйте сердце снаружи — оставляйте место до того, как прозвучит суждение.',
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
      'İlke, yargıyı adil tutan insanî bağlamı bırakabilir, ya da yapı mesafeli bir kontrole bükülebilir.',
      'Principle may shed the human context that keeps judgment fair, or structure may be bent into detached control.',
      'Принцип может сбросить человеческий контекст, который делает суждение справедливым, или структура может быть изогнута в отстранённый контроль.',
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
