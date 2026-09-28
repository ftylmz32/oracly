import { LEXICON, WORD_NEGATED, type DreamEmotion } from './dream-emotion-lexicon.js';
import { lightFold } from './dream-lexical.js';

/**
 * Stated vs negated feeling — deterministic, clause-scoped, TR / EN / RU.
 * A response contradicts the dreamer when it affirms a feeling the
 * narrative only negated ("I was not afraid" → "a deep fear"), or negates
 * a feeling the narrative only affirmed. Unknown feelings are ignored.
 * A feeling another feeling "prevails over" ("любопытство преобладает над
 * страхом") is subordinated: neither affirmed nor negated.
 */
export type { DreamEmotion } from './dream-emotion-lexicon.js';

type Stance = { affirmed: boolean; negated: boolean };

const PRE = new Set([
  'not', 'no', 'never', 'nor', 'neither', 'absence', 'lack', 'lacking',
  'free', 'than', 'instead', 'hardly', 'nothing', 'none',
  'не', 'ни', 'нет', 'без', 'вместо', 'никакого', 'никакой', 'никакая', 'никаких',
  'ничуть', 'нисколько', 'чем',
]);
const EN_COPULA = new Set(['was', 'is', 'were', 'are', 'felt', 'seemed', 'stayed']);
const EN_ABSENT = new Set(['absent', 'missing', 'gone', 'lacking', 'nowhere', 'free']);
const TR_FILLER = new Set(['hiç', 'da', 'de', 'bile', 'asla', 'pek', 'hissi', 'duygusu']);
const TR_POST =
  /^(?:değil\p{L}*|yok\p{L}*|uzak\p{L}*|yerine|hisset(?:me[dyzmn]|miyor)\p{L}*|hissedil(?:me[dyzmn]|miyor)\p{L}*|duy(?:ma[dyzmn]|muyor)\p{L}*|duyul(?:ma[dyzmn]|muyor)\p{L}*|et(?:me[dyzmn]|miyor)\p{L}*|ol(?:ma[dyzmn]|muyor)\p{L}*|yaşa(?:ma[dyzmn]|mıyor)\p{L}*|dönüş(?:me[dyzmn]|müyor)\p{L}*)$/u;
const RU_AFTER_NE = /^(?:было|был|была|ощущ\p{L}*|чувств\p{L}*|испыт\p{L}*|возник\p{L}*|появ\p{L}*)$/u;
/** "не вызывает (у тебя) испуга": negation bound to this verb, never to a long clause. */
const RU_CAUSE = /^(?:вызыва\p{L}*|вызвал\p{L}*|вызов(?:ет|ут)|вызвать)$/u;
const RU_CAUSE_GAP = new Set(['у', 'тебя', 'меня', 'нас', 'вас', 'него', 'нее', 'них', 'особого', 'малейшего']);
/** "without (any) fear": `without` negates only the feeling it governs. */
const EN_WITHOUT_GAP = new Set(['any', 'much', 'a', 'the', 'slightest', 'real']);
/** "absence of fear": a Russian absence noun directly before the feeling. */
const RU_ABSENCE = /^отсутств\p{L}*$/u;
/** "X prevails over / outweighs fear": the feeling after it is subordinated. */
const OVER = new Set(['над', 'over']);
const PREVAILS = /^(?:преоблада\p{L}*|перевешива\p{L}*|берет|брало|сильнее|prevail\p{L}*|dominat\p{L}*|wins|won|triumph\p{L}*)$/u;
const OUTWEIGHS = /^outweigh\p{L}*$/u;
const CONTRAST = new Set(['but', 'yet', 'although', 'though', 'however', 'whereas', 'ama', 'fakat', 'ancak', 'но', 'однако', 'а']);

