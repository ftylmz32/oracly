/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor03 = NarrativeCardProfile(
  canonicalCardId: 'major_03',
  coreMeaning: L10nTriple(
    'Büyümeyi besleyen ilgiyi, duyusal canlılığı ve üretken bir alan kurmayı anlatır.',
    'Care that supports growth, sensory aliveness, and a fertile space for creation.',
    'Карта говорит о заботе, поддерживающей рост, чувственной живости и плодотворном пространстве созидания.',
  ),
  light: L10nTriple(
    'Şefkatli emek, bir fikir ya da bağ için güvenli gelişme koşulları yaratabilir.',
    'Caring effort can create safe conditions for an idea or relationship to develop.',
    'Заботливый труд может создать надежные условия для развития идеи или отношений.',
  ),
  shadow: L10nTriple(
    'Beslemek, sınırlar kaybolduğunda aşırı korumaya veya tükenmeye dönebilir.',
    'Nurturing can become overprotection or depletion when boundaries disappear.',
    'Забота может стать чрезмерной опекой или истощением, если исчезают границы.',
  ),
  tension: L10nTriple(
    'Vermekten gelen doyum ile kendi kaynaklarını koruma gereği birlikte durur.',
    'The satisfaction of giving sits beside the need to preserve one\'s own resources.',
    'Удовлетворение от отдачи соседствует с необходимостью беречь собственные силы.',
  ),
  desire: L10nTriple(
    'Kişi, emeğinin kök saldığı, sıcak ve karşılık veren bir ortam arayabilir.',
    'A need for a warm, responsive setting where effort can take root can become visible.',
    'Может возникнуть стремление к теплой, отзывчивой среде, где труд способен укорениться.',
  ),
  fear: L10nTriple(
    'Değer verdiklerinin gelişmemesi veya bakım verirken kendini unutmak kaygı yaratabilir.',
    'There may be concern that what matters will not grow, or that care will erase the self.',
    'Может тревожить, что важное не вырастет или забота заставит забыть о себе.',
  ),
  relationshipDynamic: L10nTriple(
    'Yakınlığa sıcaklık ve kabul getirir; bakımın tek yönlü kalmamasını gözetir.',
    'It brings warmth and acceptance to intimacy while watching that care is not one-sided.',
    'Карта приносит в близость тепло и принятие, напоминая о взаимности заботы.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, yalnız verime değil uzun vadede neyin gerçekten gelişebileceğine bakar.',
    'The choice considers not only output but what can genuinely flourish over time.',
    'Выбор учитывает не только результат, но и то, что действительно сможет развиваться со временем.',
  ),
  actionDirection: L10nTriple(
    'Beslemek istediğiniz şeyi seçin, düzenli ilgi verin ve kendi sınırlarınızı da koruyun.',
    'Choose what you wish to nourish, offer steady care, and protect your boundaries too.',
    'Выберите, что хотите питать, уделяйте этому постоянное внимание и сохраняйте свои границы.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Cömert ve köklü bir ilgi, yaşamı zorlamadan çoğaltan bir üretkenlik yaratır.',
      'Generous, grounded care creates productivity that expands life without forcing it.',
      'Щедрая и укорененная забота создает плодотворность, расширяющую жизнь без давления.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['nurture', 'abundance', 'creation'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bakım enerjisi tükenebilir, aşırılaşabilir ya da kişinin kendisine ulaşmayabilir.',
      'Nurturing energy may become depleted, excessive, or unavailable to the self.',
      'Энергия заботы может истощиться, стать чрезмерной или перестать доходить до самого человека.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.deficiency,
    ],
    keywordIds: ['depletion', 'overcare', 'neglect'],
  ),
  symbolTags: [
    NarrativeSymbolTags.nurture,
    NarrativeSymbolTags.abundance,
    NarrativeSymbolTags.creation,
  ],
  profileRevision: 1,
);
