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
    'A repeating hand; not shared praise, but discipline of individual mastery.',
    'Говорит о повторяющейся руке; не об общей похвале, а о дисциплине личного мастерства.',
  ),
  light: L10nTriple(
    'Aynı hareketi bilinçle sürdürmek, beceriyi derinleştirebilir.',
    'Continuing the same motion with awareness can deepen skill.',
    'Сознательно продолжать то же движение может углубить умение.',
  ),
  shadow: L10nTriple(
    'Disiplin, mekanik tekrara, kendini tüketmeye veya hiç ilerlememeye kayabilir.',
    'Discipline may harden into mechanical repetition, self-exhaustion, or never advancing.',
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
    'İki kişi arasında güvenilir, pratik bir çaba ortaya çıkabilir; aynı işi tek başına yapmak, gerçekten birlikte üretmekten farklı görünür.',
    'A reliable, practical effort can show up between two people, and doing the same task alone reads differently from actually making something together.',
    'Между двумя людьми может проявиться надёжное практическое усилие, и делать одно и то же в одиночку выглядит иначе, чем действительно создавать что-то вместе.',
  ),
  decisionDynamic: L10nTriple(
    'Bir hareketi gerçek bir farkındalıkla sürdürmek, burada başlamak için daha fazla beklemekten daha iyi işler.',
    'Continuing one motion with real awareness serves better here than waiting any longer to begin.',
    'Продолжать одно движение с настоящей осознанностью здесь полезнее, чем ждать ещё дольше, прежде чем начать.',
  ),
  actionDirection: L10nTriple(
    'Bilinçli pratiğe geri dönün ve disiplini canlı tutun; onun tamamen mekanikleştiği anı gözleyerek.',
    'Return to deliberate practice and keep the discipline alive, watching for the moment it turns purely mechanical.',
    'Вернитесь к осознанной практике и держите дисциплину живой, отслеживая момент, когда она становится чисто механической.',
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
      'Disiplin mekanik tekrar ve kendini tüketmede şişebilir veya zanaat ilerleyemeyene dek ilerlemeyi bloke edebilir.',
      'Discipline may swell into excess mechanical repetition and self-exhaustion, or block advance until the craft cannot move.',
      'Дисциплина может раздуться в избыточный механический повтор и самоистощение или блокировать продвижение, пока ремесло не сможет двигаться.',
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
