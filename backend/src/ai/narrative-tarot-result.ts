/** Phase 6D — Narrative result parse + evidence binding (no legacy fallback). */
import { ErrorCode, fail } from '../errors.js';
import { asRecord } from './sanitize.js';
import type { NarrativeWireInput } from './narrative-tarot-contract.js';
import {
  LIFE_AREA_KINDS,
  NARRATIVE_LIMITS,
  NARRATIVE_RESULT_CONTRACT_VERSION,
} from './narrative-tarot-limits.js';
import { assertNarrativeProseQuality } from './narrative-tarot-prose-quality.js';

export type NarrativeTarotResult = {
  contractVersion: 2;
  languageCode: 'tr' | 'en' | 'ru';
  summary: string;
  cardReadings: { cardId: string; positionKey: string; text: string }[];
  synthesis: string;
  relationshipInsights: {
    leftCardId: string;
    rightCardId: string;
    kind: string;
    text: string;
  }[];
  recurringCardInsights: { cardId: string; text: string }[];
  recurringThemeInsights: { themeIdOrLabel: string; text: string }[];
  memoryInsights: { memoryIndices: number[]; text: string }[];
  lifeAreas: { kind: string; text: string }[];
  advice: string;
  reflectionPrompt: string | null;
  dailyFocus: string | null;
  closingMessage: string;
};

const TOP = new Set([
  'contractVersion',
  'languageCode',
  'summary',
  'cardReadings',
  'synthesis',
  'relationshipInsights',
  'recurringCardInsights',
  'recurringThemeInsights',
  'memoryInsights',
  'lifeAreas',
  'advice',
  'reflectionPrompt',
  'dailyFocus',
  'closingMessage',
]);

function bad(): never {
  fail(ErrorCode.invalidResponse);
}

function exactKeys(obj: Record<string, unknown>, allowed: Set<string>): void {
  for (const k of Object.keys(obj)) {
    if (!allowed.has(k)) bad();
  }
  for (const k of allowed) {
    if (!(k in obj)) bad();
  }
}

function nonEmpty(v: unknown, max: number): string {
  if (typeof v !== 'string') bad();
  const t = v.trim();
  if (!t || v.length > max) bad();
  return v;
}

function nullable(v: unknown, max: number): string | null {
  if (v === null) return null;
  if (typeof v !== 'string') bad();
  const t = v.trim();
  if (!t || v.length > max) bad();
  return v;
}

export function parseNarrativeTarotResult(
  rawText: string,
  narrative: NarrativeWireInput,
): NarrativeTarotResult {
  let parsed: unknown;
  try {
    parsed = JSON.parse(rawText);
  } catch {
    bad();
  }
  const root = asRecord(parsed);
  if (!root) bad();
  exactKeys(root, TOP);
  if (root.contractVersion !== NARRATIVE_RESULT_CONTRACT_VERSION) bad();
  if (root.languageCode !== narrative.languageCode) bad();

  const summary = nonEmpty(root.summary, NARRATIVE_LIMITS.summary);
  const synthesis = nonEmpty(root.synthesis, NARRATIVE_LIMITS.synthesis);
  const advice = nonEmpty(root.advice, NARRATIVE_LIMITS.advice);
  const closingMessage = nonEmpty(
    root.closingMessage,
    NARRATIVE_LIMITS.closingMessage,
  );
  const reflectionPrompt = nullable(
    root.reflectionPrompt,
    NARRATIVE_LIMITS.reflectionPrompt,
  );
  const dailyFocus = nullable(root.dailyFocus, NARRATIVE_LIMITS.dailyFocus);

  const cardReadings = parseCardReadings(root.cardReadings, narrative);
  const relationshipInsights = parseRelationships(
    root.relationshipInsights,
    narrative,
  );
  const recurringCardInsights = parseRecurringCards(
    root.recurringCardInsights,
    narrative,
  );
  const recurringThemeInsights = parseThemes(
    root.recurringThemeInsights,
    narrative,
  );
  const memoryInsights = parseMemory(root.memoryInsights, narrative);
  const lifeAreas = parseLifeAreas(root.lifeAreas);

  const result: NarrativeTarotResult = {
    contractVersion: 2,
    languageCode: narrative.languageCode,
    summary,
    cardReadings,
    synthesis,
    relationshipInsights,
    recurringCardInsights,
    recurringThemeInsights,
    memoryInsights,
    lifeAreas,
    advice,
    reflectionPrompt,
    dailyFocus,
    closingMessage,
  };
  assertTotalChars(result);
  try {
    assertNarrativeProseQuality(result);
  } catch {
    bad();
  }
  return result;
}

