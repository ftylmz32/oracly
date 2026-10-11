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

const requiredSection = {
  type: 'object',
  additionalProperties: false,
  required: ['text', 'evidenceIds'],
  properties: {
    text: { type: 'string', minLength: 1 },
    evidenceIds: {
      type: 'array',
      items: { type: 'string' },
      minItems: 1,
      maxItems: 12,
    },
  },
} as const;

const requiredBriefSection = {
  ...requiredSection,
  properties: {
    ...requiredSection.properties,
    text: { type: 'string', minLength: 1, maxLength: 260 },
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

/**
 * Coffee Observer V3 (multi-view physical mark map) — additive and DARK: no
 * live path sends this schema to a provider yet. V2/legacy schemas above are
 * never modified or reused for V3.
 */
/** Exactly the three live capture slots (two cup views + saucer); never a fourth view. */
const COFFEE_V3_SLOT_ENUM = ['cup_view_a', 'cup_view_b', 'saucer'];
const COFFEE_V3_SURFACE_ENUM = ['cup_wall', 'cup_base', 'saucer'];
const COFFEE_V3_CONFIDENCE = { type: 'string', enum: ['high', 'medium', 'low'] } as const;
const COFFEE_V3_CLOCK = { type: ['integer', 'null'], minimum: 1, maximum: 12 } as const;

const coffeeV3View = {
  type: 'object',
  additionalProperties: false,
  required: ['slot', 'surfaceVisible', 'focusLightAdequate', 'residueVisible', 'handleVisible', 'handleClock'],
  properties: {
    slot: { type: 'string', enum: COFFEE_V3_SLOT_ENUM },
    surfaceVisible: { type: 'boolean' },
    focusLightAdequate: { type: 'boolean' },
    residueVisible: { type: 'boolean' },
    handleVisible: { type: ['boolean', 'null'] },
    handleClock: COFFEE_V3_CLOCK,
  },
} as const;

const coffeeV3Sighting = {
  type: 'object',
  additionalProperties: false,
  required: ['id', 'slot', 'surface', 'band', 'rimClock', 'saucerZone', 'bandCoverage', 'description', 'visibility', 'confidence'],
  properties: {
    id: { type: 'string', minLength: 1, maxLength: 32 },
    slot: { type: 'string', enum: COFFEE_V3_SLOT_ENUM },
    surface: { type: 'string', enum: COFFEE_V3_SURFACE_ENUM },
    band: { type: 'string', enum: ['rim_upper', 'middle', 'lower_base', 'unknown'] },
    rimClock: COFFEE_V3_CLOCK,
    saucerZone: { type: ['string', 'null'], enum: ['center', 'middle_ring', 'edge', 'unknown', null] },
    bandCoverage: { type: 'array', items: { type: 'string', enum: ['rim_upper', 'middle', 'lower_base'] }, maxItems: 3 },
    description: { type: 'string', minLength: 4, maxLength: 160 },
    visibility: { type: 'string', enum: ['clear', 'partial', 'uncertain'] },
    confidence: COFFEE_V3_CONFIDENCE,
  },
} as const;

const coffeeV3Form = {
  type: 'object',
  additionalProperties: false,
  required: ['motion', 'verticalDirection', 'openness', 'course', 'posture', 'continuity', 'grouping'],
  properties: {
    motion: { type: 'string', enum: ['moving', 'still', 'unknown'] },
    verticalDirection: { type: 'string', enum: ['rising', 'descending', 'level', 'unknown'] },
    openness: { type: 'string', enum: ['open', 'closed', 'unknown'] },
    course: { type: 'string', enum: ['straight', 'bending', 'branching', 'unknown'] },
    posture: { type: 'string', enum: ['upright', 'tilted', 'unknown'] },
    continuity: { type: 'string', enum: ['continuous', 'broken', 'unknown'] },
    grouping: { type: 'string', enum: ['isolated', 'clustered', 'unknown'] },
  },
} as const;

const coffeeV3Mark = {
  type: 'object',
  additionalProperties: false,
  required: ['id', 'surface', 'kind', 'topology', 'sightingIds', 'form', 'resemblances'],
  properties: {
    id: { type: 'string', minLength: 1, maxLength: 32 },
    surface: { type: 'string', enum: COFFEE_V3_SURFACE_ENUM },
    kind: { type: 'string', enum: ['residue', 'clear_area'] },
    topology: { type: 'string', enum: ['line', 'closed_loop', 'pool', 'patch', 'unknown'] },
    sightingIds: { type: 'array', items: { type: 'string', minLength: 1, maxLength: 32 }, minItems: 1, maxItems: 4 },
    form: coffeeV3Form,
    resemblances: {
      type: 'array',
      maxItems: 2,
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['label', 'strength'],
        properties: {
          label: { type: 'string', minLength: 1, maxLength: 40 },
          strength: { type: 'string', enum: ['strong', 'weak'] },
        },
      },
    },
  },
} as const;

const coffeeV3Relation = {
  type: 'object',
  additionalProperties: false,
  required: ['a', 'b', 'kind', 'confidence'],
  properties: {
    a: { type: 'string', minLength: 1, maxLength: 32 },
    b: { type: 'string', minLength: 1, maxLength: 32 },
    kind: {
      type: 'string',
      enum: ['near', 'touching', 'connected', 'crossing', 'contained_by', 'continuation_of', 'separated'],
    },
    confidence: COFFEE_V3_CONFIDENCE,
  },
} as const;

const coffeeV3Ambiguity = {
  type: 'object',
  additionalProperties: false,
  required: ['marks', 'reason'],
  properties: {
    marks: { type: 'array', items: { type: 'string', minLength: 1, maxLength: 32 }, minItems: 2, maxItems: 2 },
    reason: { type: 'string', enum: ['possible_same_mark'] },
  },
} as const;

export const COFFEE_V3_OBSERVER_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['contract', 'usable', 'reason', 'views', 'sightings', 'marks', 'relations', 'ambiguities', 'saucer'],
  properties: {
    contract: { type: 'string', enum: ['multi_view_marks_v3'] },
    usable: { type: 'boolean' },
    reason: { type: ['string', 'null'], maxLength: 160 },
    views: { type: 'array', items: coffeeV3View, minItems: 3, maxItems: 3 },
    sightings: { type: 'array', items: coffeeV3Sighting, maxItems: 30 },
    marks: { type: 'array', items: coffeeV3Mark, maxItems: 16 },
    relations: { type: 'array', items: coffeeV3Relation, maxItems: 12 },
    ambiguities: { type: 'array', items: coffeeV3Ambiguity, maxItems: 12 },
    saucer: {
      type: 'object',
      additionalProperties: false,
      required: ['surfaceState', 'flow'],
      properties: {
        surfaceState: { type: 'string', enum: ['clean', 'film', 'islands', 'flow', 'unclear'] },
        flow: {
          type: 'object',
          additionalProperties: false,
          required: ['present', 'direction'],
          properties: {
            present: { type: 'boolean' },
            direction: { type: 'string', enum: ['toward_center', 'toward_edge', 'around', 'none', 'unknown'] },
          },
        },
      },
    },
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
    visualObservation: requiredBriefSection,
    overall: requiredSection,
    love: section,
    career: section,
    money: section,
    nearFuture: section,
    takeaway: requiredSection,
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
