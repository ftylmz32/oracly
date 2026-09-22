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
    'This archetype names stillness when the cup in front is not looked at; a field of enough and inward turn.',
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
    'Here the reach is to find an inward pause without mistaking weariness for absence.',
    'Может хотеться найти внутреннюю паузу, не принимая усталость за отсутствие.',
  ),
  fear: L10nTriple(
    'Önündeki fırsatı kaçırmak veya hissizleşmek kaygı yaratabilir.',
    'Missing what is already offered, or going numb, may cause unease.',
    'Тревогу может вызывать упущенное уже предложенное или онемение.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda mesafe keskinleşebilir; yokluk sanmadan duraklamayı ayırmayı ister.',
    'Distance may feel sharper in a bond; it asks to separate pause from assumed absence.',
    'В связи дистанция может ощущаться острее; карта просит отделить паузу от принятого за отсутствие.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, yeni aramadan önce eldekinin gerçekten görülüp görülmediğini yoklar.',
    'The choice tests whether what is already here has truly been seen before seeking more.',
    'Выбор проверяет, действительно ли увидено уже имеющееся, прежде чем искать новое.',
  ),
  actionDirection: L10nTriple(
    'Öndeki kadehe bakın, yeteri fark edin; yorgunluğu yokluk sanmayın.',
    'Look at the cup in front, notice enough; do not mistake weariness for absence.',
    'Смотрите на чашу перед собой, заметьте достаточное; не принимайте усталость за отсутствие.',
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
