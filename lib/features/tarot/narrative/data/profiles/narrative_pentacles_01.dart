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
    'Rushing for results or counting abundance that is not yet there can appear when The seed goes too far.',
    'Семя может стать спешкой к результату или подсчётом ещё несуществующего изобилия.',
  ),
  tension: L10nTriple(
    'Başlama isteği ile hemen olgun görmek ihtiyacı aynı anda durur.',
    'The wish to begin sits beside the need to see ripeness too soon.',
    'Желание начать соседствует с нуждой видеть зрелость слишком рано.',
  ),
  desire: L10nTriple(
    'Kişi, elde uyanan ilk maddi imkânı bozmadan tutmak isteyebilir.',
    'Holding a first material possibility carefully, without breaking it, may matter.',
    'Может хотеться удержать первую вещественную возможность, не ломая её.',
  ),
  fear: L10nTriple(
    'Başlangıcın boşa gitmesi veya hiç filizlenmemesi kaygı yaratabilir.',
    'The beginning coming to nothing, or never sprouting, may cause unease.',
    'Тревогу может вызывать напрасное начало или то, что оно вовсе не взойдёт.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi ortak bir başlangıcı birlikte ekebilir; burada gelecekteki hasadı, tohumun kendisinden ayrı tutmakta fayda var.',
    'Two people can plant a shared beginning together, where the future harvest is worth setting aside from the seed itself.',
    'Двое могут вместе посадить общее начало, и здесь будущий урожай стоит отделять от самого семени.',
  ),
  decisionDynamic: L10nTriple(
    'Şu an gerçekten dikilebilecek olan, henüz büyümemiş bir sonucu saymaktan daha önemlidir.',
    'What can actually be planted right now matters more than counting an outcome that has not grown yet.',
    'То, что реально можно посадить прямо сейчас, важнее подсчёта ещё не выросшего результата.',
  ),
  actionDirection: L10nTriple(
    'Elinizde gerçekten tuttuğunuz tohumu adlandırın ve toprağa koyun; hasat sayımını sonraya bırakarak.',
    'Name the seed you are actually holding and put it in the ground, leaving the harvest count for later.',
    'Назовите семя, которое действительно держите в руке, и посадите его, оставив подсчёт урожая на потом.',
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