function parseCardReadings(
  raw: unknown,
  narrative: NarrativeWireInput,
): NarrativeTarotResult['cardReadings'] {
  if (!Array.isArray(raw)) bad();
  if (raw.length !== narrative.cards.length) bad();
  const expected = new Map(
    narrative.cards.map((c) => [
      String(c.canonicalCardId),
      String(c.positionKey),
    ]),
  );
  const seen = new Set<string>();
  const out: NarrativeTarotResult['cardReadings'] = [];
  for (const item of raw) {
    const r = asRecord(item);
    if (!r) bad();
    exactKeys(r, new Set(['cardId', 'positionKey', 'text']));
    const cardId = nonEmpty(r.cardId, 64);
    const positionKey = nonEmpty(r.positionKey, 64);
    const text = nonEmpty(r.text, NARRATIVE_LIMITS.cardReading);
    if (!expected.has(cardId) || expected.get(cardId) !== positionKey) bad();
    if (seen.has(cardId)) bad();
    seen.add(cardId);
    out.push({ cardId, positionKey, text });
  }
  if (seen.size !== expected.size) bad();
  return out;
}

function parseRelationships(
  raw: unknown,
  narrative: NarrativeWireInput,
): NarrativeTarotResult['relationshipInsights'] {
  if (!Array.isArray(raw)) bad();
  const allowed = new Set(
    narrative.relationships.map(
      (r) => `${r.leftCardId}|${r.rightCardId}|${r.kind}`,
    ),
  );
  const seen = new Set<string>();
  const out: NarrativeTarotResult['relationshipInsights'] = [];
  for (const item of raw) {
    const r = asRecord(item);
    if (!r) bad();
    exactKeys(r, new Set(['leftCardId', 'rightCardId', 'kind', 'text']));
    const leftCardId = nonEmpty(r.leftCardId, 64);
    const rightCardId = nonEmpty(r.rightCardId, 64);
    const kind = nonEmpty(r.kind, 64);
    const text = nonEmpty(r.text, NARRATIVE_LIMITS.relationshipInsight);
    const key = `${leftCardId}|${rightCardId}|${kind}`;
    if (!allowed.has(key) || seen.has(key)) bad();
    seen.add(key);
    out.push({ leftCardId, rightCardId, kind, text });
  }
  if (narrative.relationships.length === 0 && out.length > 0) bad();
  return out;
}

function parseRecurringCards(
  raw: unknown,
  narrative: NarrativeWireInput,
): NarrativeTarotResult['recurringCardInsights'] {
  if (!Array.isArray(raw)) bad();
  if (narrative.recurringCards.length === 0 && raw.length > 0) bad();
  const allowed = new Set(
    narrative.recurringCards.map((c) => String(c.canonicalCardId)),
  );
  const seen = new Set<string>();
  const out: NarrativeTarotResult['recurringCardInsights'] = [];
  for (const item of raw) {
    const r = asRecord(item);
    if (!r) bad();
    exactKeys(r, new Set(['cardId', 'text']));
    const cardId = nonEmpty(r.cardId, 64);
    const text = nonEmpty(r.text, NARRATIVE_LIMITS.recurringCardInsight);
    if (!allowed.has(cardId) || seen.has(cardId)) bad();
    seen.add(cardId);
    out.push({ cardId, text });
  }
  return out;
}

