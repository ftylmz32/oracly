/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles04 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_04',
  coreMeaning: L10nTriple(
    'Eşiği koruyan kapalı eli anlatır; kilitlemek değil, tutarak güvence aramaktır.',
    'A closed hand at the threshold; not locking everything, but seeking safety by holding.',
    'Говорит о закрытой руке на пороге; не о запирании всего, а о поиске опоры через удержание.',
  ),
  light: L10nTriple(
    'Ölçülü koruma, değerli olanı savurup dağıtmamayı sağlayabilir.',
    'Measured protection can keep what matters from being scattered away.',
    'Сдержанная защита может уберечь важное от разбрасывания.',
  ),
  shadow: L10nTriple(
    'Tutma, kilitlenmeye, paylaşmayı reddetmeye veya korkuyla sıkmaya kayabilir.',
    'Locking, refusing to share, or gripping from fear appears when Holding dominates.',
    'Удержание может стать запиранием, отказом делиться или сжатием от страха.',
  ),
  tension: L10nTriple(
    'Güvence isteği ile açık kalma ihtiyacı aynı anda durur.',
    'The wish for security sits beside the need to stay open.',
    'Желание опоры соседствует с нуждой оставаться открытым.',
  ),
  desire: L10nTriple(
    'Kişi, elindekini kaybetmeden saklamak isteyebilir.',
    'A longing to keep what is in hand without losing it may surface.',
    'Может хотеться сохранить то, что в руке, не теряя его.',
  ),
  fear: L10nTriple(
    'Kaybetmek, açılmak veya savunmasız kalmak kaygı yaratabilir.',
    'Losing, opening, or being left unprotected may cause unease.',
    'Тревогу может вызывать потеря, открытие или остаться без защиты.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasında kaynaklara dair bir sınır belirebilir; bir şeyi korumak, onu tamamen kilitlemekten farklı bir eylemdir.',
    'A boundary around resources can show up between two people, and protecting something is a different act from locking it away entirely.',
    'Между двумя людьми может появиться граница вокруг ресурсов, и защищать что-то — не то же самое, что полностью её запереть.',
  ),
  decisionDynamic: L10nTriple(
    'Gerçekten korunması gerekeni adlandırmak, korkuyla her şeyi birden kavramaktan daha önemlidir.',
    'Naming what genuinely needs protecting matters more than a fear-driven grip on everything at once.',
    'Назвать то, что действительно нуждается в защите, важнее, чем судорожно хвататься за всё сразу.',
  ),
  actionDirection: L10nTriple(
    'Neyi koruduğunuzu adlandırın ve o belirli şeyi koruyun; ama kapının yeniden açılabilmesine izin vererek.',
    'Name what you are protecting and guard that specific thing, while leaving the door able to open again.',
    'Назовите то, что вы защищаете, и берегите именно это, оставляя дверь способной снова открыться.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ölçülü tutuş, eşiği kilit olmadan korur.',
      'A measured hold protects the threshold without becoming a lock.',
      'Сдержанная хватка бережёт порог, не становясь замком.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['closedHand', 'thresholdGuard', 'holding'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Tutma kilitlenme ve korkuyla sıkmada şişebilir veya eli kapalı tutarak paylaşmayı kaçınabilir.',
      'Holding may swell into excess locking and fear-grip, or avoid sharing by keeping the hand closed.',
      'Удержание может раздуться в избыточное запирание и сжатие от страха или избегать обмена, держа руку закрытой.',
    ),
    transforms: [ReversedTransformKind.excess, ReversedTransformKind.avoidance],
    keywordIds: ['lockedGrip', 'refusal', 'fearHold'],
  ),
  symbolTags: [
    NarrativeSymbolTags.attachment,
    NarrativeSymbolTags.restraint,
    NarrativeSymbolTags.stability,
  ],
  profileRevision: 1,
);
