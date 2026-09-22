/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles01 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_01',
  coreMeaning: L10nTriple(
    'İlk tohumu anlatır; henüz hasat değil, elde tutulan maddenin başlangıcıdır.',
    'The center is a first seed — matter held in the hand at its start, rather than yet a harvest.',
    'Говорит о первом семени; ещё не урожай, а начало вещества в руке.',
  ),
  light: L10nTriple(
    'Küçük bir başlangıç, saymadan dikmek için alan açabilir.',
    'A small beginning can make room to plant without counting the yield.',
    'Малое начало может дать место посадить, не считая урожай.',
  ),
  shadow: L10nTriple(
    'Tohum, acele sonuç beklentisine veya henüz olmayan bolluğu saymaya kayabilir.',
    'Pushed too far, the seed yields rushing for results or counting abundance that is not yet there.',
    'Семя может стать спешкой к результату или подсчётом ещё несуществующего изобилия.',
  ),
  tension: L10nTriple(
    'Başlama isteği ile hemen olgun görmek ihtiyacı aynı anda durur.',
    'The wish to begin sits beside the need to see ripeness too soon.',
    'Желание начать соседствует с нуждой видеть зрелость слишком рано.',
  ),
  desire: L10nTriple(
    'Kişi, elde uyanan ilk maddi imkânı bozmadan tutmak isteyebilir.',
    'A need to hold a first material possibility without breaking it can become visible.',
    'Может хотеться удержать первую вещественную возможность, не ломая её.',
  ),
  fear: L10nTriple(
    'Başlangıcın boşa gitmesi veya hiç filizlenmemesi kaygı yaratabilir.',
    'The beginning coming to nothing, or never sprouting, may cause unease.',
    'Тревогу может вызывать напрасное начало или то, что оно вовсе не взойдёт.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda ortak bir başlangıç gerekebilir; hasadı tohumdan ayırmayı ister.',
    'A shared beginning may be needed in a bond; it asks to separate harvest from seed.',
    'В связи может быть нужно общее начало; карта просит отделить урожай от семени.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, sonucu saymak yerine neyin dikilebileceğini netleştirir.',
    'The choice clarifies what can be planted rather than counting the outcome.',
    'Выбор проясняет, что можно посадить, а не подсчитывает исход.',
  ),
  actionDirection: L10nTriple(
    'Elinizdeki tohumu adlandırın; dikin, hasadı henüz saymayın.',
    'Name the seed in hand; plant it, do not count the harvest yet.',
    'Назовите семя в руке; посадите его, пока не считайте урожай.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ölçülü bir el, ilk tohumu canlı ve yönetilebilir tutar.',
      'A measured hand keeps the first seed alive and workable.',
      'Сдержанная рука удерживает первое семя живым и управляемым.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['firstSeed', 'matterInHand', 'plant'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Tohum acele sonuca, boş sayıma veya başlamamaya kayabilir.',
      'The seed may slide into rushed results, empty counting, or not beginning.',
      'Семя может стать спешным результатом, пустым подсчётом или неначатием.',
    ),
    transforms: [ReversedTransformKind.excess, ReversedTransformKind.avoidance],
    keywordIds: ['rushedYield', 'emptyCount', 'unplanted'],
  ),
  symbolTags: [
    NarrativeSymbolTags.creation,
    NarrativeSymbolTags.abundance,
    NarrativeSymbolTags.threshold,
  ],
  profileRevision: 1,
);
