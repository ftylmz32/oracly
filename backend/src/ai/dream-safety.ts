import { ErrorCode, fail } from '../errors.js';
import { INPUT, OUTPUT } from './dream-safety-lexicon.js';
import { sanitizeText } from './sanitize.js';

/**
 * Dream Phase 3 safety firewall — deterministic, TR/EN/RU, zero provider
 * calls. Mirrors `lib/features/dream/safety/` (text mechanics, input policy,
 * output firewall). Dream imagery is allowed; a waking-life disclosure or
 * request is not. Nothing here logs or returns the text it inspects.
 */
export type DreamSafetyConcern =
  | 'crisis'
  | 'acute_distress'
  | 'trauma'
  | 'delusion'
  | 'diagnosis';

const PRIORITY: DreamSafetyConcern[] = [
  'crisis',
  'acute_distress',
  'trauma',
  'delusion',
  'diagnosis',
];

type Segment = { text: string; question: boolean };

const SEGMENT = /[^.!?…;:\n[\]]+[.!?…;:\n[\]]*/g;
const TRAIL = /[.!?…;:\n[\]]+$/;
const WORD = /[\p{L}']+/gu;
const BEFORE = new Set([
  'not', 'never', 'no', 'nobody', 'nothing', "don't", 'dont', "doesn't",
  "didn't", "won't", 'cannot', "can't", "isn't", "aren't", "wasn't",
  "shouldn't", 'if', 'whether', 'не', 'нет', 'никогда', 'нельзя', 'ни',
  'никто', 'ли', 'если', 'eğer', 'kimse', 'hiç',
]);
const AFTER = new Set([
  'değil', 'değildir', 'gelmez', 'kanitlamaz', 'göstermez', 'doğrulamaz',
]);

function words(alternatives: string[]): RegExp {
  return new RegExp(`(?<![\\p{L}\\p{N}])(?:${alternatives.join('|')})`, 'gu');
}

const IN = Object.fromEntries(
  Object.entries(INPUT).map(([k, v]) => [k, words(v)]),
) as Record<keyof typeof INPUT, RegExp>;
const OUT = Object.fromEntries(
  Object.entries(OUTPUT).map(([k, v]) => [k, words(v)]),
) as Record<keyof typeof OUTPUT, RegExp>;

export function foldSafety(text: string): string {
  return text
    .toLowerCase()
    .replace(/\u0307/g, '')
    .replace(/ı/g, 'i')
    .replace(/ё/g, 'е')
    .replace(/[’‘`´]/g, "'")
    .replace(/[ \t\u00A0]+/g, ' ');
}

function segments(raw: string): Segment[] {
  const out: Segment[] = [];
  for (const m of foldSafety(raw).matchAll(SEGMENT)) {
    const body = m[0].replace(TRAIL, '').trim();
    if (body) out.push({ text: body, question: m[0].includes('?') });
  }
  return out;
}

function has(pattern: RegExp, text: string): boolean {
  return [...text.matchAll(pattern)].length > 0;
}

function framed(text: string, at: number): boolean {
  let frameEnd: number | null = null;
  for (const d of text.matchAll(IN.dream)) {
    const end = d.index + d[0].length;
    if (end <= at) frameEnd = end;
  }
  if (frameEnd === null) return false;
  const start = frameEnd;
  return ![...text.matchAll(IN.waking)].some(
    (w) => w.index >= start && w.index < at,
  );
}

function negated(text: string, start: number, end: number): boolean {
  const before = [...text.slice(0, start).matchAll(WORD)].map((w) => w[0]);
  if (before.slice(-6).some((w) => BEFORE.has(w))) return true;
  const after = [...text.slice(end).matchAll(WORD)].slice(0, 4);
  return after.some((w) => AFTER.has(w[0]));
}

function hit(
  pattern: RegExp,
  text: string,
  opts: { dream?: boolean; negationAware?: boolean } = {},
): boolean {
  for (const m of text.matchAll(pattern)) {
    if (opts.dream && framed(text, m.index)) continue;
    if (opts.negationAware && negated(text, m.index, m.index + m[0].length)) continue;
    return true;
  }
  return false;
}

function concernOf({ text, question }: Segment): DreamSafetyConcern | null {
  if (has(IN.crisis, text)) return 'crisis';
  if (hit(IN.acute, text, { dream: true })) return 'acute_distress';
  if (has(IN.abuse, text) && has(IN.reality, text)) return 'trauma';
  if ((has(IN.proof, text) && has(IN.agents, text)) || hit(IN.voices, text, { dream: true })) {
    return 'delusion';
  }
  if (hit(IN.diagnosisTerms, text, { dream: true }) && (question || has(IN.diagnosisLinks, text))) {
    return 'diagnosis';
  }
  return null;
}

/** The most urgent concern across [texts], or null when a reading may run. */
export function classifyDreamSafety(texts: string[]): DreamSafetyConcern | null {
  let worst: DreamSafetyConcern | null = null;
  for (const text of texts) {
    for (const segment of segments(text)) {
      const concern = concernOf(segment);
      if (concern && (worst === null || PRIORITY.indexOf(concern) < PRIORITY.indexOf(worst))) {
        worst = concern;
      }
    }
  }
  return worst;
}

/**
 * Pre-provider (and pre-replay) input gate. The request narrative already
 * carries the dreamer's guided answers as separate lines. Only the error
 * code leaves this function.
 */
export function assertDreamInputSafe(payload: Record<string, unknown>): void {
  if (classifyDreamSafety([sanitizeText(payload.narrative)]) !== null) {
    fail(ErrorCode.dreamSafetyBlocked);
  }
}

/** Retrieved memory that must never enrich the prompt. */
export function isSensitiveDreamMemory(memory: string): boolean {
  if (!memory.trim()) return false;
  if (classifyDreamSafety([memory]) !== null) return true;
  return has(IN.memory, foldSafety(memory));
}

export type DreamOutputCheck =
  | 'self_harm'
  | 'medical_directive'
  | 'diagnosis'
  | 'delusion'
  | 'trauma_blame'
  | 'death_certainty';

function outputCheck(text: string): DreamOutputCheck | null {
  const asserts = (p: RegExp) => hit(p, text, { negationAware: true });
  if (asserts(OUT.selfHarm)) return 'self_harm';
  if (asserts(OUT.medical)) return 'medical_directive';
  if (asserts(OUT.diagnosis)) return 'diagnosis';
  if (asserts(OUT.delusion)) return 'delusion';
  if (has(OUT.traumaTerms, text) && asserts(OUT.blame)) return 'trauma_blame';
  if (asserts(OUT.death)) return 'death_certainty';
  return null;
}

/** The first violated output check across [texts], or null when safe. */
export function dreamOutputViolation(texts: string[]): DreamOutputCheck | null {
  for (const text of texts) {
    for (const segment of segments(text)) {
      const check = outputCheck(segment.text);
      if (check) return check;
    }
  }
  return null;
}

export type DreamOutputFields = {
  summary: string;
  symbols: string[];
  emotionalTheme: string;
  interpretation: string;
  dailyLifeReflection: string;
  conclusion: string;
};

export function dreamOutputFields(data: DreamOutputFields): string[] {
  return [
    data.summary,
    ...data.symbols,
    data.emotionalTheme,
    data.interpretation,
    data.dailyLifeReflection,
    data.conclusion,
  ];
}
