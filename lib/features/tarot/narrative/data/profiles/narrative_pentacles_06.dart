/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles06 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_06',
  coreMeaning: L10nTriple(
    'Verilen ve alınan maddeyi anlatır; merhamet gösterisi değil, tartılan paylaşımdır.',
    'It speaks of matter given and received; not a display of mercy, but weighed exchange.',
    'Говорит о веществе, данном и принятом; не о показе милости, а о взвешенном обмене.',
  ),
  light: L10nTriple(
    'Adil bir akış, yardımı borca çevirmeden iki tarafa da nefes verebilir.',
    'A fair flow can give both sides breath without turning help into debt.',
    'Справедливый поток может дать обеим сторонам дыхание, не превращая помощь в долг.',
  ),
  shadow: L10nTriple(
    'Paylaşım, üstünlük gösterisine, borç yüklemeye veya almak utancına kayabilir.',
    'Sharing may slide into a display of superiority, loading debt, or shame at receiving.',
    'Обмен может стать показом превосходства, навешиванием долга или стыдом принимать.',
  ),
  tension: L10nTriple(
    'Verme isteği ile dengeyi bozmama ihtiyacı çekişir.',
    'The wish to give contends with the need not to tip the balance.',
    'Желание давать спорит с нуждой не нарушить равновесие.',
  ),
  desire: L10nTriple(
    'Kişi, yardımın gerçekten işe yaramasını ve alınabilmesini isteyebilir.',
    'There may be a wish for help to truly land and be receivable.',
    'Может хотеться, чтобы помощь действительно дошла и была принимаемой.',
  ),
  fear: L10nTriple(
    'Kullanılmak, borçlu kalmak veya verme gücünü kaybetmek kaygı yaratabilir.',
    'Being used, staying indebted, or losing the capacity to give may cause unease.',
    'Тревогу может вызывать быть использованным, остаться в долгу или потерять способность давать.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda alışveriş belirebilir; yardımı borçtan ayırmayı ister.',
    'Exchange may appear in a bond; it asks to separate help from debt.',
    'В связи может явиться обмен; карта просит отделить помощь от долга.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, kim ne veriyor ve ne alıyor sorusunu merhamet tiyatrosundan ayırır.',
    'The choice separates who gives and receives from a theatre of mercy.',
    'Выбор отделяет вопрос, кто даёт и принимает, от театра милости.',
  ),
  actionDirection: L10nTriple(
    'Alışverişi adlandırın; verin veya alın, borca çevirmeyin.',
    'Name the exchange; give or receive — do not turn it into debt.',
    'Назовите обмен; дайте или примите — не превращайте это в долг.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Tartılan paylaşım, yardımı gösterişten ve borçtan ayrı tutar.',
      'Weighed sharing holds help apart from display and from debt.',
      'Взвешенный обмен держит помощь отдельно от показа и от долга.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['giveReceive', 'weighedScales', 'share'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Paylaşım üstünlük gösterisine çarpıtılabilir veya armağanı borç yüküne ve alma utancına aşırı çevirebilir.',
      'Sharing may distort into a superiority display, or excess may load the gift as debt and shame at receiving.',
      'Обмен может исказиться в показ превосходства, а избыток — превратить дар в долг и стыд принимать.',
    ),
    transforms: [
      ReversedTransformKind.distortion,
      ReversedTransformKind.excess,
    ],
    keywordIds: ['mercyDisplay', 'loadedDebt', 'shameReceive'],
  ),
  symbolTags: [
    NarrativeSymbolTags.balance,
    NarrativeSymbolTags.values,
    NarrativeSymbolTags.accountability,
  ],
  profileRevision: 1,
);
