/** Phase 6D.1 — strict Narrative V2 request wire validation (fail-closed). */
import { ErrorCode, fail } from '../errors.js';
import { asRecord } from './sanitize.js';
import {
  asEnumSet,
  NARRATIVE_CONTRACT_VERSION,
  NARRATIVE_GEOMETRY_HOOKS,
  NARRATIVE_LENGTH_BANDS,
  NARRATIVE_LIMITS,
  NARRATIVE_MODE,
  NARRATIVE_POLICY_RULES,
  NARRATIVE_POLICY_VERSION,
  NARRATIVE_POSITION_ROLES,
  NARRATIVE_QUESTION_KINDS,
  NARRATIVE_SERIALIZER_VERSION,
  NARRATIVE_TAROT_VERSION,
  NARRATIVE_TEMPORALS,
} from './narrative-tarot-limits.js';
import {
  isFiniteUnit,
  optionalMemEpistemic,
  optionalMemSource,
  optionalString,
  optionalUtcZ,
  requireEnum,
  requireMemKind,
  requireRelKind,
  requireOccurrenceSpreadId,
  requireSpreadId,
  requireString,
  requireTokenList,
  requireTransforms,
  requireUtcZ,
} from './narrative-tarot-contract-fields.js';

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

const Q_KINDS = asEnumSet(NARRATIVE_QUESTION_KINDS);
const GEOMETRY = asEnumSet(NARRATIVE_GEOMETRY_HOOKS);
const LENGTHS = asEnumSet(NARRATIVE_LENGTH_BANDS);
const ROLES = asEnumSet(NARRATIVE_POSITION_ROLES);
const TEMPORALS = asEnumSet(NARRATIVE_TEMPORALS);

const OPTIONAL_CARD_TEXT = [
  'light',
  'shadow',
  'tension',
  'desire',
  'fear',
  'relationshipDynamic',
  'decisionDynamic',
  'actionDirection',
] as const;

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
  const jsonChars = JSON.stringify(narrative).length;
  if (jsonChars > NARRATIVE_LIMITS.maxNarrativeJsonChars) reject();
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
  parseQuestion(question);
  parsePolicy(policy);
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

function parseQuestion(q: Record<string, unknown>): void {
  exactKeys(q, new Set(['text', 'topic', 'kind', 'hasRealQuestion']));
  requireEnum(reject, q.kind, Q_KINDS);
  if (typeof q.hasRealQuestion !== 'boolean') reject();
  if (q.hasRealQuestion) {
    requireString(reject, q.text, NARRATIVE_LIMITS.maxQuestionChars, true);
  } else if (q.text !== null) {
    reject();
  }
  optionalString(reject, q.topic, NARRATIVE_LIMITS.maxTopicChars);
}

function parsePolicy(policy: Record<string, unknown>): void {
  exactKeys(policy, new Set(['version', 'rules']));
  if (policy.version !== NARRATIVE_POLICY_VERSION) reject();
  if (!Array.isArray(policy.rules)) reject();
  if (policy.rules.length !== NARRATIVE_POLICY_RULES.length) reject();
  for (let i = 0; i < NARRATIVE_POLICY_RULES.length; i++) {
    if (policy.rules[i] !== NARRATIVE_POLICY_RULES[i]) reject();
  }
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
  ...OPTIONAL_CARD_TEXT,
]);

function parseCard(raw: unknown): Record<string, unknown> {
  const c = asRecord(raw);
  if (!c) reject();
  exactKeys(c, CARD_KEYS);
  requireString(reject, c.canonicalCardId, NARRATIVE_LIMITS.maxCardIdChars, true);
  requireString(reject, c.displayName, NARRATIVE_LIMITS.maxDisplayNameChars, true);
  requireString(reject, c.positionKey, NARRATIVE_LIMITS.maxPositionKeyChars, true);
  if (typeof c.positionIndex !== 'number' || !Number.isInteger(c.positionIndex)) {
    reject();
  }
  if (c.positionIndex < 0) reject();
  if (typeof c.isReversed !== 'boolean') reject();
  requireString(reject, c.coreMeaning, NARRATIVE_LIMITS.maxCardTextChars, true);
  requireString(
    reject,
    c.orientationExpression,
    NARRATIVE_LIMITS.maxCardTextChars,
    true,
  );
  requireTokenList(
    reject,
    c.keywordIds,
    NARRATIVE_LIMITS.maxKeywordItems,
    NARRATIVE_LIMITS.maxKeywordItemChars,
  );
  requireTokenList(
    reject,
    c.symbolTags,
    NARRATIVE_LIMITS.maxKeywordItems,
    NARRATIVE_LIMITS.maxKeywordItemChars,
  );
  requireTransforms(reject, c.transforms);
  for (const key of OPTIONAL_CARD_TEXT) {
    if (key in c) {
      optionalString(reject, c[key], NARRATIVE_LIMITS.maxCardTextChars);
    }
  }
  return c;
}

