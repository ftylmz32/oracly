/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeMajor19 = NarrativeCardProfile(
  canonicalCardId: 'major_19',
  coreMeaning: L10nTriple(
    'Açıklık, canlılık ve kişinin kendini saklamadan yaşamla temas kurmasını temsil eder.',
    'It represents clarity, vitality, and meeting life without hiding the self.',
    'Карта означает ясность, жизненную силу и открытый контакт с жизнью без сокрытия себя.',
  ),
  light: L10nTriple(
    'Görünür gerçeklik, güveni ve paylaşılabilen sade bir sevinci güçlendirebilir.',
    'Visible truth can strengthen confidence and a simple joy that can be shared.',
    'Очевидная правда может укрепить уверенность и простую радость, которой можно делиться.',
  ),
  shadow: L10nTriple(
    'Parlaklık, zor duyguları gölgede bırakmaya veya sürekli neşeli görünme baskısına dönüşebilir.',
    'Brightness can overshadow difficult feelings or create pressure to appear continually cheerful.',
    'Яркость может затмить трудные чувства или создать давление постоянно выглядеть радостным.',
  ),
  tension: L10nTriple(
    'Kendini açıkça göstermek ile her deneyimin aydınlık olmadığını kabul etmek birlikte durur.',
    'Showing oneself openly coexists with accepting that not every experience is bright.',
    'Открытое проявление себя сочетается с признанием, что не каждый опыт бывает светлым.',
  ),
  desire: L10nTriple(
    'Kişi, anlaşılır, sıcak ve yaşam enerjisini rahatça ifade edebildiği bir alan isteyebilir.',
    'It can feel important to find a warm, clear space where life energy can be expressed freely.',
    'Может хотеться теплого и ясного пространства для свободного выражения жизненной энергии.',
  ),
  fear: L10nTriple(
    'Görünür olduğunda eleştirilmek veya sevincin kısa sürmesi endişe yaratabilir.',
    'Being criticized when visible or fearing that joy will be brief may cause concern.',
    'Может тревожить критика при открытом проявлении себя или недолговечность радости.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda açıklık ve sıcaklık yaratır; neşenin yanında dürüst kırılganlığa da yer verir.',
    'It creates warmth and transparency in a bond while allowing honest vulnerability beside joy.',
    'Карта создает тепло и прозрачность в связи, оставляя рядом с радостью место честной уязвимости.',
  ),
  decisionDynamic: L10nTriple(
    'Karmaşayı azaltan açık bilgi ve yaşamı gerçekten genişleten seçenek, burada temkinli bir varsayılandan daha ağır basar.',
    'Clear information and whichever option truly expands aliveness carry more weight here than a cautious default.',
    'Ясная информация и вариант, который действительно расширяет чувство жизни, здесь перевешивают осторожный вариант по умолчанию.',
  ),
  actionDirection: L10nTriple(
    'Açık olanı söyleyin, küçük başarıyı paylaşın ve enerjinizi gerçekten besleyene yöneltin.',
    'Say what is clear, share the modest success, and direct energy toward what truly nourishes it.',
    'Скажите о ясном, разделите небольшой успех и направьте силы к тому, что их действительно питает.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sade açıklık ve canlılık, kişinin kendisini güvenle ortaya koymasını destekler.',
      'Simple clarity and vitality support confident, unhidden self-expression.',
      'Простая ясность и жизненность поддерживают уверенное и открытое самовыражение.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.clarity,
      NarrativeKeywordIds.vitality,
      NarrativeKeywordIds.joy,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sevinç içerde kalabilir, açıklık gecikebilir veya iyimserlik gerçeği aşırı parlatabilir.',
      'Joy may remain private, clarity be delayed, or optimism brighten reality too much.',
      'Радость может остаться внутри, ясность — задержаться, а оптимизм — чрезмерно приукрасить реальность.',
    ),
    transforms: [
      ReversedTransformKind.internalization,
      ReversedTransformKind.excess,
    ],
    keywordIds: [
      NarrativeKeywordIds.withdrawal,
      NarrativeKeywordIds.delay,
      NarrativeKeywordIds.overflow,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.clarity,
    NarrativeSymbolTags.vitality,
    NarrativeSymbolTags.joy,
  ],
  profileRevision: 1,
);
