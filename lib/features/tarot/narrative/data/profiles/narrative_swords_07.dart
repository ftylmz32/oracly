/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords07 = NarrativeCardProfile(
  canonicalCardId: 'swords_07',
  coreMeaning: L10nTriple(
    'Görünmeden çekilen bir kılıcı anlatır; yargı değildir, saklanan bir iz alanıdır.',
    'It speaks of a sword drawn unseen; not a verdict, but a field of hidden trace.',
    'Говорит о мече, извлечённом невидимо; не о приговоре, а о поле скрытого следа.',
  ),
  light: L10nTriple(
    'Gizlenenı fark etmek, hırsız ilan etmeden stratejiyi görmeye alan açabilir.',
    'Noticing what is hidden can make room to see strategy without declaring a thief.',
    'Замечать скрытое может дать место видеть стратегию, не объявляя вора.',
  ),
  shadow: L10nTriple(
    'Saklama güvensizliğe, yalnız plana veya kendine yalana kayabilir.',
    'Hiding may slide into mistrust, a lone plan, or a lie to oneself.',
    'Укрытие может стать недоверием, одиноким планом или ложью себе.',
  ),
  tension: L10nTriple(
    'Görmek isteği ile hemen suçlama kurmama ihtiyacı birlikte durur.',
    'The wish to see coexists with the need not to assemble accusation at once.',
    'Желание видеть соседствует с нуждой не собирать обвинение сразу.',
  ),
  desire: L10nTriple(
    'Kişi, dolaylı bir hareketi veya saklanan sözü anlamak isteyebilir.',
    'There may be a wish to understand an indirect move or a hidden word.',
    'Может хотеться понять косвенное движение или скрытое слово.',
  ),
  fear: L10nTriple(
    'Aldatılma hissi veya kendi stratejisinin bozulması kaygı yaratabilir.',
    'A felt sense of being misled, or one\'s own strategy breaking, may cause unease.',
    'Тревогу может вызывать ощущение введения в заблуждение или поломка своей стратегии.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda saklanan bir söz olabilir; şüpheyi hırsız ilanından ayırmayı ister.',
    'A hidden word may sit in a bond; it asks to separate suspicion from declaring a thief.',
    'В связи может сидеть скрытое слово; карта просит отделить подозрение от объявления вора.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, kesin hüküm yerine neyin görünmediğini yoklamaya yaslanır.',
    'The choice leans on testing what is unseen rather than a fixed verdict.',
    'Выбор опирается на проверку невидимого, а не на жёсткий приговор.',
  ),
  actionDirection: L10nTriple(
    'Gizleneni görün; hırsız ilan etmeyin, korkuyu kanıttan ayırın.',
    'See what is hidden; do not declare a thief — separate fear from evidence.',
    'Увидьте скрытое; не объявляйте вора — отделите страх от свидетельства.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Görülen iz, yargı kurmadan saklananı netleştirir.',
      'A seen trace clarifies what is hidden without assembling a verdict.',
      'Увиденный след проясняет скрытое, не собирая приговор.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['hiding', 'strategy', 'unseenDraw'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Saklama güvensizliğe, yalnız plana veya kendine yalana kayabilir.',
      'Hiding may slide into mistrust, a lone plan, or a lie to oneself.',
      'Укрытие может стать недоверием, одиноким планом или ложью себе.',
    ),
    transforms: [
      ReversedTransformKind.distortion,
      ReversedTransformKind.privateInternal,
    ],
    keywordIds: ['theftFeeling', 'mistrust', 'lonePlan'],
  ),
  symbolTags: [
    NarrativeSymbolTags.inquiry,
    NarrativeSymbolTags.shadow,
    NarrativeSymbolTags.restraint,
  ],
  profileRevision: 1,
);
