/** Phase 6D — strict Narrative V2 request wire validation (fail-closed). */
import { ErrorCode, fail } from '../errors.js';
import { asRecord } from './sanitize.js';
import {
  NARRATIVE_CONTRACT_VERSION,
  NARRATIVE_LIMITS,
  NARRATIVE_MODE,
  NARRATIVE_POLICY_RULES,
  NARRATIVE_POLICY_VERSION,
  NARRATIVE_SERIALIZER_VERSION,
  NARRATIVE_TAROT_VERSION,
} from './narrative-tarot-limits.js';

export type NarrativeWireLanguage = 'tr' | 'en' | 'ru';

export type NarrativeWireInput = {
  narrativeTarotVersion: number;
  serializerVersion: number;
  languageCode: NarrativeWireLanguage;
  question: Record<string, unknown>;
  spread: Record<string, unknown>;
  cards: Record<string, unknown>[];
  relationships: Record<string, unknown>[];
  recurringCards: Record<string, unknown>[];
  recurringThemes: Record<string, unknown>[];
  memory: Record<string, unknown>;
  policy: { version: string; rules: string[] };
};

export type NarrativeTarotValidated = {
  operation: 'tarot_reading';
  mode: 'narrative_v2';
  contractVersion: 1;
  language: NarrativeWireLanguage;
  narrative: NarrativeWireInput;
};

const TOP_KEYS = new Set(['mode', 'contractVersion', 'language', 'narrative']);
const NARRATIVE_KEYS = new Set([
  'narrativeTarotVersion',
  'serializerVersion',
  'languageCode',
  'question',
  'spread',
  'cards',
  'relationships',
  'recurringCards',
  'recurringThemes',
  'memory',
  'policy',
]);
const FORBIDDEN = new Set([
  'ownerId',
  'sessionId',
  'readingId',
  'evidenceId',
  'sourceId',
  'supportingReadingIds',
  'evidenceRef',
  'ritualCardId',
  'imageAsset',
  'provenance',
  'note',
]);

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

function isFiniteUnit(n: unknown): n is number {
  return typeof n === 'number' && Number.isFinite(n) && n >= 0 && n <= 1;
}

function nonBlank(v: unknown): v is string {
  return typeof v === 'string' && v.trim().length > 0;
}

function exactLang(v: unknown): NarrativeWireLanguage | null {
  return v === 'tr' || v === 'en' || v === 'ru' ? v : null;
}

export function validateNarrativeTarotPayload(
  payload: Record<string, unknown>,
): NarrativeTarotValidated {
  exactKeys(payload, TOP_KEYS);
  if (payload.mode !== NARRATIVE_MODE) reject();
  if (payload.contractVersion !== NARRATIVE_CONTRACT_VERSION) reject();
  const language = exactLang(payload.language);
  if (!language) reject();
  const narrativeRec = asRecord(payload.narrative);
  if (!narrativeRec) reject();
  scanForbidden(narrativeRec);
  exactKeys(narrativeRec, NARRATIVE_KEYS);
  const narrative = parseNarrative(narrativeRec, language);
  return {
    operation: 'tarot_reading',
    mode: 'narrative_v2',
    contractVersion: 1,
    language,
    narrative,
  };
}

function parseNarrative(
  n: Record<string, unknown>,
  language: NarrativeWireLanguage,
): NarrativeWireInput {
  if (n.narrativeTarotVersion !== NARRATIVE_TAROT_VERSION) reject();
  if (n.serializerVersion !== NARRATIVE_SERIALIZER_VERSION) reject();
  if (n.languageCode !== language) reject();
  const question = asRecord(n.question);
  const spread = asRecord(n.spread);
  const memory = asRecord(n.memory);
  const policy = asRecord(n.policy);
  if (!question || !spread || !memory || !policy) reject();
  exactKeys(question, new Set(['text', 'topic', 'kind', 'hasRealQuestion']));
  exactKeys(
    spread,
    new Set([
      'spreadId',
      'cardCount',
      'geometryHook',
      'lengthBand',
      'interpretationOrder',
      'positions',
    ]),
  );
  exactKeys(memory, new Set(['included', 'priorReadingCount', 'entries']));
  exactKeys(policy, new Set(['version', 'rules']));
  if (policy.version !== NARRATIVE_POLICY_VERSION) reject();
  if (!Array.isArray(policy.rules)) reject();
  if (policy.rules.length !== NARRATIVE_POLICY_RULES.length) reject();
  for (let i = 0; i < NARRATIVE_POLICY_RULES.length; i++) {
    if (policy.rules[i] !== NARRATIVE_POLICY_RULES[i]) reject();
  }
  if (!Array.isArray(n.cards) || !Array.isArray(n.relationships)) reject();
  if (!Array.isArray(n.recurringCards) || !Array.isArray(n.recurringThemes)) {
    reject();
  }
  const cards = n.cards.map(parseCard);
  const relationships = n.relationships.map(parseRelationship);
  const recurringCards = n.recurringCards.map(parseRecurringCard);
  const recurringThemes = n.recurringThemes.map(parseTheme);
  validateSpreadAndCards(spread, cards);
  validateRelationships(cards, relationships);
  validateRecurrence(cards, recurringCards, recurringThemes);
  validateMemory(memory);
  return {
    narrativeTarotVersion: NARRATIVE_TAROT_VERSION,
    serializerVersion: NARRATIVE_SERIALIZER_VERSION,
    languageCode: language,
    question,
    spread,
    cards,
    relationships,
    recurringCards,
    recurringThemes,
    memory,
    policy: {
      version: NARRATIVE_POLICY_VERSION,
      rules: [...NARRATIVE_POLICY_RULES],
    },
  };
}

