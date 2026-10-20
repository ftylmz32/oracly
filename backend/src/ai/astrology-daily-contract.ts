/** Strict wire validation for the daily astrology writer (`astrology_daily`). */
import { ErrorCode, fail } from '../errors.js';
import { asRecord } from './sanitize.js';
import { canonicalYildiznameAddressName } from './narrative-yildizname-contract.js';
import {
  ASTROLOGY_ASPECTS,
  ASTROLOGY_DAILY_CONTRACT_VERSION,
  ASTROLOGY_DAILY_LIMITS,
  ASTROLOGY_DAILY_MODE,
  ASTROLOGY_DEPTHS,
  ASTROLOGY_LANES,
  ASTROLOGY_NATAL_POINTS,
  ASTROLOGY_SIGNS,
  ASTROLOGY_SPANS,
  ASTROLOGY_STRENGTHS,
  ASTROLOGY_TONES,
  ASTROLOGY_TRANSIT_POINTS,
} from './astrology-daily-limits.js';

export type AstrologyLanguage = 'tr';
export type AstrologyDepth = (typeof ASTROLOGY_DEPTHS)[number];
export type AstrologyLane = (typeof ASTROLOGY_LANES)[number];

export type AstrologyNatalPoint = { point: string; sign: string; house?: number };
export type AstrologyTransitPoint = { point: string; sign: string; natalHouse?: number };
export type AstrologyFinding = {
  lane: AstrologyLane;
  transit: string;
  natal: string;
  aspect: string;
  tone: string;
  strength: string;
  span: string;
};

export type AstrologyWireSky = {
  day: string;
  depth: AstrologyDepth;
  natal: AstrologyNatalPoint[];
  transits: AstrologyTransitPoint[];
  findings: AstrologyFinding[];
  themes: string[];
  addressName?: string;
};

export type AstrologyDailyValidated = {
  operation: 'astrology_daily';
  mode: 'sky_daily_v1';
  contractVersion: 1;
  language: AstrologyLanguage;
  sky: AstrologyWireSky;
};

const TOP_KEYS = new Set(['mode', 'contractVersion', 'language', 'sky']);
const SKY_KEYS = new Set([
  'day',
  'depth',
  'natal',
  'transits',
  'findings',
  'themes',
  'addressName',
]);

/** Identity, birth and location data never travel on this wire. */
const FORBIDDEN = new Set([
  'ownerId',
  'userId',
  'uid',
  'birthDate',
  'birthTime',
  'birthPlace',
  'latitude',
  'longitude',
  'timezoneId',
  'longitudeDeg',
  'degree',
  'degreeWithinSign',
  'orb',
]);

const SIGNS = new Set<string>(ASTROLOGY_SIGNS);
const NATAL = new Set<string>(ASTROLOGY_NATAL_POINTS);
const TRANSIT = new Set<string>(ASTROLOGY_TRANSIT_POINTS);
const ASPECTS = new Set<string>(ASTROLOGY_ASPECTS);
const TONES = new Set<string>(ASTROLOGY_TONES);
const STRENGTHS = new Set<string>(ASTROLOGY_STRENGTHS);
const SPANS = new Set<string>(ASTROLOGY_SPANS);
const LANES = new Set<string>(ASTROLOGY_LANES);
const DAY = /^\d{4}-\d{2}-\d{2}$/;

const TONE_OF: Record<string, string> = {
  conjunction: 'fusion',
  sextile: 'flow',
  trine: 'flow',
  square: 'friction',
  opposition: 'friction',
};

function reject(): never {
  fail(ErrorCode.invalidRequest);
}

function exactKeys(obj: Record<string, unknown>, allowed: Set<string>): void {
  for (const k of Object.keys(obj)) {
    if (!allowed.has(k) || FORBIDDEN.has(k)) reject();
  }
}

function scanForbidden(value: unknown): void {
  if (Array.isArray(value)) {
    for (const v of value) scanForbidden(v);
    return;
  }
  const rec = asRecord(value);
  if (!rec) return;
  for (const k of Object.keys(rec)) {
    if (FORBIDDEN.has(k)) reject();
    scanForbidden(rec[k]);
  }
}

function member(v: unknown, set: Set<string>): string {
  if (typeof v !== 'string' || !set.has(v)) reject();
  return v;
}

function house(v: unknown): number {
  if (typeof v !== 'number' || !Number.isInteger(v) || v < 1 || v > 12) reject();
  return v;
}

function dayWithinSkew(day: string, now: Date): void {
  if (!DAY.test(day)) reject();
  const at = Date.parse(`${day}T00:00:00Z`);
  if (!Number.isFinite(at) || new Date(at).toISOString().slice(0, 10) !== day) {
    reject();
  }
  const today = Date.parse(`${now.toISOString().slice(0, 10)}T00:00:00Z`);
  const skew = Math.abs(at - today) / 86_400_000;
  if (skew > ASTROLOGY_DAILY_LIMITS.maxDaySkew) reject();
}

