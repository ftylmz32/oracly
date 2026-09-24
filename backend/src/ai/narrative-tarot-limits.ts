/** Phase 6D.1 — Narrative V2 contract constants, enums, ceilings. */

export const NARRATIVE_CONTRACT_VERSION = 1;
export const NARRATIVE_TAROT_VERSION = 2;
export const NARRATIVE_SERIALIZER_VERSION = 1;
export const NARRATIVE_POLICY_VERSION = 'narrative_policy_v1';
export const NARRATIVE_MODE = 'narrative_v2';
export const NARRATIVE_RESULT_CONTRACT_VERSION = 1;
export const NARRATIVE_SCHEMA_NAME = 'oracly_tarot_narrative_v1';

export const NARRATIVE_POLICY_RULES = [
  'do_not_invent_cards',
  'do_not_invent_position_roles',
  'do_not_invent_relationships',
  'do_not_invent_recurrence',
  'do_not_invent_memory_or_history',
  'no_deterministic_prophecy',
  'distinguish_evidence_from_reflective_guidance',
  'answer_in_requested_language',
  'do_not_expose_internal_identifiers',
] as const;

export const NARRATIVE_SPREAD_IDS = [
  'classical.single',
  'classical.threeCard',
  'classical.fiveCard',
  'classical.sevenCard',
  'classical.celticCross',
  'signature.crossroads',
] as const;

/** Historical occurrence spread ids: V1 machine ids + Phase 4 legacy aliases. */
export const NARRATIVE_OCCURRENCE_SPREAD_IDS = [
  ...NARRATIVE_SPREAD_IDS,
  'single',
  'threeCard',
  'fiveCard',
  'sevenCard',
  'celtic',
  'crossroads',
] as const;

export const NARRATIVE_QUESTION_KINDS = [
  'decision',
  'relationship',
  'guidance',
  'open',
] as const;

export const NARRATIVE_GEOMETRY_HOOKS = [
  'singlePoint',
  'linearRow',
  'celticCross',
] as const;

export const NARRATIVE_LENGTH_BANDS = ['short', 'medium', 'full', 'long'] as const;

export const NARRATIVE_POSITION_ROLES = [
  'signal',
  'context',
  'root',
  'state',
  'challenge',
  'hiddenInfluence',
  'support',
  'direction',
  'self',
  'environment',
  'hopeFear',
  'outcome',
  'question',
  'avoid',
] as const;

export const NARRATIVE_TEMPORALS = [
  'past',
  'present',
  'future',
  'atemporal',
] as const;

export const NARRATIVE_RELATIONSHIP_KINDS = [
  'support',
  'reinforcement',
  'contrast',
  'conflict',
  'causeEffect',
  'blockage',
  'resolution',
  'escalation',
  'softening',
  'themeRepetition',
] as const;

export const NARRATIVE_TRANSFORMS = [
  'internalization',
  'delay',
  'excess',
  'deficiency',
  'avoidance',
  'distortion',
  'blockedExpression',
  'misdirection',
  'release',
  'privateInternal',
] as const;

export const NARRATIVE_MEMORY_KINDS = [
  'memorySummary',
  'revisitExcerpt',
  'revisitInstruction',
] as const;

export const NARRATIVE_MEMORY_SOURCE_TYPES = [
  'tarot',
  'coffee',
  'palm',
  'dream',
  'soulmate',
  'birthChart',
] as const;

export const NARRATIVE_MEMORY_EPISTEMICS = [
  'interpretation',
  'observation',
  'fact',
  'preference',
] as const;

export const NARRATIVE_LIMITS = {
  maxPriorReadingsScanned: 20,
  maxRecurringOccurrencesListed: 5,
  maxRelationships: 12,
  maxMemoryChars: 800,
  maxMemoryEntries: 4,
  maxThemeLabels: 4,
  maxLifeAreas: 4,
  maxCardCount: 12,
  maxNarrativeJsonChars: 32_000,
  maxQuestionChars: 280,
  maxTopicChars: 160,
  maxSpreadIdChars: 80,
  maxPositionKeyChars: 64,
  maxCardIdChars: 64,
  maxDisplayNameChars: 120,
  maxRelationshipKindChars: 40,
  maxThemeLabelChars: 120,
  maxMemorySourceTypeChars: 32,
  maxCardTextChars: 1000,
  maxKeywordItems: 16,
  maxKeywordItemChars: 64,
  maxTransformItems: 10,
  maxRelatedCardIds: 12,
  maxThemeSupportCount: 20,
  maxUtcChars: 40,
  maxIntentionSummaryChars: 280,
  summary: 1200,
  cardReading: 900,
  synthesis: 1600,
  relationshipInsight: 700,
  recurringCardInsight: 650,
  recurringThemeInsight: 650,
  memoryInsight: 650,
  lifeArea: 700,
  advice: 900,
  reflectionPrompt: 400,
  dailyFocus: 500,
  closingMessage: 600,
  totalVisible: 9000,
} as const;

export const LIFE_AREA_KINDS = ['love', 'career', 'money', 'spiritual'] as const;
export type LifeAreaKind = (typeof LIFE_AREA_KINDS)[number];

export function asEnumSet<T extends string>(values: readonly T[]): Set<string> {
  return new Set(values);
}
