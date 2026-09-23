/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeCups12 = NarrativeCardProfile(
  canonicalCardId: 'cups_12',
  coreMeaning: L10nTriple(
    'Kadehi yola çıkaranı anlatır; sunma ve akış alanıdır, peşinden koşulan romantizm değil.',
    'One who takes the cup on the road; a field of offer and flow, not romance-as-chase.',
    'Говорит о том, кто берёт чашу в путь; поле предложения и потока, не романтики-погони.',
  ),
  light: L10nTriple(
    'Taşınan bir sunu, her kapıyı çalmadan duygusal akışı canlı tutabilir.',
    'A carried offer can keep emotional flow alive without knocking every door.',
    'Несомое предложение может держать эмоциональный поток живым, не стуча в каждую дверь.',
  ),
  shadow: L10nTriple(
    'Akış dağınık kalbe, kaçış romantizmine veya savrulmuş sunuya kayabilir.',
    'Flow turns brittle when it becomes a scattered heart, escape-romance, or a flung offer.',
    'Поток может стать рассеянным сердцем, романтикой-бегством или разбросанным предложением.',
  ),
  tension: L10nTriple(
    'Sunuyu taşıma arzusu ile her kapıyı çalmama ihtiyacı çekişir.',
    'The wish to carry the offer contends with the need not to knock every door.',
    'Желание нести предложение спорит с нуждой не стучать в каждую дверь.',
  ),
  desire: L10nTriple(
    'Kişi, duygusal bir sunuyu yolda dürüstçe ilerletmek isteyebilir.',
    'There may be a wish to advance an emotional offer honestly on the road.',
    'Может хотеться честно продвигать эмоциональное предложение в пути.',
  ),
  fear: L10nTriple(
    'Reddedilmek veya sununun dağılması kaygı yaratabilir.',
    'Being refused, or the offer scattering, may cause unease.',
    'Тревогу может вызывать отказ или рассеяние предложения.',
  ),
  relationshipDynamic: L10nTriple(
    'Bir teklif iki kişi arasında hareket edebilir; onun peşinden koşmak, iki tarafın da gerçekten paylaştığı bir akıştan farklı bir şeydir.',
    'An offer can move between two people, and chasing it stays different from a flow that both sides actually share.',
    'Предложение может задвигаться между двумя людьми, и погоня за ним — не то же самое, что поток, которым действительно делятся обе стороны.',
  ),
  decisionDynamic: L10nTriple(
    'Bu teklifin gerçekten nereye taşındığı, ulaşılabilen her kapıyı denemekten daha önemlidir.',
    'Where this offer is actually being carried matters more than trying every door in reach.',
    'Куда на самом деле несут это предложение, важнее, чем пробовать каждую доступную дверь.',
  ),
  actionDirection: L10nTriple(
    'Teklifi, geçtiğiniz her kapıyı çalmak yerine seçtiğiniz tek bir akışa doğru taşıyın.',
    'Carry the offer toward one chosen flow rather than knocking on every door you pass.',
    'Несите предложение к одному выбранному потоку, а не стучите в каждую дверь по пути.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yoldaki sunu, kadehi dağınık peşinden koşmadan akışta tutar.',
      'An offer on the road keeps the cup in flow without scattered chase.',
      'Предложение в пути держит чашу в потоке без рассеянной погони.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.threshold,
      NarrativeKeywordIds.opening,
      NarrativeKeywordIds.flow,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Akış kaçış romantizmine sapabilir veya kalbi savrulmuş sunulara aşırı dağıtabilir.',
      'Flow may misdirect into escape-romance, or excess may scatter the heart into flung offers.',
      'Поток может сбиться в романтику-бегство, а избыток — рассеять сердце в разбросанные предложения.',
    ),
    transforms: [
      ReversedTransformKind.misdirection,
      ReversedTransformKind.excess,
    ],
    keywordIds: [
      NarrativeKeywordIds.scatter,
      NarrativeKeywordIds.escape,
      NarrativeKeywordIds.haste,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.desire,
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.hope,
  ],
  profileRevision: 1,
);
