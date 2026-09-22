/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups04 = NarrativeCardProfile(
  canonicalCardId: 'cups_04',
  coreMeaning: L10nTriple(
    'Önde duran kadehe bakılmayan durgunluğu anlatır; yeterlilik ve içe dönüş alanıdır.',
    'Stillness when the cup in front is not looked at; a field of enough and inward turn.',
    'Говорит о покое, когда чаша перед глазами не замечается; поле достаточности и поворота внутрь.',
  ),
  light: L10nTriple(
    'Durma, yeni aramadan önce önündeki kadehi görmeye alan açabilir.',
    'Stillness can make room to see the cup in front before wanting a new one.',
    'Покой может дать место увидеть чашу перед собой, прежде чем желать новую.',
  ),
  shadow: L10nTriple(
    'Durgunluk, nankörlüğe, kaçışa veya duygu körlüğüne kayabilir.',
    'Stillness turns brittle when it becomes ingratitude, escape, or feeling-blindness.',
    'Покой может стать неблагодарностью, бегством или слепотой к чувствам.',
  ),
  tension: L10nTriple(
    'Yeteri fark etme ihtiyacı ile yeni su arama isteği birlikte durur.',
    'The need to notice enough coexists with the wish to seek new water.',
    'Нужда заметить достаточное соседствует с желанием искать новую воду.',
  ),
  desire: L10nTriple(
    'Kişi, yorgunluğu yokluk sanmadan içerde bir durak bulmak isteyebilir.',
    'A longing to find an inward pause without mistaking weariness for absence may surface.',
    'Может хотеться найти внутреннюю паузу, не принимая усталость за отсутствие.',
  ),
  fear: L10nTriple(
    'Önündeki fırsatı kaçırmak veya hissizleşmek kaygı yaratabilir.',
    'Missing what is already offered, or going numb, may cause unease.',
    'Тревогу может вызывать упущенное уже предложенное или онемение.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasındaki mesafe olduğundan keskin hissedilebilir; bir mola, gerçek bir yokluktan farklı kalır.',
    'Distance between two people can feel sharper than it is, and a pause stays different from real absence.',
    'Дистанция между двумя людьми может ощущаться острее, чем есть; пауза остаётся не тем же самым, что подлинное отсутствие.',
  ),
  decisionDynamic: L10nTriple(
    'Zaten burada olan şey, daha fazlası aranmadan önce gerçekten görülmeyi hak eder.',
    'What is already here deserves to be truly seen before anything more is sought.',
    'То, что уже есть, заслуживает быть по-настоящему увиденным, прежде чем искать больше.',
  ),
  actionDirection: L10nTriple(
    'Önünüzdeki kadehe bakın ve yeterli olanı fark edin; yorgunluğu yoklukla karıştırmadan.',
    'Look at the cup already in front of you and notice what is enough, without mistaking tiredness for absence.',
    'Посмотрите на чашу перед собой и заметьте достаточное, не путая усталость с отсутствием.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'İçe dönük bir duruş, öndeki kadehi acele aramadan görmeyi güçlendirir.',
      'An inward stance strengthens seeing the cup in front without rushing toward the new.',
      'Обращённая внутрь поза усиливает видение чаши перед собой без спешки к новому.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['stillCup', 'enough', 'inwardPause'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Durgunluk duygudan kaçınmaya kayabilir veya sunulanı artık görmeyen bir eksikliğe incelenebilir.',
      'Stillness may avoid feeling through escape, or thin into a deficiency that no longer notices what is offered.',
      'Покой может избегать чувства через бегство или истончиться до дефицита, который уже не замечает предложенного.',
    ),
    transforms: [
      ReversedTransformKind.avoidance,
      ReversedTransformKind.deficiency,
    ],
    keywordIds: ['ingratitude', 'escape', 'feelingBlind'],
  ),
  symbolTags: [
    NarrativeSymbolTags.pause,
    NarrativeSymbolTags.solitude,
    NarrativeSymbolTags.perspective,
  ],
  profileRevision: 1,
);
