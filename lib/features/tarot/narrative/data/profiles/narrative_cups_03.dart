/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups03 = NarrativeCardProfile(
  canonicalCardId: 'cups_03',
  coreMeaning: L10nTriple(
    'Üç kadehin sofrasını anlatır; yalnızlığın karşıtıdır, evlilik kehaneti değildir.',
    'It speaks of a table of three cups; the opposite of solitude, not a marriage prophecy.',
    'Говорит о столе трёх чаш; противоположность одиночества, не пророчество брака.',
  ),
  light: L10nTriple(
    'Paylaşım, dostluk ve ortak neşe, sofra etrafında yumuşak bir bağ kurabilir.',
    'Sharing, friendship, and shared joy can weave a soft bond around the table.',
    'Обмен, дружба и общая радость могут сплести мягкую связь вокруг стола.',
  ),
  shadow: L10nTriple(
    'Sofrada yüzeysellik, dışlanma hissi veya gürültülü boşluk belirebilir.',
    'Surface cheer, a sense of exclusion, or noisy emptiness may appear at the table.',
    'За столом могут возникнуть поверхностность, чувство исключённости или шумная пустота.',
  ),
  tension: L10nTriple(
    'Birlikte olma arzusu ile her kadehi boşaltmama ihtiyacı çekişir.',
    'The wish to be together contends with the need not to empty every cup.',
    'Желание быть вместе спорит с нуждой не опустошать каждую чашу.',
  ),
  desire: L10nTriple(
    'Kişi, samimi bir paylaşım sofrasında yer almak isteyebilir.',
    'There may be a wish to take a seat at a table of sincere sharing.',
    'Может хотеться занять место за столом искреннего обмена.',
  ),
  fear: L10nTriple(
    'Dışarıda kalmak, yüzeyde kalmak veya neşenin sahte görünmesi kaygı yaratabilir.',
    'Being left out, staying on the surface, or joy feeling staged may cause unease.',
    'Тревогу может вызывать исключённость, жизнь на поверхности или ощущение показной радости.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda paylaşım alanı açılabilir; her duyguyu tüketmeden sofrada oturmayı ister.',
    'A sharing field may open in a bond; it asks to sit at the table without consuming every feeling.',
    'В связи может открыться поле обмена; карта просит сидеть за столом, не исчерпывая каждое чувство.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, yalnız zafer yerine ortak sofranın gerçekten taşıyıp taşımadığını yoklar.',
    'The choice tests whether a shared table truly holds, rather than seeking lone triumph.',
    'Выбор проверяет, держит ли общий стол по-настоящему, а не ищет одиночного триумфа.',
  ),
  actionDirection: L10nTriple(
    'Sofraya oturun, paylaşımı fark edin; her kadehi boşaltmayın.',
    'Sit at the table, notice the sharing; do not empty every cup.',
    'Сядьте за стол, заметьте обмен; не опустошайте каждую чашу.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Samimi bir paylaşım, üç kadehi gürültüsüz bir sofrada buluşturur.',
      'Sincere sharing gathers three cups at a table without noise.',
      'Искренний обмен собирает три чаши за столом без шума.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['sharedTable', 'friendship', 'gathering'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sofrada yüzeysellik, dışlanma veya gürültülü boşluk baskınlaşabilir.',
      'Surface cheer, exclusion, or noisy emptiness may dominate the table.',
      'За столом могут возобладать поверхностность, исключённость или шумная пустота.',
    ),
    transforms: [
      ReversedTransformKind.deficiency,
      ReversedTransformKind.distortion,
    ],
    keywordIds: ['surface', 'exclusion', 'noise'],
  ),
  symbolTags: [
    NarrativeSymbolTags.belonging,
    NarrativeSymbolTags.joy,
    NarrativeSymbolTags.nurture,
  ],
  profileRevision: 1,
);
