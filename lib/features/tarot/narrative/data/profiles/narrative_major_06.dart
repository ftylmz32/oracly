/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor06 = NarrativeCardProfile(
  canonicalCardId: 'major_06',
  coreMeaning: L10nTriple(
    'Yakınlık, değer uyumu ve kişinin kendini bir seçim içinde bütünüyle ortaya koymasını anlatır.',
    'Intimacy, aligned values, and bringing the whole self into a choice.',
    'Карта говорит о близости, согласованности ценностей и целостном присутствии человека в выборе.',
  ),
  light: L10nTriple(
    'Açık bir bağ, farklılıkları silmeden karşılıklı tanınma ve birlik yaratabilir.',
    'An open bond can create mutual recognition and union without erasing difference.',
    'Открытая связь может создать взаимное признание и единство, не стирая различий.',
  ),
  shadow: L10nTriple(
    'Çekim, temel uyumsuzlukları görmezden gelmeye veya seçimi ertelemeye yol açabilir.',
    'Attraction can lead to overlooking core differences or postponing a necessary choice.',
    'Притяжение может заставить не замечать важных различий или откладывать необходимый выбор.',
  ),
  tension: L10nTriple(
    'Birlik arzusu ile kişisel bütünlüğü koruma ihtiyacı aynı alanda buluşur.',
    'The desire for union meets the need to preserve personal integrity.',
    'Стремление к единству встречается с необходимостью сохранять личную целостность.',
  ),
  desire: L10nTriple(
    'Kişi, olduğu gibi görüldüğü ve gönüllü karşılık bulduğu bir yakınlık isteyebilir.',
    'Closeness where one is seen fully and freely reciprocated may be wanted.',
    'Может хотеться близости, в которой человека видят целиком и отвечают ему свободно.',
  ),
  fear: L10nTriple(
    'Yanlış seçim yapmak, reddedilmek veya bağ içinde kendini kaybetmek korkutabilir.',
    'Choosing wrongly, facing rejection, or losing oneself in connection may feel frightening.',
    'Могут пугать неверный выбор, отвержение или потеря себя в отношениях.',
  ),
  relationshipDynamic: L10nTriple(
    'Karşılıklılığı ve dürüst seçimi öne çıkarır; yakınlığın otomatik varsayılmamasını ister.',
    'It centers reciprocity and honest choice, asking that intimacy never be assumed.',
    'Карта ставит в центр взаимность и честный выбор, не позволяя считать близость само собой разумеющейся.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, yalnız çekime değil davranışlarla doğrulanan ortak değerlere dayanmalıdır.',
    'The decision should rest not only on attraction but on shared values confirmed by action.',
    'Решение стоит основывать не только на притяжении, но и на общих ценностях, подтвержденных поступками.',
  ),
  actionDirection: L10nTriple(
    'Sizin için vazgeçilmez olanı adlandırın ve seçiminizin onunla uyumunu gözleyin.',
    'Name what is nonnegotiable for you and observe whether your choice aligns with it.',
    'Назовите то, что для вас принципиально, и проверьте, согласуется ли с этим ваш выбор.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Gönüllü ve açık bir birliktelik, seçim ile değerleri aynı çizgide buluşturur.',
      'A willing, transparent union brings choice and values onto the same line.',
      'Добровольный и открытый союз приводит выбор и ценности к согласию.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['choice', 'union', 'values'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Uyum bozulabilir, seçim ertelenebilir veya bağ kişinin iç bütünlüğünden uzaklaşabilir.',
      'Alignment may fracture, choice may be delayed, or connection may drift from inner integrity.',
      'Согласие может нарушиться, выбор отложиться, а связь — отдалиться от внутренней целостности.',
    ),
    transforms: [
      ReversedTransformKind.delay,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: ['discord', 'indecision', 'misalignment'],
  ),
  symbolTags: [
    NarrativeSymbolTags.choice,
    NarrativeSymbolTags.union,
    NarrativeSymbolTags.values,
  ],
  profileRevision: 1,
);
