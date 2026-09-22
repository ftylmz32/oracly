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
    'It speaks of a closed hand at the threshold; not locking everything, but seeking safety by holding.',
    'Говорит о закрытой руке на пороге; не о запирании всего, а о поиске опоры через удержание.',
  ),
  light: L10nTriple(
    'Ölçülü koruma, değerli olanı savurup dağıtmamayı sağlayabilir.',
    'Measured protection can keep what matters from being scattered away.',
    'Сдержанная защита может уберечь важное от разбрасывания.',
  ),
  shadow: L10nTriple(
    'Tutma, kilitlenmeye, paylaşmayı reddetmeye veya korkuyla sıkmaya kayabilir.',
    'Holding may slide into locking, refusing to share, or gripping from fear.',
    'Удержание может стать запиранием, отказом делиться или сжатием от страха.',
  ),
  tension: L10nTriple(
    'Güvence isteği ile açık kalma ihtiyacı aynı anda durur.',
    'The wish for security sits beside the need to stay open.',
    'Желание опоры соседствует с нуждой оставаться открытым.',
  ),
  desire: L10nTriple(
    'Kişi, elindekini kaybetmeden saklamak isteyebilir.',
    'There may be a wish to keep what is in hand without losing it.',
    'Может хотеться сохранить то, что в руке, не теряя его.',
  ),
  fear: L10nTriple(
    'Kaybetmek, açılmak veya savunmasız kalmak kaygı yaratabilir.',
    'Losing, opening, or being left unprotected may cause unease.',
    'Тревогу может вызывать потеря, открытие или остаться без защиты.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda kaynak sınırı belirebilir; korumayı kilitlemekten ayırmayı ister.',
    'A resource boundary may appear in a bond; it asks to separate protecting from locking.',
    'В связи может явиться граница ресурса; карта просит отделить защиту от запирания.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, her şeyi sıkmak yerine neyin gerçekten korunacağını netleştirir.',
    'The choice clarifies what truly needs protecting rather than gripping everything.',
    'Выбор проясняет, что действительно нужно беречь, а не сжимать всё.',
  ),
  actionDirection: L10nTriple(
    'Neyi koruduğunuzu adlandırın; koruyun, kapıyı tamamen dondurmayın.',
    'Name what you are protecting; protect it, do not freeze the door shut.',
    'Назовите, что вы бережёте; берегите, но не замораживайте дверь наглухо.',
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
      'Tutma kilitlenmeye, reddetmeye veya korkuyla sıkmaya kayabilir.',
      'Holding may slide into locking, refusal, or gripping from fear.',
      'Удержание может стать запиранием, отказом или сжатием от страха.',
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
