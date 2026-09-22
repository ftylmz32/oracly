/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands06 = NarrativeCardProfile(
  canonicalCardId: 'wands_06',
  coreMeaning: L10nTriple(
    'Bir eşiği geçmiş ateşi anlatır; henüz sonsuz zafer değildir.',
    'The card holds fire that has crossed a threshold, not endless triumph.',
    'Говорит об огне, перешедшем порог; не о вечной победе.',
  ),
  light: L10nTriple(
    'Emeğin fark edilmesi, omuzları indiren sakin bir nefes ve görünürlük yaratabilir.',
    'Effort being noticed can create calm breath, dropped shoulders, and visibility.',
    'Замеченное усилие может дать спокойное дыхание, опущенные плечи и видимость.',
  ),
  shadow: L10nTriple(
    'Geçiş, övünç, sahne alkışı veya geçmişe takılmaya bağlanabilir.',
    'The crossing may bind itself to boast, staged applause, or getting stuck in the past.',
    'Переход может привязаться к похвальбе, сценическим аплодисментам или застреванию в прошлом.',
  ),
  tension: L10nTriple(
    'Tanınma ihtiyacı ile taht kurmadan geçidi onurlandırma arzusu çekişir.',
    'The need for notice contends with the wish to honor the passage without building a throne.',
    'Нужда в признании спорит с желанием почтить проход, не строя трон.',
  ),
  desire: L10nTriple(
    'Kişi, geçtiği eşiğin sade ve dürüst biçimde görülmesini isteyebilir.',
    'Part of this archetype longs for the crossed threshold to be seen simply and honestly.',
    'Может хотеться, чтобы перейденный порог увидели просто и честно.',
  ),
  fear: L10nTriple(
    'Görünmez kalmak, alkışa bağımlı olmak veya geçişi abartmak kaygı yaratabilir.',
    'Staying unseen, needing applause, or inflating the crossing may cause unease.',
    'Тревогу может вызывать страх остаться незамеченным, зависеть от аплодисментов или раздуть переход.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda yumuşama veya görünürlük belirebilir; alkış yerine karşılıklı fark etmeyi önerir.',
    'Softening or visibility may appear in a bond; it favors mutual notice over applause.',
    'В связи может явиться смягчение или видимость; карта предлагает взаимное замечание вместо аплодисментов.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, sahne kurmak yerine geçilen eşiğin gerçek değerini sadeleştirir.',
    'The choice clarifies the real value of the crossed threshold rather than staging a show.',
    'Выбор проясняет подлинную ценность перейденного порога, а не устраивает спектакль.',
  ),
  actionDirection: L10nTriple(
    'Geçtiğinizi fark edin, nefes alın; taht kurmayın.',
    'Notice that you crossed, take a breath; do not build a throne.',
    'Заметьте, что перешли, сделайте вдох; не стройте трон.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sakin bir fark edilme, eşiği geçmiş ateşi zafer abartısına düşmeden onurlandırır.',
      'Calm recognition honors fire that crossed a threshold without triumphal excess.',
      'Спокойное признание чтит огонь, перешедший порог, без победного излишества.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['crossing', 'notice', 'breath'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Geçiş övünce, sahneye veya geçmiş başarıya takılmaya dönüşebilir.',
      'The crossing may become boast, stage, or fixation on past success.',
      'Переход может стать похвальбой, сценой или застреванием в прошлом успехе.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.distortion,
    ],
    keywordIds: ['boast', 'stuckInPast', 'stage'],
  ),
  symbolTags: [
    NarrativeSymbolTags.recognition,
    NarrativeSymbolTags.threshold,
    NarrativeSymbolTags.hope,
  ],
  profileRevision: 1,
);
