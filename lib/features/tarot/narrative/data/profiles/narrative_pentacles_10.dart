/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles10 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_10',
  coreMeaning: L10nTriple(
    'Zaman içinde köklü ortak yapıyı anlatır; miras vaadi değil, süren bir soydur.',
    'Rooted shared structure across time is not a promise of inheritance; it is lasting lineage.',
    'Говорит об укоренённой общей структуре во времени; не об обещании наследства, а о длящейся линии.',
  ),
  light: L10nTriple(
    'Paylaşılan düzen, tek kişinin yeterliğini aşan bir süreklilik taşıyabilir.',
    'Shared order can carry a continuity larger than one person\'s sufficiency.',
    'Общий порядок может нести непрерывность шире личной достаточности.',
  ),
  shadow: L10nTriple(
    'Soy, baskıya, zorunlu role veya kökleri taşlaştırmaya kayabilir.',
    'The risk is pressure, a forced role, or turning roots into stone when Lineage is pushed too far.',
    'Линия может стать давлением, навязанной ролью или окаменением корней.',
  ),
  tension: L10nTriple(
    'Ait olma isteği ile kendi yolunu boğmama ihtiyacı çekişir.',
    'The wish to belong contends with the need not to smother one\'s own path.',
    'Желание принадлежать спорит с нуждой не задушить собственный путь.',
  ),
  desire: L10nTriple(
    'Kişi, emeğin kendinden öteye tutunmasını isteyebilir.',
    'The longing is for labor to hold beyond the self.',
    'Может хотеться, чтобы труд держался дальше себя.',
  ),
  fear: L10nTriple(
    'Kopmak, unutulmak veya yapıya hapsolmak kaygı yaratabilir.',
    'Breaking off, being forgotten, or being trapped in the structure may cause unease.',
    'Тревогу может вызывать отрыв, забвение или пленение структурой.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda ortak süreklilik belirebilir; alışverişi köklü yapıdan ayırmayı ister.',
    'Shared continuity may appear in a bond; it asks to separate exchange from rooted structure.',
    'В связи может явиться общая непрерывность; карта просит отделить обмен от укоренённой структуры.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, kişisel yeterlikten ayrı, neyin birlikte süreceğini netleştirir.',
    'The choice clarifies what will last together, apart from personal sufficiency alone.',
    'Выбор проясняет, что продлится вместе, отдельно от одной лишь личной достаточности.',
  ),
  actionDirection: L10nTriple(
    'Hangi ortak yapının sürdüğünü görün; miras saymayın, kökleri adlandırın.',
    'See which shared structure endures; do not count inheritance — name the roots.',
    'Увидьте, какая общая структура длится; не считайте наследство — назовите корни.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Köklü ortak yapı, kişisel yeterliği ve anlık alışverişi aşar.',
      'Rooted shared structure outlasts personal sufficiency and momentary exchange.',
      'Укоренённая общая структура переживает личную достаточность и мгновенный обмен.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['lastingLineage', 'sharedStructure', 'roots'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Soy baskı ve zorunlu rolde şişebilir veya canlı ifadeyi kökler taşlaşana dek bloke edebilir.',
      'Lineage may swell into excess pressure and a forced role, or block living expression until roots harden into stone.',
      'Линия может раздуться в избыточное давление и навязанную роль или блокировать живое выражение, пока корни не окаменеют.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: ['forcedRole', 'petrifiedRoots', 'lineagePressure'],
  ),
  symbolTags: [
    NarrativeSymbolTags.belonging,
    NarrativeSymbolTags.structure,
    NarrativeSymbolTags.tradition,
    NarrativeSymbolTags.completion,
  ],
  profileRevision: 1,
);