function clauses(text: string): string[][] {
  const out: string[][] = [[]];
  const parts = lightFold(text.replace(/[’`]/g, "'")).match(/[\p{L}']+|[,;:.!?…—–()]/gu) ?? [];
  for (const p of parts) {
    if (/^[,;:.!?…—–()]$/u.test(p) || CONTRAST.has(p)) out.push([]);
    else out[out.length - 1]!.push(p.replace(/^'+|'+$/g, ''));
  }
  return out.filter((c) => c.length);
}

/** Index of the word before [i] once up to [max] [gap] words are skipped. */
function headBefore(c: string[], i: number, gap: Set<string>, max: number): number {
  let k = i - 1;
  while (k >= 0 && i - 1 - k < max && gap.has(c[k]!)) k--;
  return k;
}

function negatedInClause(c: string[], i: number): boolean {
  for (let k = Math.max(0, i - 3); k < i; k++) {
    if (PRE.has(c[k]!) || c[k]!.endsWith("n't")) return true;
  }
  if (i > 0 && RU_ABSENCE.test(c[i - 1]!)) return true;
  if (c[headBefore(c, i, EN_WITHOUT_GAP, 2)] === 'without') return true;
  const cause = headBefore(c, i, RU_CAUSE_GAP, 3);
  if (cause > 0 && RU_CAUSE.test(c[cause]!) && c[cause - 1] === 'не') return true;
  const [a, b] = [c[i + 1], c[i + 2]];
  if (c.slice(i + 1, i + 4).some((w) => EN_ABSENT.has(w))) return true;
  if (a && EN_COPULA.has(a) && b && (b === 'not' || b === 'never' || EN_ABSENT.has(b))) return true;
  if (a && /^(?:wasn't|isn't|weren't|aren't)$/.test(a)) return true;
  const tr = a && TR_FILLER.has(a) ? b : a;
  if (tr && TR_POST.test(tr)) return true;
  if (a === 'нет' || (a && a.startsWith('отсутств'))) return true;
  return a === 'не' && !!b && RU_AFTER_NE.test(b);
}

function subordinated(c: string[], i: number): boolean {
  const before = c[i - 1];
  if (before && OUTWEIGHS.test(before)) return true;
  if (!before || !OVER.has(before)) return false;
  return c.slice(Math.max(0, i - 4), i - 1).some((w) => PREVAILS.test(w));
}

/** The canonical feeling a single (light-folded) word affirms, if any ("неспокойный" affirms none). */
export function affirmedEmotionOf(word: string): DreamEmotion | null {
  const hit = LEXICON.find(([, p]) => p.test(word))?.[0];
  if (!hit || WORD_NEGATED.find(([e]) => e === hit)![1].test(word)) return null;
  return hit;
}

export function emotionStances(text: string): Map<DreamEmotion, Stance> {
  const out = new Map<DreamEmotion, Stance>();
  for (const c of clauses(text)) {
    c.forEach((w, i) => {
      for (const [emotion, pattern] of LEXICON) {
        if (!pattern.test(w) || subordinated(c, i)) continue;
        const own = WORD_NEGATED.find(([e]) => e === emotion)![1].test(w);
        const negated = own || negatedInClause(c, i);
        const s = out.get(emotion) ?? { affirmed: false, negated: false };
        if (negated) s.negated = true;
        else s.affirmed = true;
        out.set(emotion, s);
      }
    });
  }
  return out;
}

/** True when [claims] reverse a feeling stated (or denied) only one way in [told]. */
export function contradictsEmotion(told: string, claims: string): boolean {
  const said = emotionStances(told);
  const claimed = emotionStances(claims);
  for (const [emotion, c] of claimed) {
    const s = said.get(emotion);
    if (!s) continue;
    if (s.negated && !s.affirmed && c.affirmed) return true;
    if (s.affirmed && !s.negated && c.negated && !c.affirmed) return true;
  }
  return false;
}

/**
 * Emotional-theme role grounding: [claims] names at least one feeling the
 * dreamer stated with the same stance (affirmed, or negated). "Relief" is
 * grounded by "I felt relieved"; "isolation" by nothing unless told.
 */
export function honoursStatedEmotion(told: string, claims: string): boolean {
  const said = emotionStances(told);
  for (const [emotion, c] of emotionStances(claims)) {
    const s = said.get(emotion);
    if (!s) continue;
    if ((c.affirmed && s.affirmed) || (c.negated && s.negated)) return true;
  }
  return false;
}
