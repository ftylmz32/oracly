/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

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
    'Smothering control, self-exhaustion, or taking everything on can appear when Care goes too far.',
    'Забота может стать удушающим контролем, самоистощением или принятием всего на себя.',
  ),
  tension: L10nTriple(
    'Bakma isteği ile yön dayatma riski aynı anda durur.',
    'The wish to tend sits beside the risk of imposing direction.',
    'Желание ухаживать соседствует с риском навязать направление.',
  ),
  desire: L10nTriple(
    'Kişi, elindeki alanı güvenilir ve bereketli tutmak isteyebilir.',
    'Keeping what is in hand reliable and fertile may be longed for.',
    'Может хотеться держать пространство в руке надёжным и плодородным.',
  ),
  fear: L10nTriple(
    'Bakımsız kalmak veya yeterince gözetememek kaygı yaratabilir.',
    'Being untended, or not stewarding enough, may cause unease.',
    'Тревогу может вызывать остаться без ухода или недостаточно опекать.',
  ),
  relationshipDynamic: L10nTriple(
    'Bir bağın içinde pratik bir gözetim türü gelişebilir; birine bakmak, onun yönünü belirlemekten farklı bir şeydir.',
    'A practical kind of stewardship can grow inside a bond, where tending someone is different from steering their direction.',
    'Внутри связи может расти практическая форма попечения, где заботиться о ком-то — не то же самое, что определять его направление.',
  ),
  decisionDynamic: L10nTriple(
    'Gerçekten beslenmesi ve korunması gereken şey, yalnızca hesap verebilirliği taşıyandan ayrı olarak adlandırılmaya değer.',
    'What actually needs nourishing and protecting is worth naming apart from who simply holds accountability.',
    'То, что действительно нуждается в питании и защите, стоит назвать отдельно от того, кто просто несёт подотчётность.',
  ),
  actionDirection: L10nTriple(
    'Zaten büyümekte olanı beslemeyi sürdürün ve bakım kontrole benzemeye başladığı an tutuşunuzu gevşetin.',
    'Keep tending what is already growing, and loosen your grip the moment care starts to feel like control.',
    'Продолжайте ухаживать за тем, что уже растёт, и ослабляйте хватку в тот момент, когда забота начинает напоминать контроль.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Olgun gözetim, bakımı emir vermekten ayrı tutar.',
      'Mature stewardship holds care apart from giving orders.',
      'Зрелое попечение держит заботу отдельно от отдачи приказов.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [NarrativeKeywordIds.nurture, NarrativeKeywordIds.stewardship],
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
    keywordIds: [NarrativeKeywordIds.control, NarrativeKeywordIds.exhaustion],
  ),
  symbolTags: [
    NarrativeSymbolTags.nurture,
    NarrativeSymbolTags.stability,
    NarrativeSymbolTags.abundance,
  ],
  profileRevision: 1,
);
