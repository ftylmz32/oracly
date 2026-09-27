/**
 * Dream Phase 4C — mechanical observations for one live reading, using the
 * production Phase 4B measures where they exist. No semantic judgement:
 * memory "use" is only a term-presence fact pending independent review.
 */
import type { AppLanguage } from '../../src/ai/app-language.js';
import { touchesTold } from '../../src/ai/dream-client-parity.js';
import { contradictsEmotion } from '../../src/ai/dream-emotion-contract.js';
import { isRichNarrative, recapShare, touchedClusters } from '../../src/ai/dream-narrative-anchors.js';
import { unsupportedPersonalDomain } from '../../src/ai/dream-personal-facts.js';
import { isOpenQuestion, wellnessHits } from '../../src/ai/dream-premium-quality.js';
import { lightFold } from '../../src/ai/dream-lexical.js';
import type { DreamData } from '../../src/ai/parse-provider.js';
import type { Phase4cRecord } from './harness.js';
import { acceptanceInput } from './stages.js';
import {
  COUNT_OR_DATE, DIAGNOSIS, FATE, FIELDS, jaccard, longWords, ngrams, RECURRENCE, round,
  sentences, TAROT, trigramOverlap, words,
} from './observe-text.js';

export const ROLE_SIMILARITY_FLAG = 0.4;
const MEMORY_PREFIX = /^.*?\]\s*/u;

export function firstFailure(r: Phase4cRecord): string | null {
  const s = r.stages;
  if (!s) return r.errorCode;
  if (!s.parseSuccess) return 'parse';
  return [s.outputSafety, s.phase2, s.phase4A, s.phase4B].find((v) => v !== 'PASS') ?? null;
}

function duplicatePhrases(d: DreamData): string[] {
  const seen = new Map<string, Set<string>>();
  for (const f of FIELDS) for (const g of new Set(ngrams(words(d[f]), 5))) (seen.get(g) ?? seen.set(g, new Set()).get(g)!).add(f);
  return [...seen].filter(([, fs]) => fs.size >= 2).map(([g]) => g);
}

/** Non-narrative long words that appear in three or more sections. */
function repeatedImagery(d: DreamData, narrative: string): string[] {
  const told = longWords(narrative);
  const counts = new Map<string, number>();
  for (const f of FIELDS) for (const w of longWords(d[f])) if (!told.has(w)) counts.set(w, (counts.get(w) ?? 0) + 1);
  return [...counts].filter(([, n]) => n >= 3).map(([w]) => w).sort();
}

function memoryUse(r: Phase4cRecord, prose: string) {
  if (!r.memorySummary) return null;
  const memoryText = r.memorySummary.replace(MEMORY_PREFIX, '');
  const told = longWords(r.narrative);
  const own = longWords(prose);
  const terms = [...longWords(memoryText)].filter((w) => !told.has(w) && own.has(w)).sort();
  const tarot = TAROT.test(lightFold(prose));
  return {
    memorySource: r.memorySource,
    memoryOnlyTermsInOutput: terms,
    sourceReadingNamed: tarot,
    mechanical: terms.length || tarot ? 'memory_terms_present' : 'not_used',
    independentReviewRequired: terms.length > 0 || tarot,
  };
}

export function observeReading(r: Phase4cRecord) {
  const d = r.stages?.parsed;
  if (!d) return { runId: r.runId, parsed: false as const };
  const language = r.language as AppLanguage;
  const input = acceptanceInput(
    { narrative: r.narrative, symbols: r.symbols, emotions: r.emotions, memorySummary: r.memorySummary ?? undefined },
    language,
  );
  const observed = [...input.symbols, ...input.emotions];
  const reflectionTold = input.memorySummary ? `${input.narrative} ${input.memorySummary}` : input.narrative;
  const feelings = [input.narrative, ...input.emotions].join('. ');
  const prose = FIELDS.map((f) => d[f]);
  const allText = prose.join(' ');
  const claims = sentences(allText).filter((s) => RECURRENCE.test(lightFold(s)));
  const claimText = lightFold(claims.join(' '));
  const grounded = (s: string, told = input.narrative) => touchesTold(s, told, observed, language);
  return {
    runId: r.runId,
    parsed: true as const,
    firstFailure: firstFailure(r),
    summaryTrigramOverlap: trigramOverlap(input.narrative, d.summary),
    summaryRecapShare: round(recapShare(input.narrative, d.summary)),
    richNarrative: isRichNarrative(input.narrative),
    interpretationAnchorsTouched: touchedClusters(input.narrative, d.interpretation, language),
    sectionGrounded: {
      summary: grounded(d.summary),
      emotionalTheme: grounded(d.emotionalTheme),
      interpretation: grounded(d.interpretation),
      dailyLifeReflection: grounded(d.dailyLifeReflection, reflectionTold),
      conclusion: grounded(d.conclusion),
    },
    emotionContradiction: { summary: contradictsEmotion(feelings, d.summary), emotionalTheme: contradictsEmotion(feelings, d.emotionalTheme) },
    reflectionWellnessHits: wellnessHits(d.dailyLifeReflection),
    conclusionOpenQuestion: isOpenQuestion(d.conclusion),
    questionCount: (allText.match(/[?？]/g) ?? []).length,
    duplicatePhrasesAcrossFields: duplicatePhrases(d),
    roleSimilarity: {
      interpretationVsReflection: jaccard(d.interpretation, d.dailyLifeReflection),
      summaryVsTheme: jaccard(d.summary, d.emotionalTheme),
    },
    repeatedImagery: repeatedImagery(d, input.narrative),
    historySupplied: Array.isArray(r.history) && r.history.length > 0,
    historyClaims: claims,
    historyClaimFlags: { countOrDate: COUNT_OR_DATE.test(claimText), fate: FATE.test(claimText), diagnosis: DIAGNOSIS.test(claimText) },
    addressedDomain: unsupportedPersonalDomain(prose, ''),
    unsupportedDomain: unsupportedPersonalDomain(prose, `${[input.narrative, ...observed].join(' ')} ${input.memorySummary ?? ''}`),
    memory: memoryUse(r, allText),
  };
}

export type ReadingObservation = ReturnType<typeof observeReading>;