function parseRelationship(raw: unknown): Record<string, unknown> {
  const r = asRecord(raw);
  if (!r) reject();
  exactKeys(
    r,
    new Set([
      'leftCardId',
      'rightCardId',
      'leftPositionKey',
      'rightPositionKey',
      'kind',
      'strength',
    ]),
  );
  requireString(reject, r.leftCardId, NARRATIVE_LIMITS.maxCardIdChars, true);
  requireString(reject, r.rightCardId, NARRATIVE_LIMITS.maxCardIdChars, true);
  requireString(reject, r.leftPositionKey, NARRATIVE_LIMITS.maxPositionKeyChars, true);
  requireString(reject, r.rightPositionKey, NARRATIVE_LIMITS.maxPositionKeyChars, true);
  requireRelKind(reject, r.kind);
  if (!isFiniteUnit(r.strength)) reject();
  if (r.leftCardId === r.rightCardId) reject();
  return r;
}

function parseOccurrence(raw: unknown): Record<string, unknown> {
  const occ = asRecord(raw);
  if (!occ) reject();
  exactKeys(
    occ,
    new Set([
      'occurredAtUtc',
      'spreadId',
      'positionKey',
      'orientationKnown',
      'isReversed',
      'intentionSummary',
    ]),
  );
  requireUtcZ(reject, occ.occurredAtUtc);
  requireOccurrenceSpreadId(reject, occ.spreadId);
  requireString(reject, occ.positionKey, NARRATIVE_LIMITS.maxPositionKeyChars, true);
  if (typeof occ.orientationKnown !== 'boolean') reject();
  if (occ.orientationKnown) {
    if (typeof occ.isReversed !== 'boolean') reject();
  } else if (occ.isReversed !== null) {
    reject();
  }
  if ('intentionSummary' in occ) {
    optionalString(reject, occ.intentionSummary, NARRATIVE_LIMITS.maxIntentionSummaryChars);
  }
  return occ;
}

function parseRecurringCard(raw: unknown): Record<string, unknown> {
  const r = asRecord(raw);
  if (!r) reject();
  exactKeys(
    r,
    new Set([
      'canonicalCardId',
      'occurrenceCount',
      'contextsOverlap',
      'overlapSummaryKey',
      'occurrences',
    ]),
  );
  requireString(reject, r.canonicalCardId, NARRATIVE_LIMITS.maxCardIdChars, true);
  if (typeof r.occurrenceCount !== 'number' || !Number.isInteger(r.occurrenceCount)) {
    reject();
  }
  if (r.occurrenceCount <= 0) reject();
  if (typeof r.contextsOverlap !== 'boolean') reject();
  if (r.contextsOverlap) {
    requireString(reject, r.overlapSummaryKey, 120, true);
  } else if (r.overlapSummaryKey != null) {
    reject();
  }
  if (!Array.isArray(r.occurrences)) reject();
  if (r.occurrences.length > NARRATIVE_LIMITS.maxRecurringOccurrencesListed) {
    reject();
  }
  if (r.occurrenceCount < r.occurrences.length) reject();
  r.occurrences = r.occurrences.map(parseOccurrence);
  return r;
}

