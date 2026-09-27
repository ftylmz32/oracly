/**
 * Dream Phase 4C — small text primitives for mechanical observations.
 * Observations are facts about strings, never a semantic verdict.
 */
import { lightFold } from '../../src/ai/dream-lexical.js';

export const FIELDS = ['summary', 'emotionalTheme', 'interpretation', 'dailyLifeReflection', 'conclusion'] as const;
export type Field = (typeof FIELDS)[number];

export const words = (s: string): string[] =>
  lightFold(s.replace(/[’`]/g, "'")).match(/[\p{L}\p{N}']+/gu) ?? [];

export const sentences = (s: string): string[] =>
  s.split(/(?<=[.!?…])\s+/u).map((x) => x.trim()).filter(Boolean);

export const normSentence = (s: string): string => words(s).join(' ');

export function ngrams(ws: string[], n: number): string[] {
  const out: string[] = [];
  for (let i = 0; i + n <= ws.length; i++) out.push(ws.slice(i, i + n).join(' '));
  return out;
}

/** Share of [text]'s word trigrams that also occur in [source]. */
export function trigramOverlap(source: string, text: string): number {
  const own = ngrams(words(text), 3);
  if (!own.length) return 0;
  const src = new Set(ngrams(words(source), 3));
  return round(own.filter((g) => src.has(g)).length / own.length);
}

const content = (s: string) => new Set(words(s).filter((w) => w.length >= 4));

export function jaccard(a: string, b: string): number {
  const x = content(a), y = content(b);
  const union = new Set([...x, ...y]).size;
  return union ? round([...x].filter((w) => y.has(w)).length / union) : 0;
}

export const round = (n: number) => Math.round(n * 1000) / 1000;

/** Recurrence / prior-dream wording (TR / EN / RU), on folded text. */
export const RECURRENCE =
  /(recurr|again|previous|earlier dream|before|keeps? (?:coming|returning|appearing)|repeated|tekrar|yine|önceki|daha önce|yeniden|снова|опять|повтор|прошл|раньше)/u;
export const COUNT_OR_DATE =
  /(\d|\bonce\b|\btwice\b|three times|several|many (?:times|dreams)|birkaç|iki kez|üç kez|çoğu zaman|несколько|дважды|трижды|много раз|last (?:week|month|year)|geçen (?:hafta|ay|yıl)|на прошлой)/u;
export const FATE = /(destin|fate|meant to|kader|alın yazısı|mukadder|судьб|предначертан|суждено)/u;
export const DIAGNOSIS = /(trauma|disorder|depress|diagnos|travma|bozukluk|depresyon|teşhis|травм|расстройств|депресс|диагноз)/u;
export const TAROT = /(tarot|таро)/u;

/** Folded words of [text] with at least five letters. */
export const longWords = (text: string) => new Set(words(text).filter((w) => w.length >= 5));