const CARD_KEYS = new Set([
  'canonicalCardId',
  'displayName',
  'isReversed',
  'positionKey',
  'positionIndex',
  'coreMeaning',
  'orientationExpression',
  'keywordIds',
  'symbolTags',
  'transforms',
  'light',
  'shadow',
  'tension',
  'desire',
  'fear',
  'relationshipDynamic',
  'decisionDynamic',
  'actionDirection',
]);

function parseCard(raw: unknown): Record<string, unknown> {
  const c = asRecord(raw);
  if (!c) reject();
  exactKeys(c, CARD_KEYS);
  if (!nonBlank(c.canonicalCardId) || !nonBlank(c.displayName)) reject();
  if (!nonBlank(c.positionKey) || typeof c.positionIndex !== 'number') reject();
  if (!Number.isInteger(c.positionIndex) || c.positionIndex < 0) reject();
  if (typeof c.isReversed !== 'boolean') reject();
  return c;
}

const REL_KEYS = new Set([
  'leftCardId',
  'rightCardId',
  'leftPositionKey',
  'rightPositionKey',
  'kind',
  'strength',
]);

function parseRelationship(raw: unknown): Record<string, unknown> {
  const r = asRecord(raw);
  if (!r) reject();
  exactKeys(r, REL_KEYS);
  if (!nonBlank(r.leftCardId) || !nonBlank(r.rightCardId)) reject();
  if (!nonBlank(r.leftPositionKey) || !nonBlank(r.rightPositionKey)) reject();
  if (!nonBlank(r.kind) || !isFiniteUnit(r.strength)) reject();
  if (r.leftCardId === r.rightCardId) reject();
  return r;
}

const OCC_KEYS = new Set([
  'occurredAtUtc',
  'spreadId',
  'positionKey',
  'orientationKnown',
  'isReversed',
  'intentionSummary',
]);

const REC_CARD_KEYS = new Set([
  'canonicalCardId',
  'occurrenceCount',
  'contextsOverlap',
  'overlapSummaryKey',
  'occurrences',
]);

function parseRecurringCard(raw: unknown): Record<string, unknown> {
  const r = asRecord(raw);
  if (!r) reject();
  exactKeys(r, REC_CARD_KEYS);
  if (!nonBlank(r.canonicalCardId)) reject();
  if (typeof r.occurrenceCount !== 'number' || !Number.isInteger(r.occurrenceCount)) {
    reject();
  }
  if (r.occurrenceCount <= 0) reject();
  if (typeof r.contextsOverlap !== 'boolean') reject();
  if (r.contextsOverlap) {
    if (!nonBlank(r.overlapSummaryKey)) reject();
  } else if (r.overlapSummaryKey != null) {
    reject();
  }
  if (!Array.isArray(r.occurrences)) reject();
  if (r.occurrences.length > NARRATIVE_LIMITS.maxRecurringOccurrencesListed) {
    reject();
  }
  if (r.occurrenceCount < r.occurrences.length) reject();
  for (const o of r.occurrences) {
    const occ = asRecord(o);
    if (!occ) reject();
    exactKeys(occ, OCC_KEYS);
    if (!nonBlank(occ.spreadId) || !nonBlank(occ.positionKey)) reject();
    if (typeof occ.orientationKnown !== 'boolean') reject();
  }
  return r;
}

const THEME_KEYS = new Set([
  'themeIdOrLabel',
  'supportCount',
  'relatedCardIds',
  'relevanceToCurrentAsk',
]);

function parseTheme(raw: unknown): Record<string, unknown> {
  const t = asRecord(raw);
  if (!t) reject();
  exactKeys(t, THEME_KEYS);
  if (!nonBlank(t.themeIdOrLabel)) reject();
  if (typeof t.supportCount !== 'number' || !Number.isInteger(t.supportCount)) {
    reject();
  }
  if (t.supportCount < 2) reject();
  if (!isFiniteUnit(t.relevanceToCurrentAsk)) reject();
  if (!Array.isArray(t.relatedCardIds)) reject();
  const seen = new Set<string>();
  for (const id of t.relatedCardIds) {
    if (typeof id !== 'string' || id.trim() === '') reject();
    if (seen.has(id)) reject();
    seen.add(id);
  }
  return t;
}