function parseTheme(raw: unknown): Record<string, unknown> {
  const t = asRecord(raw);
  if (!t) reject();
  exactKeys(
    t,
    new Set([
      'themeIdOrLabel',
      'supportCount',
      'relatedCardIds',
      'relevanceToCurrentAsk',
    ]),
  );
  requireString(reject, t.themeIdOrLabel, NARRATIVE_LIMITS.maxThemeLabelChars, true);
  if (typeof t.supportCount !== 'number' || !Number.isInteger(t.supportCount)) {
    reject();
  }
  if (t.supportCount < 2 || t.supportCount > NARRATIVE_LIMITS.maxThemeSupportCount) {
    reject();
  }
  if (!isFiniteUnit(t.relevanceToCurrentAsk)) reject();
  requireTokenList(
    reject,
    t.relatedCardIds,
    NARRATIVE_LIMITS.maxRelatedCardIds,
    NARRATIVE_LIMITS.maxCardIdChars,
  );
  return t;
}

function validateSpreadAndCards(
  spread: Record<string, unknown>,
  cards: Record<string, unknown>[],
): void {
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
  requireSpreadId(reject, spread.spreadId);
  requireEnum(reject, spread.geometryHook, GEOMETRY);
  requireEnum(reject, spread.lengthBand, LENGTHS);
  if (typeof spread.cardCount !== 'number' || !Number.isInteger(spread.cardCount)) {
    reject();
  }
  if (spread.cardCount < 1 || spread.cardCount > NARRATIVE_LIMITS.maxCardCount) {
    reject();
  }
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
    requireString(reject, pos.positionKey, NARRATIVE_LIMITS.maxPositionKeyChars, true);
    requireEnum(reject, pos.role, ROLES);
    requireEnum(reject, pos.temporal, TEMPORALS);
    if (typeof pos.index !== 'number' || !Number.isInteger(pos.index)) reject();
    if (posKeys.has(pos.positionKey as string) || indices.has(pos.index)) reject();
    posKeys.add(pos.positionKey as string);
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
    if (idx < 0 || idx >= (spread.cardCount as number) || orderSeen.has(idx)) {
      reject();
    }
    orderSeen.add(idx);
  }
  const cardIds = new Set<string>();
  const cardPos = new Set<string>();
  const byPos = new Map<string, number>();
  for (const p of spread.positions) {
    const pos = p as Record<string, unknown>;
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
  if (recurringCards.length > cards.length || recurringCards.length > 12) {
    reject();
  }
  const current = new Set(cards.map((c) => String(c.canonicalCardId)));
  const seenRec = new Set<string>();
  for (const r of recurringCards) {
    const id = String(r.canonicalCardId);
    if (!current.has(id) || seenRec.has(id)) reject();
    seenRec.add(id);
  }
  const seenTheme = new Set<string>();
  for (const t of themes) {
    const label = String(t.themeIdOrLabel);
    if (seenTheme.has(label)) reject();
    seenTheme.add(label);
    for (const id of t.relatedCardIds as string[]) {
      if (!current.has(id)) reject();
    }
  }
}

function validateMemory(memory: Record<string, unknown>): void {
  exactKeys(memory, new Set(['included', 'priorReadingCount', 'entries']));
  if (typeof memory.included !== 'boolean') reject();
  if (typeof memory.priorReadingCount !== 'number') reject();
  if (!Number.isInteger(memory.priorReadingCount)) reject();
  if (memory.priorReadingCount < 0) reject();
  if (memory.priorReadingCount > NARRATIVE_LIMITS.maxPriorReadingsScanned) {
    reject();
  }
  if (!Array.isArray(memory.entries)) reject();
  if (memory.entries.length > NARRATIVE_LIMITS.maxMemoryEntries) reject();
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
    requireMemKind(reject, entry.kind);
    requireString(reject, entry.contentForModel, NARRATIVE_LIMITS.maxMemoryChars, true);
    if ('sourceType' in entry) optionalMemSource(reject, entry.sourceType);
    if ('occurredAtUtc' in entry) optionalUtcZ(reject, entry.occurredAtUtc);
    if ('epistemic' in entry) optionalMemEpistemic(reject, entry.epistemic);
    if (entry.confidence != null && !isFiniteUnit(entry.confidence)) reject();
    chars += String(entry.contentForModel).length;
  }
  if (chars > NARRATIVE_LIMITS.maxMemoryChars) reject();
}
