/** Phase 6D.1 — shared field validators for Narrative wire contract. */
import {
  NARRATIVE_LIMITS,
  NARRATIVE_MEMORY_EPISTEMICS,
  NARRATIVE_MEMORY_KINDS,
  NARRATIVE_MEMORY_SOURCE_TYPES,
  NARRATIVE_OCCURRENCE_SPREAD_IDS,
  NARRATIVE_RELATIONSHIP_KINDS,
  NARRATIVE_SPREAD_IDS,
  NARRATIVE_TRANSFORMS,
  asEnumSet,
} from './narrative-tarot-limits.js';

export type RejectFn = () => never;

const SPREADS = asEnumSet(NARRATIVE_SPREAD_IDS);
const OCC_SPREADS = asEnumSet(NARRATIVE_OCCURRENCE_SPREAD_IDS);
const REL_KINDS = asEnumSet(NARRATIVE_RELATIONSHIP_KINDS);
const TRANSFORMS = asEnumSet(NARRATIVE_TRANSFORMS);
const MEM_KINDS = asEnumSet(NARRATIVE_MEMORY_KINDS);
const MEM_SOURCES = asEnumSet(NARRATIVE_MEMORY_SOURCE_TYPES);
const MEM_EPI = asEnumSet(NARRATIVE_MEMORY_EPISTEMICS);

export function isFiniteUnit(n: unknown): n is number {
  return typeof n === 'number' && Number.isFinite(n) && n >= 0 && n <= 1;
}

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

export function optionalString(
  reject: RejectFn,
  v: unknown,
  max: number,
): string | null {
  if (v === undefined || v === null) return null;
  return requireString(reject, v, max, true);
}

export function requireEnum(
  reject: RejectFn,
  v: unknown,
  allowed: Set<string>,
): string {
  if (typeof v !== 'string' || !allowed.has(v)) reject();
  return v;
}

export function requireUtcZ(reject: RejectFn, v: unknown): string {
  const s = requireString(reject, v, NARRATIVE_LIMITS.maxUtcChars, true);
  if (!s.endsWith('Z')) reject();
  const t = Date.parse(s);
  if (!Number.isFinite(t)) reject();
  return s;
}

export function optionalUtcZ(reject: RejectFn, v: unknown): string | null {
  if (v === undefined || v === null) return null;
  return requireUtcZ(reject, v);
}

export function requireTokenList(
  reject: RejectFn,
  v: unknown,
  maxItems: number,
  maxItem: number,
): string[] {
  if (!Array.isArray(v)) reject();
  if (v.length > maxItems) reject();
  const seen = new Set<string>();
  const out: string[] = [];
  for (const item of v) {
    const s = requireString(reject, item, maxItem, true);
    if (seen.has(s)) reject();
    seen.add(s);
    out.push(s);
  }
  return out;
}

export function requireTransforms(reject: RejectFn, v: unknown): string[] {
  const list = requireTokenList(
    reject,
    v,
    NARRATIVE_LIMITS.maxTransformItems,
    64,
  );
  for (const t of list) {
    if (!TRANSFORMS.has(t)) reject();
  }
  return list;
}

export function requireSpreadId(reject: RejectFn, v: unknown): string {
  const s = requireString(reject, v, NARRATIVE_LIMITS.maxSpreadIdChars, true);
  if (!SPREADS.has(s)) reject();
  return s;
}

export function requireOccurrenceSpreadId(reject: RejectFn, v: unknown): string {
  const s = requireString(reject, v, NARRATIVE_LIMITS.maxSpreadIdChars, true);
  if (!OCC_SPREADS.has(s)) reject();
  return s;
}

export function requireRelKind(reject: RejectFn, v: unknown): string {
  const s = requireString(
    reject,
    v,
    NARRATIVE_LIMITS.maxRelationshipKindChars,
    true,
  );
  if (!REL_KINDS.has(s)) reject();
  return s;
}

export function requireMemKind(reject: RejectFn, v: unknown): string {
  return requireEnum(reject, v, MEM_KINDS);
}

export function optionalMemSource(reject: RejectFn, v: unknown): string | null {
  if (v === undefined || v === null) return null;
  const s = requireString(
    reject,
    v,
    NARRATIVE_LIMITS.maxMemorySourceTypeChars,
    true,
  );
  if (!MEM_SOURCES.has(s)) reject();
  return s;
}

export function optionalMemEpistemic(
  reject: RejectFn,
  v: unknown,
): string | null {
  if (v === undefined || v === null) return null;
  return requireEnum(reject, v, MEM_EPI);
}
