/** Phase 6D — Narrative V2 contract constants (server-owned ceilings). */

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

export const NARRATIVE_LIMITS = {
  maxPriorReadingsScanned: 20,
  maxRecurringOccurrencesListed: 5,
  maxRelationships: 12,
  maxMemoryChars: 800,
  maxThemeLabels: 4,
  maxLifeAreas: 4,
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
