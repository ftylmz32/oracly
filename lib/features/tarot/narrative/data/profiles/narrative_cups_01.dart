/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups01 = NarrativeCardProfile(
  canonicalCardId: 'cups_01',
  coreMeaning: L10nTriple(
    'Henüz hikâyeye dönüşmemiş ilk suyu anlatır; duygu vardır, anlatı henüz yoktur.',
    'At the center: first water not yet a story; feeling is present, narrative is not.',
    'Говорит о первой воде, ещё не ставшей историей; чувство есть, рассказа ещё нет.',
  ),
  light: L10nTriple(
    'Kadeh elde tutulduğunda, duygunun taşmadan canlı kalması mümkün olur.',
    'When the cup is held, feeling can stay alive without spilling everywhere.',
    'Когда чаша удержана, чувство может оставаться живым, не разливаясь повсюду.',
  ),
  shadow: L10nTriple(
    'İlk his, herkese dökülmeye, kapanmaya veya hissetmekten kaçınmaya kayabilir.',
    'Without balance, first feeling can become pouring for everyone, closing off, or fleeing feeling itself.',
    'Первое чувство может стать разливанием всем, закрытием или бегством от самого чувства.',
  ),
  tension: L10nTriple(
    'Duyguyu taşıma isteği ile onu hemen paylaşmama ihtiyacı aynı anda durur.',
    'The wish to carry feeling sits beside the need not to share it at once.',
    'Желание нести чувство соседствует с нуждой не делиться им сразу.',
  ),
  desire: L10nTriple(
    'Kişi, uyanan yumuşaklığı bozmadan tutmak ve tanımak isteyebilir.',
    'The longing is to hold and recognize soft awakening without forcing it.',
    'Может хотеться удержать и узнать мягкое пробуждение, не форсируя его.',
  ),
  fear: L10nTriple(
    'Hissi kaybetmek, taşmak veya duygunun fazla büyümesi kaygı yaratabilir.',
    'Losing the feeling, overflowing, or emotion growing too large may cause unease.',
    'Тревогу может вызывать утрата чувства, переполнение или чрезмерный рост эмоции.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda taze bir açıklık belirebilir; sunuyu dayatmadan yoklamayı ister.',
    'Fresh openness may appear in a bond; it asks to test the offer without imposing it.',
    'В связи может возникнуть свежая открытость; карта просит проверять предложение, не навязывая его.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, büyük vaat yerine duyguyu henüz biçimlenmeden fark etmeye yaslanır.',
    'The choice leans on noticing feeling before it is shaped, not on a grand promise.',
    'Выбор опирается на замечание чувства до его формы, а не на громкое обещание.',
  ),
  actionDirection: L10nTriple(
    'Kadehi fark edin ve tutun; herkese dökmeyin, kapatmayın.',
    'Notice the cup and hold it; do not pour for everyone, and do not seal it shut.',
    'Заметьте чашу и удержите её; не разливайте всем и не закрывайте наглухо.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ölçülü bir tutuş, ilk suyu canlı ve yönetilebilir kılar.',
      'A measured hold keeps first water alive and workable.',
      'Сдержанное удержание делает первую воду живой и управляемой.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['firstWater', 'heldCup', 'softOpening'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'İlk his taşmaya, kapanmaya veya hissetmekten kaçınmaya kayabilir.',
      'First feeling may slide into overflow, closing, or avoidance of feeling.',
      'Первое чувство может стать переполнением, закрытием или избеганием чувства.',
    ),
    transforms: [ReversedTransformKind.excess, ReversedTransformKind.avoidance],
    keywordIds: ['overflow', 'closing', 'feelingFlee'],
  ),
  symbolTags: [
    NarrativeSymbolTags.desire,
    NarrativeSymbolTags.nurture,
    NarrativeSymbolTags.attachment,
  ],
  profileRevision: 1,
);
