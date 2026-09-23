/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativePentacles03 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_03',
  coreMeaning: L10nTriple(
    'Ortak atölyeyi anlatır; alkış değil, birbirine dokunan işin örülmesidir.',
    'The center is a shared workshop — work woven together, rather than applause.',
    'Говорит об общей мастерской; не об аплодисментах, а о сплетённой вместе работе.',
  ),
  light: L10nTriple(
    'Ellerin birlikte çalışması, tek başına bitmeyen bir parçayı tamamlayabilir.',
    'Hands working together can complete a piece that alone would stay unfinished.',
    'Руки, работающие вместе, могут завершить то, что в одиночку осталось бы незавершённым.',
  ),
  shadow: L10nTriple(
    'İşbirliği, görünürlük yarışına veya katkıyı inkâr etmeye kayabilir.',
    'Collaboration can tip into a contest for visibility or denying a contribution.',
    'Сотрудничество может стать соревнованием за видимость или отрицанием вклада.',
  ),
  tension: L10nTriple(
    'Birlikte üretme isteği ile kendi payını kaybetme kaygısı çekişir.',
    'The wish to make together contends with unease about losing one\'s own share.',
    'Желание творить вместе спорит с тревогой потерять свою долю.',
  ),
  desire: L10nTriple(
    'Kişi, emeğin başkalarıyla anlamlı bir şekilde birleşmesini isteyebilir.',
    'Labor joining meaningfully with others may be what is hoped for.',
    'Может хотеться, чтобы труд осмысленно соединился с другими.',
  ),
  fear: L10nTriple(
    'Görülmemek veya emeğin boşa sayılması kaygı yaratabilir.',
    'Going unseen, or labor being counted as nothing, may cause unease.',
    'Тревогу может вызывать остаться незамеченным или то, что труд сочтут ничем.',
  ),
  relationshipDynamic: L10nTriple(
    'İnsanlar arasında ortak bir üretim alanı açılabilir; çektiği alkış, onu kuran emekle aynı şey değildir.',
    'A shared making-space can open between people, and the applause it draws is not the same thing as the labor that built it.',
    'Между людьми может открыться общее пространство созидания, и вызванные аплодисменты — не то же самое, что построивший его труд.',
  ),
  decisionDynamic: L10nTriple(
    'Bu işin kiminle örüleceği, burada tek başına ustalık kadar önemlidir.',
    'Who this work gets woven with matters here as much as any solo mastery.',
    'С кем сплетётся эта работа, важно здесь не меньше, чем одинокое мастерство.',
  ),
  actionDirection: L10nTriple(
    'Bunu kiminle ördüğünüzü görün ve katkılarını açıkça adlandırın; alkış beklemek yerine.',
    'See who you are weaving this with and name their contribution plainly, rather than waiting around for applause.',
    'Увидьте, с кем вы это плетёте, и прямо назовите их вклад, вместо того чтобы ждать аплодисментов.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Örülen emek, ortak atölyeyi alkıştan ayrı tutar.',
      'Woven labor holds the shared workshop apart from applause.',
      'Сплетённый труд держит общую мастерскую отдельно от аплодисментов.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [NarrativeKeywordIds.craft, NarrativeKeywordIds.belonging],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'İşbirliği görünürlük yarışına veya katkıyı silmeye kayabilir.',
      'Collaboration may slide into visibility contests or erasing a contribution.',
      'Сотрудничество может стать гонкой за видимостью или стиранием вклада.',
    ),
    transforms: [
      ReversedTransformKind.distortion,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: [
      NarrativeKeywordIds.display,
      NarrativeKeywordIds.withdrawal,
      NarrativeKeywordIds.instability,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.craft,
    NarrativeSymbolTags.belonging,
    NarrativeSymbolTags.recognition,
  ],
  profileRevision: 1,
);