export function validateAstrologyDailyPayload(
  payload: Record<string, unknown>,
  now: Date = new Date(),
): AstrologyDailyValidated {
  exactKeys(payload, TOP_KEYS);
  if (payload.mode !== ASTROLOGY_DAILY_MODE) reject();
  if (payload.contractVersion !== ASTROLOGY_DAILY_CONTRACT_VERSION) reject();
  // Turkish only for now; other locales stay on general sign copy.
  if (payload.language !== 'tr') reject();
  const skyRec = asRecord(payload.sky);
  if (!skyRec) reject();
  scanForbidden(skyRec);
  exactKeys(skyRec, SKY_KEYS);
  const sky = parseSky(skyRec, now);
  if (JSON.stringify(sky).length > ASTROLOGY_DAILY_LIMITS.maxNarrativeJsonChars) {
    reject();
  }
  return {
    operation: 'astrology_daily',
    mode: 'sky_daily_v1',
    contractVersion: 1,
    language: 'tr',
    sky,
  };
}

function parseSky(s: Record<string, unknown>, now: Date): AstrologyWireSky {
  if (typeof s.day !== 'string') reject();
  dayWithinSkew(s.day, now);
  const depth = member(s.depth, new Set(ASTROLOGY_DEPTHS)) as AstrologyDepth;
  if (!Array.isArray(s.natal) || !Array.isArray(s.transits)) reject();
  if (!Array.isArray(s.findings) || !Array.isArray(s.themes)) reject();

  const natal = s.natal.map((raw) => parseNatal(raw, depth));
  const natalPoints = new Set(natal.map((n) => n.point));
  if (natalPoints.size !== natal.length) reject();
  for (const p of ['sun', 'mercury', 'venus', 'mars', 'jupiter', 'saturn']) {
    if (!natalPoints.has(p)) reject();
  }
  if (depth === 'full') {
    for (const p of ASTROLOGY_NATAL_POINTS) if (!natalPoints.has(p)) reject();
  } else if (natalPoints.has('ascendant') || natalPoints.has('midheaven')) {
    // Without a birth time there is no rising sign or MC to speak about.
    reject();
  }

  const transits = s.transits.map((raw) => parseTransit(raw, depth));
  const transitPoints = new Set(transits.map((t) => t.point));
  if (transitPoints.size !== ASTROLOGY_TRANSIT_POINTS.length) reject();
  if (transits.length !== ASTROLOGY_TRANSIT_POINTS.length) reject();

  const findings = s.findings.map((raw) => parseFinding(raw, natalPoints));
  const lanes = new Set(findings.map((f) => f.lane));
  if (lanes.size !== findings.length) reject();

  if (s.themes.length > ASTROLOGY_DAILY_LIMITS.maxThemes) reject();
  const themes = s.themes.map((t) => {
    if (typeof t !== 'string') reject();
    const v = t.trim();
    if (!v || v.length > ASTROLOGY_DAILY_LIMITS.maxThemeChars || v !== t) reject();
    return v;
  });

  let addressName: string | undefined;
  if ('addressName' in s) {
    const name = canonicalYildiznameAddressName(s.addressName);
    if (name === null) reject();
    addressName = name;
  }

  return {
    day: s.day,
    depth,
    natal,
    transits,
    findings,
    themes,
    ...(addressName ? { addressName } : {}),
  };
}

function parseNatal(raw: unknown, depth: AstrologyDepth): AstrologyNatalPoint {
  const n = asRecord(raw);
  if (!n) reject();
  exactKeys(n, new Set(['point', 'sign', 'house']));
  const point = member(n.point, NATAL);
  const sign = member(n.sign, SIGNS);
  if (depth === 'full') return { point, sign, house: house(n.house) };
  if ('house' in n) reject();
  return { point, sign };
}

function parseTransit(raw: unknown, depth: AstrologyDepth): AstrologyTransitPoint {
  const t = asRecord(raw);
  if (!t) reject();
  exactKeys(t, new Set(['point', 'sign', 'natalHouse']));
  const point = member(t.point, TRANSIT);
  const sign = member(t.sign, SIGNS);
  if (depth === 'full') return { point, sign, natalHouse: house(t.natalHouse) };
  if ('natalHouse' in t) reject();
  return { point, sign };
}

function parseFinding(raw: unknown, natalPoints: Set<string>): AstrologyFinding {
  const f = asRecord(raw);
  if (!f) reject();
  exactKeys(
    f,
    new Set(['lane', 'transit', 'natal', 'aspect', 'tone', 'strength', 'span']),
  );
  const lane = member(f.lane, LANES) as AstrologyLane;
  const transit = member(f.transit, TRANSIT);
  const natal = member(f.natal, NATAL);
  if (!natalPoints.has(natal)) reject();
  const aspect = member(f.aspect, ASPECTS);
  const tone = member(f.tone, TONES);
  if (TONE_OF[aspect] !== tone) reject();
  return {
    lane,
    transit,
    natal,
    aspect,
    tone,
    strength: member(f.strength, STRENGTHS),
    span: member(f.span, SPANS),
  };
}
