/**
 * Dream Phase 4A — prior-Dream history evidence.
 *
 * The client computes it from the owner's saved Dreams; the server trusts
 * only its shape: known kinds, canonical keys, short plain labels, a
 * level that matches the count, at most five unique items. No prior
 * narratives, ids, dates or provider prose are accepted or rendered.
 */
import { ErrorCode, fail } from '../errors.js';
import type { AppLanguage } from './app-language.js';
import { asRecord } from './sanitize.js';

export const DREAM_HISTORY_KINDS = ['symbol', 'location', 'relationship', 'emotion', 'entry'] as const;
export type DreamHistoryKind = (typeof DREAM_HISTORY_KINDS)[number];
export type DreamHistoryLevel = 'seen_before' | 'recurring';

export type DreamHistoryItem = {
  kind: DreamHistoryKind;
  key: string;
  label: string;
  level: DreamHistoryLevel;
  priorCount: number;
};

export const DREAM_HISTORY_MAX_ITEMS = 5;
/** Mirrors the client scan window (`DreamHistoryBuilder.maxScanned`). */
export const DREAM_HISTORY_MAX_PRIOR = 40;

const FIELDS = ['kind', 'key', 'label', 'level', 'priorCount'];
const KEY_BODY = /^[\p{Ll}\p{Lo}\p{M}\p{N}][\p{Ll}\p{Lo}\p{M}\p{N}' _-]{0,47}$/u;
const LABEL = /^[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N}' -]{0,47}$/u;
const IDS: Partial<Record<DreamHistoryKind, Set<string>>> = {
  emotion: new Set(['peaceful', 'anxious', 'curious', 'fearful', 'joyful', 'melancholic', 'surreal', 'vivid']),
  entry: new Set(['nightmare', 'clear', 'symbols']),
};

/** Validated history, or undefined when absent/empty. Malformed → invalid_request. */
export function parseDreamHistory(raw: unknown): DreamHistoryItem[] | undefined {
  if (raw === undefined || raw === null) return undefined;
  if (!Array.isArray(raw) || raw.length > DREAM_HISTORY_MAX_ITEMS) fail(ErrorCode.invalidRequest);
  const seen = new Set<string>();
  const items = raw.map((entry) => {
    const item = parseItem(entry);
    if (seen.has(item.key)) fail(ErrorCode.invalidRequest);
    seen.add(item.key);
    return item;
  });
  return items.length ? items : undefined;
}

function parseItem(entry: unknown): DreamHistoryItem {
  const record = asRecord(entry);
  if (!record) fail(ErrorCode.invalidRequest);
  const keys = Object.keys(record);
  if (keys.length !== FIELDS.length || !keys.every((k) => FIELDS.includes(k))) fail(ErrorCode.invalidRequest);
  const { kind, key, label, level, priorCount } = record;
  if (typeof kind !== 'string' || !(DREAM_HISTORY_KINDS as readonly string[]).includes(kind)) {
    fail(ErrorCode.invalidRequest);
  }
  const typed = kind as DreamHistoryKind;
  if (typeof key !== 'string' || !key.startsWith(`${typed}:`)) fail(ErrorCode.invalidRequest);
  const body = key.slice(typed.length + 1);
  if (!KEY_BODY.test(body) || (IDS[typed] && !IDS[typed]!.has(body))) fail(ErrorCode.invalidRequest);
  if (typeof label !== 'string' || !LABEL.test(label)) fail(ErrorCode.invalidRequest);
  if (
    typeof priorCount !== 'number' ||
    !Number.isInteger(priorCount) ||
    priorCount < 1 ||
    priorCount > DREAM_HISTORY_MAX_PRIOR
  ) {
    fail(ErrorCode.invalidRequest);
  }
  const expected: DreamHistoryLevel = priorCount >= 2 ? 'recurring' : 'seen_before';
  if (level !== expected) fail(ErrorCode.invalidRequest);
  return { kind: typed, key, label, level: expected, priorCount };
}

type HistoryCopy = {
  heading: string;
  kinds: Record<DreamHistoryKind, string>;
  levels: Record<DreamHistoryLevel, string>;
  count: (n: number) => string;
};

const COPY: Record<AppLanguage, HistoryCopy> = {
  tr: {
    heading: 'Önceki rüya örüntüleri (kayıtlı rüyalardan sayıldı; yalnızca bu rüyayla doğrudan ilişkiliyse kullan):',
    kinds: { symbol: 'sembol', location: 'mekân', relationship: 'kişi', emotion: 'duygu', entry: 'giriş işareti' },
    levels: { recurring: 'tekrar eden', seen_before: 'daha önce görülmüş' },
    count: (n) => `önceki ${n} rüyada da vardı`,
  },
  en: {
    heading: 'Prior dream patterns (counted from saved dreams; use only if directly related to this dream):',
    kinds: { symbol: 'symbol', location: 'place', relationship: 'person', emotion: 'feeling', entry: 'entry mark' },
    levels: { recurring: 'recurring', seen_before: 'seen before' },
    count: (n) => (n === 1 ? 'also in 1 earlier dream' : `also in ${n} earlier dreams`),
  },
  ru: {
    heading: 'Повторяющиеся элементы прошлых снов (подсчитано по сохранённым снам; используй, только если это прямо связано с этим сном):',
    kinds: { symbol: 'символ', location: 'место', relationship: 'человек', emotion: 'чувство', entry: 'отметка' },
    levels: { recurring: 'повторяется', seen_before: 'встречалось раньше' },
    count: (n) => (n === 1 ? 'также в одном прошлом сне' : `также в прошлых снах: ${n}`),
  },
};

/** The prompt block for [items] in [language]; empty when there is none. */
export function dreamHistorySection(items: DreamHistoryItem[] | undefined, language: AppLanguage): string {
  if (!items?.length) return '';
  const copy = COPY[language];
  const lines = items.map(
    (i) => `- ${i.label} (${copy.kinds[i.kind]}): ${copy.count(i.priorCount)} — ${copy.levels[i.level]}`,
  );
  return `${copy.heading}\n${lines.join('\n')}`;
}

/** Canonical identity lines, in prompt order. */
export function dreamHistoryIdentity(items: DreamHistoryItem[] | undefined): string[] {
  const norm = (s: string) => s.trim().toLowerCase().replace(/\s+/g, ' ');
  return (items ?? []).map((i) => [i.kind, i.key, norm(i.label), i.level, i.priorCount].join('|'));
}
