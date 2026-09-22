/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups14 = NarrativeCardProfile(
  canonicalCardId: 'cups_14',
  coreMeaning: L10nTriple(
    'Suyu yönlendiren sakin duruşu anlatır; duyguları kontrol eden bir rol değil, ölçülü sorumluluk alanıdır.',
    'A calm stance that steers water; not a role that controls emotion, but a field of measured responsibility.',
    'Говорит о спокойной позе, направляющей воду; не о роли, контролирующей эмоции, а о поле сдержанной ответственности.',
  ),
  light: L10nTriple(
    'Ölçülü su, donmadan yön vererek duygusal alanı netleştirebilir.',
    'Measured water can clarify the emotional field by steering without freezing.',
    'Сдержанная вода может прояснить эмоциональное поле, направляя без замораживания.',
  ),
  shadow: L10nTriple(
    'Yön verme soğukluğa, bastırmaya veya donmuş bir duruşa kayabilir.',
    'Steering may harden into coldness, suppression, or a frozen stance.',
    'Направление может стать холодностью, подавлением или замёрзшей позой.',
  ),
  tension: L10nTriple(
    'Sorumlulukla yön verme arzusu ile duyguyu dondurmama ihtiyacı birlikte durur.',
    'The wish to steer with responsibility coexists with the need not to freeze feeling.',
    'Желание направлять с ответственностью соседствует с нуждой не замораживать чувство.',
  ),
  desire: L10nTriple(
    'Kişi, duygusal akışı ölçülü bir sorumlulukla yönlendirmek isteyebilir.',
    'Quietly, one may seek to steer emotional flow with measured responsibility.',
    'Может хотеться направлять эмоциональный поток с сдержанной ответственностью.',
  ),
  fear: L10nTriple(
    'Kontrolü kaybetmek veya soğuk görünmek kaygı yaratabilir.',
    'Losing steerage, or seeming cold, may cause unease.',
    'Тревогу может вызывать утрата управления или вид холодности.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasında ölçülü bir yön duygusu ortaya çıkabilir; sorumlu kalmak, soğumakla aynı şey değildir.',
    'A measured sense of direction can appear between two people, and staying responsible is not the same as turning cold.',
    'Между двумя людьми может появиться сдержанное чувство направления, и оставаться ответственным — не то же самое, что становиться холодным.',
  ),
  decisionDynamic: L10nTriple(
    'Duygusal alana sorumluluk getirmek, içinden geçeni bastırmaktan daha iyi işler.',
    'Bringing responsibility to the emotional field works better than suppressing what moves through it.',
    'Внести ответственность в эмоциональное поле работает лучше, чем подавлять то, что через него проходит.',
  ),
  actionDirection: L10nTriple(
    'Elinizi sabit tutarak yön verin; ölçünün donmaya ya da bastırmaya dönüşmeyeceği kadar sıcak kalın.',
    'Steer with a steady hand, staying warm enough that measure never turns into freezing or suppression.',
    'Направляйте твёрдой рукой, оставаясь достаточно тёплым, чтобы мера не превратилась в заморозку или подавление.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sakin bir sorumluluk, suyu soğukluk olmadan ölçülü yönlendirir.',
      'Calm responsibility steers water with measure, without coldness.',
      'Спокойная ответственность направляет воду с мерой, без холодности.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['steeringWater', 'measuredFlow', 'calmStance'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yön verme sıcak ifadeyi soğuklukta engelleyebilir veya duyguyu donmuş bir duruşa içe çekebilir.',
      'Steering may block warm expression into coldness, or internalize feeling until the stance freezes.',
      'Направление может заблокировать тёплое выражение в холодность или увести чувство внутрь, пока поза не замёрзнет.',
    ),
    transforms: [
      ReversedTransformKind.blockedExpression,
      ReversedTransformKind.internalization,
    ],
    keywordIds: ['coldness', 'suppression', 'frozenStance'],
  ),
  symbolTags: [
    NarrativeSymbolTags.restraint,
    NarrativeSymbolTags.accountability,
    NarrativeSymbolTags.clarity,
  ],
  profileRevision: 1,
);
