import { lightFold } from './dream-lexical.js';

/**
 * Stated vs negated feeling — deterministic, clause-scoped, TR / EN / RU.
 * A response contradicts the dreamer when it affirms a feeling the
 * narrative only negated ("I was not afraid" → "a deep fear"), or negates
 * a feeling the narrative only affirmed. Unknown feelings are ignored.
 */
export type DreamEmotion = 'fear' | 'anxiety' | 'calm' | 'joy' | 'sadness' | 'curiosity';

type Stance = { affirmed: boolean; negated: boolean };

const LEXICON: Array<[DreamEmotion, RegExp]> = [
  ['fear', /^(?:afraid|unafraid|fear\p{L}*|scared|scary|frighten\p{L}*|terrif\p{L}*|terror|panic\p{L}*|dread\p{L}*|kork\p{L}*|dehşet\p{L}*|panik\p{L}*|страх\p{L}*|страш\p{L}*|бесстраш\p{L}*|боял\p{L}*|боюсь|боится|бояться|испуг\p{L}*|испуга\p{L}*|ужас\p{L}*)$/u],
  ['anxiety', /^(?:anxi\p{L}*|worr\p{L}*|nervous\p{L}*|uneas\p{L}*|tense|tension|kaygı\p{L}*|endişe\p{L}*|tedirgin\p{L}*|gergin\p{L}*|huzursuz\p{L}*|тревог\p{L}*|тревож\p{L}*|беспоко\p{L}*|волновал\p{L}*|волнуюсь|волнение\p{L}*|взволнова\p{L}*|нервн\p{L}*)$/u],
  ['calm', /^(?:calm\p{L}*|peace\p{L}*|seren\p{L}*|relax\p{L}*|tranquil\p{L}*|sakin\p{L}*|huzur\p{L}*|dingin\p{L}*|rahat\p{L}*|спокой\p{L}*|неспокой\p{L}*|умиротвор\p{L}*|безмятеж\p{L}*)$/u],
  ['joy', /^(?:happy|happier|happiest|happily|happiness|unhappy|joy\p{L}*|glad\p{L}*|delight\p{L}*|cheerful\p{L}*|mutlu\p{L}*|sevin\p{L}*|neşe\p{L}*|радост\p{L}*|безрадост\p{L}*|радова\p{L}*|счастл\p{L}*|счасть\p{L}*|весел\p{L}*)$/u],
  ['sadness', /^(?:sad|sadly|sadness|unhapp\p{L}*|sorrow\p{L}*|grief|griev\p{L}*|melanchol\p{L}*|üzgün\p{L}*|üzüntü\p{L}*|üzül\p{L}*|hüzün\p{L}*|hüzn\p{L}*|keder\p{L}*|mutsuz\p{L}*|грус\p{L}*|печал\p{L}*|тоск\p{L}*)$/u],
  ['curiosity', /^(?:curio\p{L}*|merak\p{L}*|любопыт\p{L}*)$/u],
];

/** The word itself carries the negation (fearless, korkmadım, kaygısız, бесстрашно). */
const WORD_NEGATED: Array<[DreamEmotion, RegExp]> = [
  ['fear', /^(?:unafraid|fearless\p{L}*|korkusuz\p{L}*|бесстраш\p{L}*)$|^korkm[aeıiuü](?:[dyzmn]|$)/u],
  ['anxiety', /^(?:kaygısız\p{L}*|endişesiz\p{L}*)$|^(?:kaygılan|endişelen)m[aeıiuü](?:[dyzmn]|$)/u],
  ['calm', /^(?:huzursuz\p{L}*|rahatsız\p{L}*|неспокой\p{L}*|restless)$|^(?:sakinleş|rahatla)m[aeıiuü](?:[dyzmn]|$)/u],
  ['joy', /^(?:unhappy|joyless|neşesiz\p{L}*|безрадост\p{L}*)$|^sevinm[aeıiuü](?:[dyzmn]|$)/u],
  ['sadness', /^üzülm[aeıiuü](?:[dyzmn]|$)/u],
  ['curiosity', /^(?:incurious|meraksız\p{L}*)$/u],
];

const PRE = new Set([
  'not', 'no', 'never', 'without', 'nor', 'neither', 'absence', 'lack', 'lacking',
  'free', 'than', 'instead', 'hardly', 'nothing', 'none',
  'не', 'ни', 'нет', 'без', 'вместо', 'никакого', 'никакой', 'никакая', 'никаких',
  'ничуть', 'нисколько', 'чем',
]);
const EN_COPULA = new Set(['was', 'is', 'were', 'are', 'felt', 'seemed', 'stayed']);
const EN_ABSENT = new Set(['absent', 'missing', 'gone', 'lacking', 'nowhere', 'free']);
const TR_FILLER = new Set(['hiç', 'da', 'de', 'bile', 'asla', 'pek']);
const TR_POST =
  /^(?:değil\p{L}*|yok\p{L}*|uzak\p{L}*|yerine|hisset(?:me[dyzmn]|miyor)\p{L}*|duy(?:ma[dyzmn]|muyor)\p{L}*|et(?:me[dyzmn]|miyor)\p{L}*|ol(?:ma[dyzmn]|muyor)\p{L}*|yaşa(?:ma[dyzmn]|mıyor)\p{L}*)$/u;
const RU_AFTER_NE = /^(?:было|был|была|ощущ\p{L}*|чувств\p{L}*|испыт\p{L}*|возник\p{L}*|появ\p{L}*)$/u;
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

function negatedInClause(c: string[], i: number): boolean {
  for (let k = Math.max(0, i - 3); k < i; k++) {
    if (PRE.has(c[k]!) || c[k]!.endsWith("n't")) return true;
  }
  const [a, b] = [c[i + 1], c[i + 2]];
  if (c.slice(i + 1, i + 4).some((w) => EN_ABSENT.has(w))) return true;
  if (a && EN_COPULA.has(a) && b && (b === 'not' || b === 'never' || EN_ABSENT.has(b))) return true;
  if (a && /^(?:wasn't|isn't|weren't|aren't)$/.test(a)) return true;
  const tr = a && TR_FILLER.has(a) ? b : a;
  if (tr && TR_POST.test(tr)) return true;
  if (a === 'нет' || (a && a.startsWith('отсутств'))) return true;
  return a === 'не' && !!b && RU_AFTER_NE.test(b);
}

export function emotionStances(text: string): Map<DreamEmotion, Stance> {
  const out = new Map<DreamEmotion, Stance>();
  for (const c of clauses(text)) {
    c.forEach((w, i) => {
      for (const [emotion, pattern] of LEXICON) {
        if (!pattern.test(w)) continue;
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
