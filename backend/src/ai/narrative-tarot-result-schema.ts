/** Phase 6E.3 — strict OpenAI JSON Schema for Narrative Tarot Result v2. */
import {
  LIFE_AREA_KINDS,
  NARRATIVE_LIMITS,
  NARRATIVE_RESULT_CONTRACT_VERSION,
} from './narrative-tarot-limits.js';

const textField = (max: number) => ({
  type: 'string',
  minLength: 1,
  maxLength: max,
});

const nullableText = (max: number) => ({
  type: ['string', 'null'],
  maxLength: max,
});

export const NARRATIVE_TAROT_RESULT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: [
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
  ],
  properties: {
    contractVersion: {
      type: 'integer',
      const: NARRATIVE_RESULT_CONTRACT_VERSION,
    },
    languageCode: { type: 'string', enum: ['tr', 'en', 'ru'] },
    summary: textField(NARRATIVE_LIMITS.summary),
    cardReadings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['cardId', 'positionKey', 'text'],
        properties: {
          cardId: { type: 'string', minLength: 1, maxLength: 64 },
          positionKey: { type: 'string', minLength: 1, maxLength: 64 },
          text: textField(NARRATIVE_LIMITS.cardReading),
        },
      },
    },
    synthesis: textField(NARRATIVE_LIMITS.synthesis),
    relationshipInsights: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['leftCardId', 'rightCardId', 'kind', 'text'],
        properties: {
          leftCardId: { type: 'string', minLength: 1, maxLength: 64 },
          rightCardId: { type: 'string', minLength: 1, maxLength: 64 },
          kind: { type: 'string', minLength: 1, maxLength: 64 },
          text: textField(NARRATIVE_LIMITS.relationshipInsight),
        },
      },
    },
    recurringCardInsights: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['cardId', 'text'],
        properties: {
          cardId: { type: 'string', minLength: 1, maxLength: 64 },
          text: textField(NARRATIVE_LIMITS.recurringCardInsight),
        },
      },
    },
    recurringThemeInsights: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['themeIdOrLabel', 'text'],
        properties: {
          themeIdOrLabel: { type: 'string', minLength: 1, maxLength: 120 },
          text: textField(NARRATIVE_LIMITS.recurringThemeInsight),
        },
      },
    },
    memoryInsights: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['memoryIndices', 'text'],
        properties: {
          memoryIndices: {
            type: 'array',
            minItems: 1,
            items: { type: 'integer', minimum: 0 },
            uniqueItems: true,
          },
          text: textField(NARRATIVE_LIMITS.memoryInsight),
        },
      },
    },
    lifeAreas: {
      type: 'array',
      maxItems: NARRATIVE_LIMITS.maxLifeAreas,
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['kind', 'text'],
        properties: {
          kind: { type: 'string', enum: [...LIFE_AREA_KINDS] },
          text: textField(NARRATIVE_LIMITS.lifeArea),
        },
      },
    },
    advice: textField(NARRATIVE_LIMITS.advice),
    reflectionPrompt: nullableText(NARRATIVE_LIMITS.reflectionPrompt),
    dailyFocus: nullableText(NARRATIVE_LIMITS.dailyFocus),
    closingMessage: textField(NARRATIVE_LIMITS.closingMessage),
  },
} as const;
