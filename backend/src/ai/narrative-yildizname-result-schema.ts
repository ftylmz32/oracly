/** Phase 5 — strict OpenAI JSON Schema for Yıldızname natal narrative result. */
import {
  YILDIZNAME_LIMITS,
  YILDIZNAME_RESULT_CONTRACT_VERSION,
  YILDIZNAME_SCOPES,
  YILDIZNAME_SECTION_KINDS,
} from './narrative-yildizname-limits.js';

const textField = (max: number) => ({
  type: 'string',
  minLength: 1,
  maxLength: max,
});

const nullableText = (max: number) => ({
  type: ['string', 'null'],
  maxLength: max,
});

const refList = (maxItems: number, maxChars: number) => ({
  type: 'array',
  maxItems,
  items: { type: 'string', minLength: 1, maxLength: maxChars },
});

const proseBlock = {
  type: 'object',
  additionalProperties: false,
  required: ['text', 'factRefs', 'themeRefs'],
  properties: {
    text: textField(YILDIZNAME_LIMITS.summary),
    factRefs: refList(
      YILDIZNAME_LIMITS.maxFactRefsPerBlock,
      YILDIZNAME_LIMITS.maxFactRefChars,
    ),
    themeRefs: refList(
      YILDIZNAME_LIMITS.maxThemeRefsPerBlock,
      YILDIZNAME_LIMITS.maxThemeRefChars,
    ),
  },
};

const sectionBlock = {
  type: 'object',
  additionalProperties: false,
  required: ['kind', 'text', 'factRefs', 'themeRefs'],
  properties: {
    kind: { type: 'string', enum: [...YILDIZNAME_SECTION_KINDS] },
    text: textField(YILDIZNAME_LIMITS.section),
    factRefs: refList(
      YILDIZNAME_LIMITS.maxFactRefsPerBlock,
      YILDIZNAME_LIMITS.maxFactRefChars,
    ),
    themeRefs: refList(
      YILDIZNAME_LIMITS.maxThemeRefsPerBlock,
      YILDIZNAME_LIMITS.maxThemeRefChars,
    ),
  },
};

export const YILDIZNAME_NARRATIVE_RESULT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: [
    'contractVersion',
    'languageCode',
    'scope',
    'summary',
    'sections',
    'reflectionPrompt',
    'closingMessage',
  ],
  properties: {
    contractVersion: {
      type: 'integer',
      const: YILDIZNAME_RESULT_CONTRACT_VERSION,
    },
    languageCode: { type: 'string', enum: ['tr', 'en', 'ru'] },
    scope: { type: 'string', enum: [...YILDIZNAME_SCOPES] },
    summary: proseBlock,
    sections: {
      type: 'array',
      minItems: 1,
      maxItems: YILDIZNAME_LIMITS.maxSections,
      items: sectionBlock,
    },
    reflectionPrompt: nullableText(YILDIZNAME_LIMITS.reflectionPrompt),
    closingMessage: textField(YILDIZNAME_LIMITS.closingMessage),
  },
} as const;
