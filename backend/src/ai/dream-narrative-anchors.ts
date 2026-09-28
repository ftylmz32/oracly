import type { AppLanguage } from './app-language.js';
import { sameWord } from './dream-lexical.js';
import { isDreamWord, significant, STOP, tokens } from './dream-quality.js';

/**
 * Narrative anchors — distinct concrete details the dreamer told, grouped
 * into clusters of adjacent words ("red door" is one anchor, "sand" another).
 *
 * RICH narrative: ≥ RICH_MIN_WORDS distinct anchor words spread over
 * ≥ RICH_MIN_CLUSTERS clusters. Only a rich narrative must be interpreted
 * through ≥ RICH_MIN_TOUCHED distinct clusters; a sparse dream never is.
 */
export const RICH_MIN_WORDS = 5;
export const RICH_MIN_CLUSTERS = 3;
export const RICH_MIN_TOUCHED = 2;

/**
 * Summary near-verbatim copy (Phase 4C.1): the share of summary tokens
 * inside shared trigrams reaches RECAP_MAX_SHARE AND the copy is either one
 * contiguous run of RECAP_MIN_RUN tokens or RECAP_MIN_COPIED copied
 * content words. A compressed line that reuses "train station" and "old
 * friend" is not a recap; a sentence lifted from the narrative, or a
 * scene-by-scene retelling, is.
 */
export const RECAP_MAX_SHARE = 0.6;
export const RECAP_MIN_TOKENS = 6;
export const RECAP_MIN_RUN = 6;
export const RECAP_MIN_COPIED = 6;

const ANCHOR_STOP = new Set([
  'not', 'felt', 'feel', 'saw', 'see', 'seen', 'her', 'his', 'him', 'she', 'had',
  'did', 'got', 'all', 'any', 'too', 'our', 'out', 'who', 'how', 'why', 'one',
  'gordum', 'hissettim', 'vardi', 'cok', 'sonra', 'birden', 'orada', 'gibiydi',
  'мне', 'снилось', 'снилась', 'снился', 'снится', 'приснилось', 'приснился',
  'приснилась', 'там', 'вдруг', 'все', 'был', 'шла', 'шел',
]);

/** First-person narrative → second-person prose, so a restated plot compares. */
const PERSON: Record<string, string> = {
  i: 'you', me: 'you', my: 'your', mine: 'yours', myself: 'yourself', am: 'are',
  я: 'ты', меня: 'тебя', мне: 'тебе', мой: 'твой', моя: 'твоя', мое: 'твое', мои: 'твои',
  ben: 'sen', benim: 'senin', bana: 'sana', beni: 'seni',
};

function isAnchor(w: string): boolean {
  return w.length >= 3 && !STOP.has(w) && !isDreamWord(w) && !ANCHOR_STOP.has(w);
}

/** Clauses never join: agglutinative Turkish has too few stop words to split on alone. */
function segments(narrative: string): string[][] {
  return narrative.split(/[.,;:!?…—–()]+/u).map(tokens).filter((s) => s.length);
}

function clusterCount(words: string[], segs: string[][]): number {
  const parent = new Map(words.map((w) => [w, w]));
  const root = (w: string): string => (parent.get(w) === w ? w : root(parent.get(w)!));
  for (const seq of segs) {
    for (let i = 0; i + 1 < seq.length; i++) {
      const [a, b] = [seq[i]!, seq[i + 1]!];
      if (parent.has(a) && parent.has(b) && root(a) !== root(b)) parent.set(root(a), root(b));
    }
  }
  return new Set(words.map(root)).size;
}

export function isRichNarrative(narrative: string): boolean {
  const segs = segments(narrative);
  const anchors = [...new Set(segs.flat().filter(isAnchor))];
  return anchors.length >= RICH_MIN_WORDS && clusterCount(anchors, segs) >= RICH_MIN_CLUSTERS;
}

/** Distinct narrative clusters the [text] reaches through its own words. */
export function touchedClusters(narrative: string, text: string, language: AppLanguage): number {
  const segs = segments(narrative);
  const own = [...significant(text)];
  const touched = [...new Set(segs.flat().filter(isAnchor))].filter((a) =>
    own.some((w) => sameWord(w, a, language)),
  );
  return touched.length ? clusterCount(touched, segs) : 0;
}

type RecapCopy = { share: number; run: number; copied: number };

function recapCopy(narrative: string, summary: string): RecapCopy {
  const person = (w: string) => PERSON[w] ?? w;
  const n = tokens(narrative).map(person);
  const s = tokens(summary).map(person);
  if (s.length < RECAP_MIN_TOKENS) return { share: 0, run: 0, copied: 0 };
  const grams = new Set<string>();
  for (let i = 0; i + 2 < n.length; i++) grams.add(n.slice(i, i + 3).join(' '));
  const covered = new Array<boolean>(s.length).fill(false);
  for (let i = 0; i + 2 < s.length; i++) {
    if (grams.has(s.slice(i, i + 3).join(' '))) covered[i] = covered[i + 1] = covered[i + 2] = true;
  }
  let run = 0;
  let current = 0;
  for (const c of covered) run = Math.max(run, (current = c ? current + 1 : 0));
  const copied = new Set(s.filter((w, i) => covered[i] && isAnchor(w))).size;
  return { share: covered.filter(Boolean).length / s.length, run, copied };
}

export function recapShare(narrative: string, summary: string): number {
  return recapCopy(narrative, summary).share;
}

export function isPlotRecap(narrative: string, summary: string): boolean {
  const { share, run, copied } = recapCopy(narrative, summary);
  return share >= RECAP_MAX_SHARE && (run >= RECAP_MIN_RUN || copied >= RECAP_MIN_COPIED);
}
