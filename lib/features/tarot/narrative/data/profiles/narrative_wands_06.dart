/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeWands06 = NarrativeCardProfile(
  canonicalCardId: 'wands_06',
  coreMeaning: L10nTriple(
    'Bir eşiği geçmiş ateşi anlatır; henüz sonsuz zafer değildir.',
    'Fire that has crossed a threshold; not endless triumph.',
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
    'Having the crossed threshold seen simply and honestly may be wanted.',
    'Может хотеться, чтобы перейденный порог увидели просто и честно.',
  ),
  fear: L10nTriple(
    'Görünmez kalmak, alkışa bağımlı olmak veya geçişi abartmak kaygı yaratabilir.',
    'Staying unseen, needing applause, or inflating the crossing may cause unease.',
    'Тревогу может вызывать страх остаться незамеченным, зависеть от аплодисментов или раздуть переход.',
  ),
  relationshipDynamic: L10nTriple(
    'İnsanlar arasında bir yumuşama ya da yeni bir görünürlük ortaya çıkabilir; karşılıklı fark ediş, alkıştan daha değerlidir.',
    'A softening or a new visibility can surface between people, and mutual notice carries more than applause.',
    'Между людьми может проявиться смягчение или новая видимость; взаимное внимание значит больше, чем аплодисменты.',
  ),
  decisionDynamic: L10nTriple(
    'Geçilen bu eşiğin gerçek değeri, etrafında bir gösteri kurmaktan daha önemlidir.',
    'The real value of this crossed threshold matters more than staging a show around it.',
    'Подлинная ценность пройденного порога важнее, чем устраивать вокруг него представление.',
  ),
  actionDirection: L10nTriple(
    'Geçtiğinizi fark edin, bir nefes alın ve anın bir tahta dönüşmeden sade kalmasına izin verin.',
    'Notice that you crossed it, take a breath, and let the moment stay simple rather than becoming a throne.',
    'Заметьте, что вы перешли порог, сделайте вдох и позвольте моменту остаться простым, не превращая его в трон.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sakin bir fark edilme, eşiği geçmiş ateşi zafer abartısına düşmeden onurlandırır.',
      'Calm recognition honors fire that crossed a threshold without triumphal excess.',
      'Спокойное признание чтит огонь, перешедший порог, без победного излишества.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [NarrativeKeywordIds.threshold, NarrativeKeywordIds.inquiry],
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
    keywordIds: [
      NarrativeKeywordIds.boast,
      NarrativeKeywordIds.bondage,
      NarrativeKeywordIds.display,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.recognition,
    NarrativeSymbolTags.threshold,
    NarrativeSymbolTags.hope,
  ],
  profileRevision: 1,
);