function validateSpreadAndCards(
  spread: Record<string, unknown>,
  cards: Record<string, unknown>[],
): void {
  if (!nonBlank(spread.spreadId)) reject();
  if (typeof spread.cardCount !== 'number' || !Number.isInteger(spread.cardCount)) {
    reject();
  }
  if (spread.cardCount <= 0) reject();
  if (!Array.isArray(spread.positions) || !Array.isArray(spread.interpretationOrder)) {
    reject();
  }
  if (spread.positions.length !== spread.cardCount) reject();
  if (cards.length !== spread.cardCount) reject();
  const posKeys = new Set<string>();
  const indices = new Set<number>();
  for (const p of spread.positions) {
    const pos = asRecord(p);
    if (!pos) reject();
    exactKeys(pos, new Set(['positionKey', 'index', 'role', 'temporal']));
    if (!nonBlank(pos.positionKey) || typeof pos.index !== 'number') reject();
    if (!Number.isInteger(pos.index)) reject();
    if (posKeys.has(pos.positionKey) || indices.has(pos.index)) reject();
    posKeys.add(pos.positionKey);
    indices.add(pos.index);
  }
  for (let i = 0; i < spread.cardCount; i++) {
    if (!indices.has(i)) reject();
  }
  const order = spread.interpretationOrder as unknown[];
  if (order.length !== spread.cardCount) reject();
  const orderSeen = new Set<number>();
  for (const idx of order) {
    if (typeof idx !== 'number' || !Number.isInteger(idx)) reject();
    if (idx < 0 || idx >= spread.cardCount || orderSeen.has(idx)) reject();
    orderSeen.add(idx);
  }
  const cardIds = new Set<string>();
  const cardPos = new Set<string>();
  const byPos = new Map<string, number>();
  for (const pos of spread.positions as Record<string, unknown>[]) {
    byPos.set(String(pos.positionKey), pos.index as number);
  }
  for (const c of cards) {
    const id = String(c.canonicalCardId);
    const pk = String(c.positionKey);
    if (cardIds.has(id) || cardPos.has(pk)) reject();
    cardIds.add(id);
    cardPos.add(pk);
    if (!byPos.has(pk) || byPos.get(pk) !== c.positionIndex) reject();
  }
}

function validateRelationships(
  cards: Record<string, unknown>[],
  relationships: Record<string, unknown>[],
): void {
  if (relationships.length > NARRATIVE_LIMITS.maxRelationships) reject();
  const byId = new Map(cards.map((c) => [String(c.canonicalCardId), c]));
  for (const r of relationships) {
    const left = byId.get(String(r.leftCardId));
    const right = byId.get(String(r.rightCardId));
    if (!left || !right) reject();
    if (left.positionKey !== r.leftPositionKey) reject();
    if (right.positionKey !== r.rightPositionKey) reject();
  }
}

function validateRecurrence(
  cards: Record<string, unknown>[],
  recurringCards: Record<string, unknown>[],
  themes: Record<string, unknown>[],
): void {
  if (themes.length > NARRATIVE_LIMITS.maxThemeLabels) reject();
  const current = new Set(cards.map((c) => String(c.canonicalCardId)));
  for (const r of recurringCards) {
    if (!current.has(String(r.canonicalCardId))) reject();
  }
  for (const t of themes) {
    for (const id of t.relatedCardIds as string[]) {
      if (!current.has(id)) reject();
    }
  }
}

function validateMemory(memory: Record<string, unknown>): void {
  if (typeof memory.included !== 'boolean') reject();
  if (typeof memory.priorReadingCount !== 'number') reject();
  if (!Number.isInteger(memory.priorReadingCount)) reject();
  if (memory.priorReadingCount < 0) reject();
  if (memory.priorReadingCount > NARRATIVE_LIMITS.maxPriorReadingsScanned) {
    reject();
  }
  if (!Array.isArray(memory.entries)) reject();
  if (!memory.included && memory.entries.length > 0) reject();
  let chars = 0;
  for (const e of memory.entries) {
    const entry = asRecord(e);
    if (!entry) reject();
    exactKeys(
      entry,
      new Set([
        'kind',
        'contentForModel',
        'sourceType',
        'occurredAtUtc',
        'confidence',
        'epistemic',
      ]),
    );
    if (!nonBlank(entry.kind) || !nonBlank(entry.contentForModel)) reject();
    if (entry.confidence != null && !isFiniteUnit(entry.confidence)) reject();
    chars += String(entry.contentForModel).length;
  }
  if (chars > NARRATIVE_LIMITS.maxMemoryChars) reject();
}
