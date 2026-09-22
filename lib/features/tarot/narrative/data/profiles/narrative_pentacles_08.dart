/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles08 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_08',
  coreMeaning: L10nTriple(
    'Tekrarlayan eli anlatır; ortak övgü değil, bireysel ustalık disiplinidir.',
    'It speaks of a repeating hand; not shared praise, but discipline of individual mastery.',
    'Говорит о повторяющейся руке; не об общей похвале, а о дисциплине личного мастерства.',
  ),
  light: L10nTriple(
    'Aynı hareketi bilinçle sürdürmek, beceriyi derinleştirebilir.',
    'Continuing the same motion with awareness can deepen skill.',
    'Сознательно продолжать то же движение может углубить умение.',
  ),
  shadow: L10nTriple(
    'Disiplin, mekanik tekrara, kendini tüketmeye veya hiç ilerlememeye kayabilir.',
    'Discipline may slide into mechanical repetition, self-exhaustion, or never advancing.',
    'Дисциплина может стать механическим повтором, самоистощением или отсутствием продвижения.',
  ),
  tension: L10nTriple(
    'Ustalaşma isteği ile tekrarın yorması aynı anda durur.',
    'The wish to master sits beside the fatigue of repetition.',
    'Желание овладеть соседствует с усталостью от повтора.',
  ),
  desire: L10nTriple(
    'Kişi, elinin işi güvenilir ve keskin tutmasını isteyebilir.',
    'There may be a wish for the hand to hold the craft reliable and sharp.',
    'Может хотеться, чтобы рука держала ремесло надёжным и острым.',
  ),
  fear: L10nTriple(
    'Yetersiz kalmak veya emeğin görünmemesi kaygı yaratabilir.',
    'Falling short, or labor going unseen, may cause unease.',
    'Тревогу может вызывать недостаточность или то, что труд останется незамеченным.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda güvenilir pratik çaba belirebilir; tekrarı ortak üretmekten ayırmayı ister.',
    'Reliable practical effort may appear in a bond; it asks to separate repetition from making together.',
    'В связи может явиться надёжное практическое усилие; карта просит отделить повтор от совместного делания.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, beklemeyi bırakıp hangi hareketin bilinçle sürdürüleceğini netleştirir.',
    'The choice clarifies which motion to continue with awareness, rather than waiting further.',
    'Выбор проясняет, какое движение сознательно продолжать, а не ждать дальше.',
  ),
  actionDirection: L10nTriple(
    'Bilinçli pratiğe dönün; mekanik tekrara düşmeyin, disiplini sürdürün.',
    'Return to deliberate practice; do not fall into mechanical repetition — continue the discipline.',
    'Вернитесь к осознанной практике; не падайте в механический повтор — продолжайте дисциплину.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bilinçli tekrar, ustalığı mekanik yorgunluktan ayırır.',
      'Conscious repetition separates mastery from mechanical fatigue.',
      'Сознательный повтор отделяет мастерство от механической усталости.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['repeatingHand', 'mastery', 'discipline'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Disiplin mekanik tekrara, tükenmeye veya ilerlememeye kayabilir.',
      'Discipline may slide into mechanical repetition, exhaustion, or no advance.',
      'Дисциплина может стать механическим повтором, истощением или отсутствием продвижения.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: ['mechanicalLoop', 'exhaustion', 'noAdvance'],
  ),
  symbolTags: [
    NarrativeSymbolTags.craft,
    NarrativeSymbolTags.focus,
    NarrativeSymbolTags.endurance,
  ],
  profileRevision: 1,
);
