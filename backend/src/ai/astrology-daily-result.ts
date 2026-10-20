/** Daily astrology writer result: strict schema + fail-closed prose checks. */
import { ErrorCode, fail } from '../errors.js';
import { asRecord } from './sanitize.js';
import { findDeterministicFuture } from './narrative-tarot-prose-quality.js';
import type { AstrologyWireSky } from './astrology-daily-contract.js';
import {
  ASTROLOGY_DAILY_LIMITS,
  ASTROLOGY_DAILY_RESULT_VERSION,
} from './astrology-daily-limits.js';

export const ASTROLOGY_DAILY_FIELDS = [
  'portrait',
  'overall',
  'love',
  'career',
  'money',
  'mood',
  'drive',
  'opportunity',
  'caution',
  'reflection',
] as const;

type Field = (typeof ASTROLOGY_DAILY_FIELDS)[number];

export type AstrologyDailyResult = { contractVersion: 1 } & Record<Field, string>;

function ceiling(field: Field): number {
  const L = ASTROLOGY_DAILY_LIMITS;
  if (field === 'portrait') return L.portrait;
  if (field === 'overall') return L.overall;
  if (field === 'reflection') return L.reflection;
  return L.lane;
}

export const ASTROLOGY_DAILY_RESULT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['contractVersion', ...ASTROLOGY_DAILY_FIELDS],
  properties: {
    contractVersion: { type: 'integer', enum: [ASTROLOGY_DAILY_RESULT_VERSION] },
    ...Object.fromEntries(
      ASTROLOGY_DAILY_FIELDS.map((f) => [
        f,
        { type: 'string', minLength: 1, maxLength: ceiling(f) },
      ]),
    ),
  },
} as const;

function bad(): never {
  fail(ErrorCode.invalidResponse);
}

/** Technique words the reader should never see. */
const TECHNIQUE =
  /\b(kare açı|üçgen açı|karşıtlık|kavuşum|altmışlık|transit|orb|derece|\d+\.\s*ev)/i;
const REFS = /\b(f\.\w+|hit\.\d|factRef|natalHouse|addressName)\b|```|\{/;
/** Without a birth time there is no rising sign or MC. Numbered houses are
 * already technique words; "ev" alone also means home, so it stays allowed. */
const TIME_ONLY = /(yükselen|ascendant|\bMC\b|tepe noktası)/i;
const GREETING = /(?<![\p{L}])(sevgili|merhaba)(?![\p{L}])/iu;
/** The reading must not describe its own structure. */
const META = /(bu alan|cephe|uyarı alanı|bulgu yok|doğuştan gelen)/i;
/** A past-reading claim needs supplied themes behind it. */
const PAST_READINGS = /(son okuma|önceki okuma|geçmiş okuma|okumalarında)/i;
/** A daily reading describes tendencies: no "you will meet/earn/receive". */
const FIXED_FUTURE = [
  /(?<![\p{L}])(kesinlikle|mutlaka)(?![\p{L}])/iu,
  /(?<![\p{L}])\p{L}+(?:ecek|acak)s[ıi]n(?:[ıi]z)?(?![\p{L}])/iu,
  /(?<![\p{L}])(para|teklif|haber|müjde|aşk|şans)\s+(?:\p{L}+\s+){0,2}(gelecek|çıkacak|kapanacak|kapıyı çalacak)(?![\p{L}])/iu,
];
/** Whole-word imperatives only: "harekete geçişin" is not an order. */
const ORDERS =
  /(?<![\p{L}])(dene|unutma|kendine izin ver|dikkat et|harekete geç|yapmalısın|etmelisin)(?![\p{L}])/iu;

function sentences(text: string): string[] {
  return text
    .split(/(?<=[.!?…])\s+/)
    .map((s) => s.trim().toLocaleLowerCase('tr').replace(/\s+/g, ' '))
    .filter((s) => s.length > 12);
}

export function parseAstrologyDailyResult(
  raw: string,
  sky: AstrologyWireSky,
): AstrologyDailyResult {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    bad();
  }
  const rec = asRecord(parsed);
  if (!rec) bad();
  const allowed = new Set(['contractVersion', ...ASTROLOGY_DAILY_FIELDS]);
  for (const k of Object.keys(rec)) if (!allowed.has(k)) bad();
  if (rec.contractVersion !== ASTROLOGY_DAILY_RESULT_VERSION) bad();

  const out = { contractVersion: 1 } as AstrologyDailyResult;
  let total = 0;
  for (const field of ASTROLOGY_DAILY_FIELDS) {
    const v = rec[field];
    if (typeof v !== 'string') bad();
    const text = v.trim();
    if (!text || text.length > ceiling(field)) bad();
    out[field] = text;
    total += text.length;
  }
  if (total > ASTROLOGY_DAILY_LIMITS.totalVisible) bad();
  assertProse(out, sky);
  return out;
}

function assertProse(r: AstrologyDailyResult, sky: AstrologyWireSky): void {
  if (astrologyDailyRefusal(r, sky) !== null) bad();
}

/** Why a written reading is refused, or null. Exported for QA diagnostics. */
export function astrologyDailyRefusal(
  r: Record<Field, string>,
  sky: AstrologyWireSky,
): string | null {
  const all = ASTROLOGY_DAILY_FIELDS.map((f) => r[f]).join('\n');
  const hit = (re: RegExp) => re.exec(all)?.[0];
  const checks: [string, string | undefined][] = [
    ['refs', hit(REFS)],
    ['technique', hit(TECHNIQUE)],
    ['greeting', hit(GREETING)],
    ['meta', hit(META)],
    ['orders', hit(ORDERS)],
    ['fixedFuture', findDeterministicFuture(all, 'tr')?.pattern],
    ['fixedFuture', FIXED_FUTURE.map(hit).find((m) => m)],
    ['timeOnly', sky.depth === 'dayOnly' ? hit(TIME_ONLY) : undefined],
    ['pastReadings', sky.themes.length === 0 ? hit(PAST_READINGS) : undefined],
  ];
  for (const [rule, match] of checks) if (match) return `${rule}: ${match}`;
  if (!r.reflection.trim().endsWith('?')) return 'reflection: not a question';

  // overall, love, career and money must not share a sentence.
  const seen = new Set<string>();
  for (const f of ['overall', 'love', 'career', 'money'] as const) {
    for (const s of sentences(r[f])) {
      if (seen.has(s)) return `repeat: ${s}`;
      seen.add(s);
    }
  }

  const name = sky.addressName;
  if (name) {
    const re = new RegExp(`(?<![\\p{L}])${escape(name)}(?![\\p{L}])`, 'gu');
    if ((all.match(re) ?? []).length > 2) return 'name: repeated';
  }
  return null;
}

function escape(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
