/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles13 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_13',
  coreMeaning: L10nTriple(
    'Pratik bakımın olgun elini anlatır; yön vermek değil, maddeyi gözeten vekilliktir.',
    'A mature hand of practical care names stewardship of matter; it refuses commanding direction.',
    'Говорит о зрелой руке практического заботливого ухода; не о командовании, а о попечении над веществом.',
  ),
  light: L10nTriple(
    'Gözetmek, kaynakları zorlamadan canlı tutabilir.',
    'Stewarding can keep resources alive without forcing them.',
    'Попечение может держать ресурсы живыми, не принуждая их.',
  ),
  shadow: L10nTriple(
    'Bakım, boğucu kontrole, kendini tüketmeye veya her şeyi üstlenmeye kayabilir.',
    'Pushed too far, care yields smothering control, self-exhaustion, or taking everything on.',
    'Забота может стать удушающим контролем, самоистощением или принятием всего на себя.',
  ),
  tension: L10nTriple(
    'Bakma isteği ile yön dayatma riski aynı anda durur.',
    'The wish to tend sits beside the risk of imposing direction.',
    'Желание ухаживать соседствует с риском навязать направление.',
  ),
  desire: L10nTriple(
    'Kişi, elindeki alanı güvenilir ve bereketli tutmak isteyebilir.',
    'Part of this archetype longs to keep the space in hand reliable and fertile.',
    'Может хотеться держать пространство в руке надёжным и плодородным.',
  ),
  fear: L10nTriple(
    'Bakımsız kalmak veya yeterince gözetememek kaygı yaratabilir.',
    'Being untended, or not stewarding enough, may cause unease.',
    'Тревогу может вызывать остаться без ухода или недостаточно опекать.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda pratik gözetim belirebilir; bakımı yön dayatmaktan ayırmayı ister.',
    'Practical stewardship may appear in a bond; it asks to separate care from imposing direction.',
    'В связи может явиться практическое попечение; карта просит отделить заботу от навязывания направления.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, hesap vermekten ayrı, neyin beslenip korunacağını netleştirir.',
    'The choice clarifies what to nourish and protect, apart from holding accountability alone.',
    'Выбор проясняет, что питать и беречь, отдельно от одной лишь подотчётности.',
  ),
  actionDirection: L10nTriple(
    'Pratik bakımı sürdürün; boğmayın, vekilliği yön dayatmaktan ayırın.',
    'Continue practical care; do not smother — separate stewardship from imposing direction.',
    'Продолжайте практическую заботу; не удушайте — отделите попечение от навязывания направления.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Olgun gözetim, bakımı emir vermekten ayrı tutar.',
      'Mature stewardship holds care apart from giving orders.',
      'Зрелое попечение держит заботу отдельно от отдачи приказов.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['practicalCare', 'stewardship', 'fertileHand'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bakım boğucu kontrole aşırı kayabilir veya vekilliği her şeyi üstlenmeye çarpıtabilir.',
      'Care may tip into excess control that smothers, or distort stewardship into taking everything on.',
      'Забота может перейти в избыточный удушающий контроль или исказить попечение в принятие всего на себя.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.distortion,
    ],
    keywordIds: ['smotherControl', 'selfExhaust', 'overTake'],
  ),
  symbolTags: [
    NarrativeSymbolTags.nurture,
    NarrativeSymbolTags.stability,
    NarrativeSymbolTags.abundance,
  ],
  profileRevision: 1,
);
