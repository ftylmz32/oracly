import { inventsCatalogueImage, touchesTold } from './dream-client-parity.js';
import { lightFold } from './dream-lexical.js';
import { contradictsEmotion } from './dream-emotion-contract.js';
import { isRichNarrative, RECAP_MAX_SHARE, recapShare, RICH_MIN_TOUCHED, touchedClusters } from './dream-narrative-anchors.js';
import { unsupportedPersonalDomain } from './dream-personal-facts.js';
import type { DreamQualityInput } from './dream-quality.js';
import type { DreamData } from './parse-provider.js';

/**
 * Phase 4B premium narrative gate — runs after the Phase 2 gate and the
 * Phase 4A history gate, never instead of them. Each section must do its
 * own job: summary compresses (not copies), the emotional theme honours
 * stated and negated feelings, a rich dream is interpreted through more
 * than one detail, the reflection belongs to this Dream (or the safe
 * memory), nothing biographical is invented, and the only question is one
 * open, grounded conclusion. Deterministic; no provider call; no logging.
 */
export type DreamPremiumInput = DreamQualityInput & {
  /** The request's already-filtered memory (undefined when sensitive). */
  memorySummary?: string;
};

export type DreamPremiumFailure =
  | 'thin_section'
  | 'extra_question'
  | 'symbol_list'
  | 'plot_recap'
  | 'emotion_contradiction'
  | 'invented_image'
  | 'ungrounded_section'
  | 'weak_interpretation'
  | 'generic_reflection'
  | 'unsupported_personal_fact'
  | 'weak_conclusion';

/** Same floor as the client guard, so the backend never accepts a section the client drops. */
export const PREMIUM_MIN_CHARS = 24;
export const MAX_SYMBOLS = 8;

const WELLNESS = [
  /trust yourself|listen to your (?:intuition|heart|inner voice)|take (?:some )?time for yourself|believe in yourself|embrace (?:the )?change|step (?:out|outside) (?:of )?your comfort zone|follow your heart|be kind to yourself|self-care|everything happens for a reason/gu,
  /kendine güven|sezgilerini dinle|iç sesini dinle|kalbinin sesini dinle|kendine zaman ayır|kendine inan|değişimi kucakla|konfor alanının dışına çık|her şey bir sebeple|kendine nazik davran/gu,
  /доверься себе|доверяй себе|прислушайся к (?:своей )?интуиции|слушай (?:свою )?интуицию|слушай свое сердце|удели время себе|найди время для себя|верь в себя|прими перемены|выйди из зоны комфорта|все происходит не случайно/gu,
];

const OPEN = new Set([
  'what', "what's", 'how', 'which', 'where', 'when', 'why', 'who', 'whom', 'whose',
  'ne', 'neyi', 'neye', 'neyin', 'neyle', 'neden', 'nedir', 'neydi', 'nesi', 'niçin', 'niye',
  'что', 'чего', 'чему', 'чем', 'где', 'куда', 'откуда', 'когда', 'почему', 'зачем',
  'кто', 'кого', 'кому', 'кем', 'сколько', 'чей', 'чья', 'чье', 'чьи',
]);
const OPEN_STEM = /^(?:nasıl|hangi|nere|kim|kaç|neler|как)\p{L}*$/u;
const EN_YES_NO = /^(?:are|is|am|was|were|do|does|did|will|would|should|could|can|have|has|had|shall|may|might|must)$/;

function words(s: string): string[] {
  return lightFold(s.replace(/[’`]/g, "'")).match(/[\p{L}']+/gu) ?? [];
}

export function isOpenQuestion(conclusion: string): boolean {
  const ws = words(conclusion);
  if (!ws.length || EN_YES_NO.test(ws[0]!)) return false;
  return ws.some((w) => OPEN.has(w) || OPEN_STEM.test(w));
}

export function wellnessHits(text: string): number {
  const folded = lightFold(text);
  return WELLNESS.reduce((n, re) => n + (folded.match(re) ?? []).length, 0);
}

function symbolListOk(symbols: string[]): boolean {
  const keys = symbols.map((s) => lightFold(s).trim().replace(/\s+/g, ' '));
  return keys.length <= MAX_SYMBOLS && new Set(keys).size === keys.length;
}

export function evaluateDreamPremiumQuality(
  data: DreamData,
  input: DreamPremiumInput,
): DreamPremiumFailure | null {
  const { summary, emotionalTheme, interpretation, dailyLifeReflection, conclusion } = data;
  const prose = [summary, emotionalTheme, interpretation, dailyLifeReflection, conclusion];
  if (prose.some((s) => s.trim().length < PREMIUM_MIN_CHARS)) return 'thin_section';
  if (prose.slice(0, 4).some((s) => /[?？]/.test(s))) return 'extra_question';
  if (!symbolListOk(data.symbols)) return 'symbol_list';
  if (recapShare(input.narrative, summary) >= RECAP_MAX_SHARE) return 'plot_recap';
  const feelings = [input.narrative, ...input.emotions].join('. ');
  // Per section: one section affirming a feeling must not mask another denying it.
  if ([emotionalTheme, summary].some((s) => contradictsEmotion(feelings, s))) return 'emotion_contradiction';
  const { language, narrative } = input;
  const memory = input.memorySummary?.trim() ?? '';
  // The reflection alone may also lean on the safe memory actually sent.
  const reflectionTold = memory ? `${narrative} ${memory}` : narrative;
  if ([summary, emotionalTheme, interpretation].some((s) => inventsCatalogueImage(s, narrative, language)) ||
      inventsCatalogueImage(dailyLifeReflection, reflectionTold, language)) {
    return 'invented_image';
  }
  const observed = [...input.symbols, ...input.emotions];
  const told = narrative.trim() ? narrative : observed.join(' ');
  const grounded = (s: string, evidence = told) => !evidence.trim() || touchesTold(s, evidence, observed, language);
  if (![summary, emotionalTheme, interpretation].every((s) => grounded(s))) return 'ungrounded_section';
  if (isRichNarrative(narrative) && touchedClusters(narrative, interpretation, language) < RICH_MIN_TOUCHED) {
    return 'weak_interpretation';
  }
  if (!grounded(dailyLifeReflection, reflectionTold) || wellnessHits(dailyLifeReflection) >= 2) {
    return 'generic_reflection';
  }
  const dream = [narrative, ...observed].join(' ');
  if (unsupportedPersonalDomain(prose, `${dream} ${memory}`)) return 'unsupported_personal_fact';
  if (!isOpenQuestion(conclusion) || !grounded(conclusion)) return 'weak_conclusion';
  return null;
}
