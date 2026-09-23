/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeSwords07 = NarrativeCardProfile(
  canonicalCardId: 'swords_07',
  coreMeaning: L10nTriple(
    'Görünmeden çekilen bir kılıcı anlatır; yargı değildir, saklanan bir iz alanıdır.',
    'A sword drawn unseen is not a verdict; it is a field of hidden trace.',
    'Говорит о мече, извлечённом невидимо; не о приговоре, а о поле скрытого следа.',
  ),
  light: L10nTriple(
    'Gizlenenı fark etmek, hırsız ilan etmeden stratejiyi görmeye alan açabilir.',
    'Noticing what is hidden can make room to see strategy without declaring a thief.',
    'Замечать скрытое может дать место видеть стратегию, не объявляя вора.',
  ),
  shadow: L10nTriple(
    'Saklama güvensizliğe, yalnız plana veya kendine yalana kayabilir.',
    'Strategy can tip into mistrust, a lone plan, or a lie to oneself.',
    'Укрытие может стать недоверием, одиноким планом или ложью себе.',
  ),
  tension: L10nTriple(
    'Görmek isteği ile hemen suçlama kurmama ihtiyacı birlikte durur.',
    'The wish to see coexists with the need not to assemble accusation at once.',
    'Желание видеть соседствует с нуждой не собирать обвинение сразу.',
  ),
  desire: L10nTriple(
    'Kişi, dolaylı bir hareketi veya saklanan sözü anlamak isteyebilir.',
    'Understanding an indirect move or a hidden word may become important.',
    'Может хотеться понять косвенное движение или скрытое слово.',
  ),
  fear: L10nTriple(
    'Aldatılma hissi veya kendi stratejisinin bozulması kaygı yaratabilir.',
    'A felt sense of being misled, or one\'s own strategy breaking, may cause unease.',
    'Тревогу может вызывать ощущение введения в заблуждение или поломка своей стратегии.',
  ),
  relationshipDynamic: L10nTriple(
    'Saklı bir söz bir bağın içinde sessizce durabilir; şüphelenmek, birini gerçekten hırsız ilan etmekten farklı bir şeydir.',
    'A hidden word can sit quietly inside a bond, and suspicion stays a different thing from actually declaring someone a thief.',
    'Скрытое слово может тихо лежать внутри связи, и подозрение — это не то же самое, что объявить кого-то вором.',
  ),
  decisionDynamic: L10nTriple(
    'Hâlâ görünmeyeni sınamak, burada erkenden sabit bir hükme varmaktan daha iyi işler.',
    'Testing what is still unseen serves better here than settling on a fixed verdict too soon.',
    'Проверить ещё невидимое здесь полезнее, чем слишком рано остановиться на твёрдом приговоре.',
  ),
  actionDirection: L10nTriple(
    'Saklı olana bakın ve onu kanıt olarak tartın; bir hırsız adlandırmak isteyen korkudan ayrı tutarak.',
    'Look at what is hidden and weigh it as evidence, keeping it apart from the fear that wants to name a thief.',
    'Посмотрите на скрытое и взвесьте его как свидетельство, отдельно от страха, который хочет назвать вора.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Görülen iz, yargı kurmadan saklananı netleştirir.',
      'A seen trace clarifies what is hidden without assembling a verdict.',
      'Увиденный след проясняет скрытое, не собирая приговор.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.withdrawal,
      NarrativeKeywordIds.discernment,
      NarrativeKeywordIds.ending,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Saklama güvensizlik ve yalnız plana çarpıtılabilir veya yalnızca içte tutulan bir yalana çekilebilir.',
      'Hiding may distort into mistrust and a lone plan, or turn privately into a lie kept only within.',
      'Укрытие может исказиться в недоверие и одинокий план или уйти внутрь в ложь, хранимую лишь внутри.',
    ),
    transforms: [
      ReversedTransformKind.distortion,
      ReversedTransformKind.privateInternal,
    ],
    keywordIds: [
      NarrativeKeywordIds.fear,
      NarrativeKeywordIds.doubt,
      NarrativeKeywordIds.isolation,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.inquiry,
    NarrativeSymbolTags.shadow,
    NarrativeSymbolTags.restraint,
  ],
  profileRevision: 1,
);
