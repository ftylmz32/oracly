/** Phase 5 — shared field helpers for Yıldızname wire contract. */
import {
  YILDIZNAME_ASPECT_TYPES,
  YILDIZNAME_BODIES,
  YILDIZNAME_CERTAINTIES,
  YILDIZNAME_LIMITS,
  YILDIZNAME_SIGNS,
  asEnumSet,
} from './narrative-yildizname-limits.js';

export type RejectFn = () => never;

const BODIES = asEnumSet(YILDIZNAME_BODIES);
const SIGNS = asEnumSet(YILDIZNAME_SIGNS);
const CERTS = asEnumSet(YILDIZNAME_CERTAINTIES);
const ASPECTS = asEnumSet(YILDIZNAME_ASPECT_TYPES);

export function requireString(
  reject: RejectFn,
  v: unknown,
  max: number,
  nonEmpty: boolean,
): string {
  if (typeof v !== 'string') reject();
  if (v.length > max) reject();
  if (nonEmpty && v.trim().length === 0) reject();
  return v;
}

export function requireEnum(
  reject: RejectFn,
  v: unknown,
  allowed: Set<string>,
): string {
  if (typeof v !== 'string' || !allowed.has(v)) reject();
  return v;
}

export function requireBody(reject: RejectFn, v: unknown): string {
  return requireEnum(reject, v, BODIES);
}

export function requireSign(reject: RejectFn, v: unknown): string {
  return requireEnum(reject, v, SIGNS);
}

export function requireCertainty(reject: RejectFn, v: unknown): string {
  return requireEnum(reject, v, CERTS);
}

export function requireAspectType(reject: RejectFn, v: unknown): string {
  return requireEnum(reject, v, ASPECTS);
}

export function requireHouseNumber(reject: RejectFn, v: unknown): number {
  if (typeof v !== 'number' || !Number.isInteger(v) || v < 1 || v > 12) {
    reject();
  }
  return v;
}

export function requireDegreeWithinSign(reject: RejectFn, v: unknown): number {
  if (typeof v !== 'number' || !Number.isFinite(v) || v < 0 || v >= 30) {
    reject();
  }
  return v;
}

export function requireOrb(reject: RejectFn, v: unknown): number {
  if (
    typeof v !== 'number' ||
    !Number.isFinite(v) ||
    v < 0 ||
    v > YILDIZNAME_LIMITS.maxOrb
  ) {
    reject();
  }
  return v;
}

const PLACEMENT_REF = /^placement\.(sun|moon|mercury|venus|mars|jupiter|saturn|uranus|neptune|pluto)$/;
const ANGLE_REF = /^angle\.(ascendant|midheaven)$/;
const HOUSE_REF = /^house\.([1-9]|1[0-2])$/;
const ASPECT_REF =
  /^aspect\.(sun|moon|mercury|venus|mars|jupiter|saturn|uranus|neptune|pluto)\.(sun|moon|mercury|venus|mars|jupiter|saturn|uranus|neptune|pluto)\.(conjunction|sextile|square|trine|opposition)$/;
const BALANCE_REF = /^balance\.(elements|modalities)$/;
const THEME_REF = /^theme\.[a-z0-9_]{1,48}$/;

export function requirePlacementFactRef(reject: RejectFn, v: unknown): string {
  const s = requireString(reject, v, YILDIZNAME_LIMITS.maxFactRefChars, true);
  if (!PLACEMENT_REF.test(s)) reject();
  return s;
}

export function requireAngleFactRef(reject: RejectFn, v: unknown): string {
  const s = requireString(reject, v, YILDIZNAME_LIMITS.maxFactRefChars, true);
  if (!ANGLE_REF.test(s)) reject();
  return s;
}

export function requireHouseFactRef(reject: RejectFn, v: unknown): string {
  const s = requireString(reject, v, YILDIZNAME_LIMITS.maxFactRefChars, true);
  if (!HOUSE_REF.test(s)) reject();
  return s;
}

export function requireAspectFactRef(reject: RejectFn, v: unknown): string {
  const s = requireString(reject, v, YILDIZNAME_LIMITS.maxFactRefChars, true);
  if (!ASPECT_REF.test(s)) reject();
  return s;
}

export function requireBalanceFactRef(reject: RejectFn, v: unknown): string {
  const s = requireString(reject, v, YILDIZNAME_LIMITS.maxFactRefChars, true);
  if (!BALANCE_REF.test(s)) reject();
  return s;
}

export function requireThemeRef(reject: RejectFn, v: unknown): string {
  const s = requireString(reject, v, YILDIZNAME_LIMITS.maxThemeRefChars, true);
  if (!THEME_REF.test(s)) reject();
  return s;
}

export function isKnownFactRefPattern(s: string): boolean {
  return (
    PLACEMENT_REF.test(s) ||
    ANGLE_REF.test(s) ||
    HOUSE_REF.test(s) ||
    ASPECT_REF.test(s) ||
    BALANCE_REF.test(s)
  );
}