function parseThemes(
  raw: unknown,
  narrative: NarrativeWireInput,
): NarrativeTarotResult['recurringThemeInsights'] {
  if (!Array.isArray(raw)) bad();
  if (narrative.recurringThemes.length === 0 && raw.length > 0) bad();
  const allowed = new Set(
    narrative.recurringThemes.map((t) => String(t.themeIdOrLabel)),
  );
  const seen = new Set<string>();
  const out: NarrativeTarotResult['recurringThemeInsights'] = [];
  for (const item of raw) {
    const r = asRecord(item);
    if (!r) bad();
    exactKeys(r, new Set(['themeIdOrLabel', 'text']));
    const themeIdOrLabel = nonEmpty(r.themeIdOrLabel, 120);
    const text = nonEmpty(r.text, NARRATIVE_LIMITS.recurringThemeInsight);
    if (!allowed.has(themeIdOrLabel) || seen.has(themeIdOrLabel)) bad();
    seen.add(themeIdOrLabel);
    out.push({ themeIdOrLabel, text });
  }
  return out;
}

function parseMemory(
  raw: unknown,
  narrative: NarrativeWireInput,
): NarrativeTarotResult['memoryInsights'] {
  if (!Array.isArray(raw)) bad();
  const mem = narrative.memory;
  const included = mem.included === true;
  const entries = Array.isArray(mem.entries) ? mem.entries : [];
  if (!included && raw.length > 0) bad();
  const globalSeen = new Set<number>();
  const out: NarrativeTarotResult['memoryInsights'] = [];
  for (const item of raw) {
    const r = asRecord(item);
    if (!r) bad();
    exactKeys(r, new Set(['memoryIndices', 'text']));
    if (!Array.isArray(r.memoryIndices) || r.memoryIndices.length === 0) bad();
    const indices: number[] = [];
    const localSeen = new Set<number>();
    for (const rawIdx of r.memoryIndices) {
      if (typeof rawIdx !== 'number' || !Number.isInteger(rawIdx)) bad();
      if (rawIdx < 0 || rawIdx >= entries.length) bad();
      if (localSeen.has(rawIdx) || globalSeen.has(rawIdx)) bad();
      localSeen.add(rawIdx);
      globalSeen.add(rawIdx);
      indices.push(rawIdx);
    }
    for (let i = 1; i < indices.length; i++) {
      if (indices[i]! <= indices[i - 1]!) bad();
    }
    out.push({
      memoryIndices: indices,
      text: nonEmpty(r.text, NARRATIVE_LIMITS.memoryInsight),
    });
  }
  return out;
}

function parseLifeAreas(
  raw: unknown,
): NarrativeTarotResult['lifeAreas'] {
  if (!Array.isArray(raw)) bad();
  if (raw.length > NARRATIVE_LIMITS.maxLifeAreas) bad();
  const allowed = new Set<string>(LIFE_AREA_KINDS);
  const seen = new Set<string>();
  const out: NarrativeTarotResult['lifeAreas'] = [];
  for (const item of raw) {
    const r = asRecord(item);
    if (!r) bad();
    exactKeys(r, new Set(['kind', 'text']));
    const kind = nonEmpty(r.kind, 32);
    if (!allowed.has(kind) || seen.has(kind)) bad();
    seen.add(kind);
    out.push({ kind, text: nonEmpty(r.text, NARRATIVE_LIMITS.lifeArea) });
  }
  return out;
}

function assertTotalChars(result: NarrativeTarotResult): void {
  const parts = [
    result.summary,
    result.synthesis,
    result.advice,
    result.closingMessage,
    result.reflectionPrompt ?? '',
    result.dailyFocus ?? '',
    ...result.cardReadings.map((c) => c.text),
    ...result.relationshipInsights.map((r) => r.text),
    ...result.recurringCardInsights.map((r) => r.text),
    ...result.recurringThemeInsights.map((r) => r.text),
    ...result.memoryInsights.map((m) => m.text),
    ...result.lifeAreas.map((l) => l.text),
  ];
  const total = parts.reduce((n, s) => n + s.length, 0);
  if (total > NARRATIVE_LIMITS.totalVisible) bad();
}
