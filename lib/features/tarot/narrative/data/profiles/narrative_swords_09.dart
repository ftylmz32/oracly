/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords09 = NarrativeCardProfile(
  canonicalCardId: 'swords_09',
  coreMeaning: L10nTriple(
    'Gece çoğalan düşünceleri anlatır; gündüz kadar gerçek olmayabilirler, tanı değildir.',
    'It speaks of thoughts that multiply at night; they may be less real by day — not a diagnosis.',
    'Говорит о мыслях, что множатся ночью; днём они могут быть менее реальны — не диагноз.',
  ),
  light: L10nTriple(
    'Düşünceleri saymak, hepsine inanmadan zihin yükünü ayırmaya alan açabilir.',
    'Counting thoughts can make room to separate mind-load without believing them all.',
    'Считать мысли может дать место отделить ношу ума, не веря всем.',
  ),
  shadow: L10nTriple(
    'Gece düşüncesi felaket hayaline, uykusuzluk kimliğine veya suç yüküne kayabilir.',
    'Night thought may slide into catastrophe-dream, insomnia-identity, or guilt-load.',
    'Ночная мысль может стать мечтой-катастрофой, личностью бессонницы или грузом вины.',
  ),
  tension: L10nTriple(
    'Kaygıyı ciddiye alma ile onu kehanet saymama ihtiyacı birlikte durur.',
    'Taking worry seriously coexists with the need not to treat it as prophecy.',
    'Серьёзное отношение к тревоге соседствует с нуждой не считать её пророчеством.',
  ),
  desire: L10nTriple(
    'Kişi, gece zihninin gürültüsünden sakin bir sabah istemek isteyebilir.',
    'There may be a wish for a quiet morning after the night-mind\'s noise.',
    'Может хотеться тихого утра после шума ночного ума.',
  ),
  fear: L10nTriple(
    'En kötü senaryonun gerçek olması veya düşüncenin hiç dinmemesi kaygı yaratabilir.',
    'The worst scenario proving true, or thought never quieting, may cause unease.',
    'Тревогу может вызывать сбытие худшего сценария или мысль, что никогда не утихает.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda kaygı konuşmaları artabilir; korkuyu kanıttan ve kehanetten ayırmayı ister.',
    'Anxious talk may increase in a bond; it asks to separate fear from evidence and prophecy.',
    'В связи могут усилиться тревожные разговоры; карта просит отделить страх от свидетельства и пророчества.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, kın dinlenmesinden ayrı, gece büyüyen varsayımları gündüz yoklar.',
    'The choice tests night-grown assumptions by day, apart from sheath-rest.',
    'Выбор дневной проверкой испытывает ночные допущения, отдельно от отдыха в ножнах.',
  ),
  actionDirection: L10nTriple(
    'Düşünceyi sayın; hepsine inanmayın, korkuyu kanıttan ayırın.',
    'Count the thoughts; do not believe them all — separate fear from evidence.',
    'Сочтите мысли; не верьте всем — отделите страх от свидетельства.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sayılan düşünce, gece yükünü kehanet sanmadan tutar.',
      'Counted thought holds night-load without mistaking it for prophecy.',
      'Сочтённая мысль держит ночную ношу, не принимая её за пророчество.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['nightThought', 'mindLoad', 'worry'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Gece düşüncesi felaket hayaline aşırı şişebilir veya uykusuzluk kimliği ve suç yüküne içe çekilebilir.',
      'Night thought may tip into excess catastrophe-dream, or internalize into insomnia-identity and private guilt-load.',
      'Ночная мысль может перейти в избыточную мечту-катастрофу или уйти внутрь в личность бессонницы и частный груз вины.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.internalization,
    ],
    keywordIds: ['catastropheDream', 'insomniaIdentity', 'guilt'],
  ),
  symbolTags: [
    NarrativeSymbolTags.shadow,
    NarrativeSymbolTags.silence,
    NarrativeSymbolTags.uncertainty,
  ],
  profileRevision: 1,
);
