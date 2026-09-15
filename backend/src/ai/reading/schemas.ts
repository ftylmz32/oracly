/** Strict JSON Schemas for Coffee/Palm observer + writer (Chat Completions). */

const evidenceItem = {
  type: 'object',
  additionalProperties: false,
  required: ['id', 'region', 'description', 'confidence', 'visibility', 'resemblance'],
  properties: {
    id: { type: 'string', minLength: 2, maxLength: 32 },
    region: { type: 'string', minLength: 2, maxLength: 64 },
    description: { type: 'string', minLength: 8, maxLength: 400 },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
    visibility: { type: 'string', enum: ['clear', 'partial', 'uncertain'] },
    resemblance: { type: ['string', 'null'], maxLength: 120 },
  },
} as const;

const section = {
  type: 'object',
  additionalProperties: false,
  required: ['text', 'evidenceIds'],
  properties: {
    text: { type: 'string' },
    evidenceIds: {
      type: 'array',
      items: { type: 'string' },
      maxItems: 12,
    },
  },
} as const;

/**
 * Same shape as [section], but for visualObservation specifically: a
 * brief scene-setting opener, not a full evidence report. The hard
 * maxLength keeps this structurally impossible to turn into an essay —
 * see human-quality.ts's observation_heavy check for the matching
 * quality-gate side of this same rule.
 */
const briefSection = {
  type: 'object',
  additionalProperties: false,
  required: ['text', 'evidenceIds'],
  properties: {
    text: { type: 'string', maxLength: 260 },
    evidenceIds: {
      type: 'array',
      items: { type: 'string' },
      maxItems: 12,
    },
  },
} as const;

export const COFFEE_OBSERVER_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['usable', 'reason', 'checks', 'evidence'],
  properties: {
    usable: { type: 'boolean' },
    reason: { type: 'string' },
    checks: {
      type: 'object',
      additionalProperties: false,
      required: [
        'cupInteriorVisible',
        'adequateFocusLight',
        'residueVisible',
        'milkFoamObstruction',
        'usefulRegionsVisible',
      ],
      properties: {
        cupInteriorVisible: { type: 'boolean' },
        adequateFocusLight: { type: 'boolean' },
        residueVisible: { type: 'boolean' },
        milkFoamObstruction: { type: 'boolean' },
        usefulRegionsVisible: { type: 'boolean' },
      },
    },
    evidence: { type: 'array', items: evidenceItem, maxItems: 16 },
  },
} as const;

/**
 * Coffee V2 (three-photo reading) — additive, dedicated schema. Legacy
 * COFFEE_OBSERVER_SCHEMA above is never modified or reused for V2.
 */
const coffeeV2EvidenceItem = {
  type: 'object',
  additionalProperties: false,
  required: ['id', 'region', 'description', 'confidence', 'visibility', 'resemblance', 'sourceSlot'],
  properties: {
    id: { type: 'string', minLength: 2, maxLength: 32 },
    region: { type: 'string', minLength: 2, maxLength: 64 },
    description: { type: 'string', minLength: 8, maxLength: 400 },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
    visibility: { type: 'string', enum: ['clear', 'partial', 'uncertain'] },
    resemblance: { type: ['string', 'null'], maxLength: 120 },
    /** Which of the three photos this evidence item was actually observed in. */
    sourceSlot: { type: 'string', enum: ['cup_primary', 'cup_secondary', 'saucer'] },
  },
} as const;

const coffeeV2CupPhotoChecks = {
  type: 'object',
  additionalProperties: false,
  required: ['cupInteriorVisible', 'adequateFocusLight', 'residueVisible', 'usefulRegionsVisible'],
  properties: {
    cupInteriorVisible: { type: 'boolean' },
    adequateFocusLight: { type: 'boolean' },
    residueVisible: { type: 'boolean' },
    usefulRegionsVisible: { type: 'boolean' },
  },
} as const;

const coffeeV2SaucerPhotoChecks = {
  type: 'object',
  additionalProperties: false,
  required: ['saucerVisible', 'adequateFocusLight', 'residueOrFlowVisible', 'usefulRegionsVisible'],
  properties: {
    saucerVisible: { type: 'boolean' },
    adequateFocusLight: { type: 'boolean' },
    residueOrFlowVisible: { type: 'boolean' },
    usefulRegionsVisible: { type: 'boolean' },
  },
} as const;

export const COFFEE_V2_OBSERVER_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['usable', 'reason', 'photoChecks', 'evidence'],
  properties: {
    usable: { type: 'boolean' },
    reason: { type: 'string' },
    photoChecks: {
      type: 'object',
      additionalProperties: false,
      required: ['cupPrimary', 'cupSecondary', 'saucer'],
      properties: {
        cupPrimary: coffeeV2CupPhotoChecks,
        cupSecondary: coffeeV2CupPhotoChecks,
        saucer: coffeeV2SaucerPhotoChecks,
      },
    },
    evidence: { type: 'array', items: coffeeV2EvidenceItem, maxItems: 24 },
  },
} as const;

export const PALM_OBSERVER_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['usable', 'reason', 'checks', 'evidence'],
  properties: {
    usable: { type: 'boolean' },
    reason: { type: 'string' },
    checks: {
      type: 'object',
      additionalProperties: false,
      required: [
        'onePalmFacing',
        'majorLinesVisible',
        'adequateFocusLight',
        'overlapOcclusion',
        'dorsal',
      ],
      properties: {
        onePalmFacing: { type: 'boolean' },
        majorLinesVisible: { type: 'boolean' },
        adequateFocusLight: { type: 'boolean' },
        overlapOcclusion: { type: 'boolean' },
        dorsal: { type: 'boolean' },
      },
    },
    evidence: { type: 'array', items: evidenceItem, maxItems: 16 },
  },
} as const;

export const COFFEE_WRITER_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: [
    'visualObservation',
    'overall',
    'love',
    'career',
    'money',
    'nearFuture',
    'takeaway',
  ],
  properties: {
    visualObservation: briefSection,
    overall: section,
    love: section,
    career: section,
    money: section,
    nearFuture: section,
    takeaway: section,
  },
} as const;

export const PALM_WRITER_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: [
    'visualObservation',
    'overall',
    'lifeLine',
    'headLine',
    'heartLine',
    'fateLine',
    'takeaway',
  ],
  properties: {
    visualObservation: briefSection,
    overall: section,
    lifeLine: section,
    headLine: section,
    heartLine: section,
    fateLine: section,
    takeaway: section,
  },
} as const;
