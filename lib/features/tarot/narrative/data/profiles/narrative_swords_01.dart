/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords01 = NarrativeCardProfile(
  canonicalCardId: 'swords_01',
  coreMeaning: L10nTriple(
    'İlk keskinliği anlatır; henüz savaş değil, duru bir fikrin kenarıdır.',
    'A first edge; not yet a war, but the rim of a clear idea.',
    'Говорит о первом острие; ещё не война, а край ясной идеи.',
  ),
  light: L10nTriple(
    'Net bir cümle, yaralamadan düşünceyi ayırabilir.',
    'A clear sentence can separate thought without wounding.',
    'Ясная фраза может отделить мысль, не раня.',
  ),
  shadow: L10nTriple(
    'Keskinlik sert söze, dağınık zihne veya kesmek için kesmeye kayabilir.',
    'Edge may slide into a harsh word, a scattered mind, or cutting for its own sake.',
    'Остриё может стать жёстким словом, рассеянным умом или резаньем ради резанья.',
  ),
  tension: L10nTriple(
    'Dürüst olma isteği ile keserek konuşmama ihtiyacı aynı anda durur.',
    'The wish to be honest sits beside the need not to speak by cutting.',
    'Желание быть честным соседствует с нуждой не говорить, раня.',
  ),
  desire: L10nTriple(
    'Kişi, içeride uyanan duru fikri bozmadan tutmak isteyebilir.',
    'Holding a waking clear idea without breaking it may be sought.',
    'Может хотеться удержать просыпающуюся ясную идею, не ломая её.',
  ),
  fear: L10nTriple(
    'Netliğin incitmesi veya fikrin dağılması kaygı yaratabilir.',
    'Clarity wounding someone, or the idea scattering, may cause unease.',
    'Тревогу может вызывать ранение ясностью или рассеяние идеи.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasında net bir cümle çok şey ifade edebilir; bir şeyi açıkça söylemek, onu keserek söylemekle aynı şey değildir.',
    'A clear sentence can matter a great deal between two people, and saying something clearly is not the same as cutting with it.',
    'Ясная фраза может значить многое между двумя людьми, и сказать что-то прямо — не то же самое, что сказать это раня.',
  ),
  decisionDynamic: L10nTriple(
    'Küçük ve dürüst bir ayrım, burada büyük bir savaş çıkarmaktan daha değerlidir.',
    'A small, honest distinction is worth more here than staging a grand battle over it.',
    'Небольшое честное различие значит здесь больше, чем устраивать из-за него большую битву.',
  ),
  actionDirection: L10nTriple(
    'Varsayımı yüksek sesle adlandırın ve netliğinizin işi görmesine izin verin, sesinizdeki bir keskinliğin değil.',
    'Name the assumption out loud and let your clarity do the work instead of an edge in your voice.',
    'Назовите допущение вслух и позвольте ясности сделать своё дело, а не остроте в голосе.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ölçülü bir kenar, ilk fikri canlı ve yönetilebilir tutar.',
      'A measured edge keeps the first idea alive and workable.',
      'Сдержанное остриё удерживает первую идею живой и управляемой.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['firstEdge', 'clearIdea', 'air'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Keskinlik sert söze, dağınık zihne veya gereksiz kesmeye kayabilir.',
      'Edge may slide into harsh speech, scattered mind, or needless cutting.',
      'Остриё может стать жёсткой речью, рассеянным умом или ненужным резаньем.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.distortion,
    ],
    keywordIds: ['harshWord', 'scatteredMind', 'cuttingToCut'],
  ),
  symbolTags: [
    NarrativeSymbolTags.clarity,
    NarrativeSymbolTags.truth,
    NarrativeSymbolTags.choice,
  ],
  profileRevision: 1,
);
