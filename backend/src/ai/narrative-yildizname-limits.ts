/** Phase 5 — Yıldızname natal narrative contract constants, enums, ceilings. */

export const YILDIZNAME_NARRATIVE_VERSION = 1;
export const YILDIZNAME_SERIALIZER_VERSION = 1;
export const YILDIZNAME_CONTRACT_VERSION = 1;
export const YILDIZNAME_RESULT_CONTRACT_VERSION = 1;
export const YILDIZNAME_MODE = 'natal_narrative_v1';
export const YILDIZNAME_POLICY_VERSION = 'yildizname_policy_v1';
export const YILDIZNAME_SCHEMA_NAME = 'oracly_yildizname_narrative_v1';

/** Exact frozen policy rules — must match Flutter. */
export const YILDIZNAME_POLICY_RULES = [
  'USE_ONLY_SUPPLIED_FACTS',
  'DO_NOT_CALCULATE_ASTRONOMY',
  'DO_NOT_INVENT_MEMORY',
  'DO_NOT_INVENT_PLACEMENTS',
  'DO_NOT_INVENT_HOUSES',
  'DO_NOT_INVENT_ASPECTS',
  'DO_NOT_TREAT_SYMBOLIC_INTERPRETATION_AS_CERTAINTY',
  'NO_DETERMINISTIC_FUTURE',
  'NO_FATALISM',
  'NO_MEDICAL_DIAGNOSIS',
  'NO_PREGNANCY_CERTAINTY',
  'NO_LEGAL_FINANCIAL_GUARANTEE',
  'NO_GUARANTEED_SOULMATE',
  'KARMIC_LANGUAGE_METAPHOR_ONLY',
] as const;

export const YILDIZNAME_SCOPES = ['legacy', 'reduced', 'full'] as const;
export const YILDIZNAME_FIDELITIES = [
  'tropicalSunSign',
  'reducedNatal',
  'fullNatalEphemeris',
] as const;
/** Only these certainties may appear on supplied facts. */
export const YILDIZNAME_CERTAINTIES = ['exact', 'intervalStable'] as const;

export const YILDIZNAME_SECTION_KINDS = [
  'core_identity',
  'emotional_world',
  'mind_and_expression',
  'relationships_and_values',
  'drive_and_growth',
  'angles_and_houses',
  'patterns_and_tensions',
  'strengths_and_resources',
  'archive_echo',
  'practical_reflection',
] as const;

export const YILDIZNAME_BODIES = [
  'sun',
  'moon',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
  'pluto',
] as const;

export const YILDIZNAME_ANGLE_KINDS = ['ascendant', 'midheaven'] as const;

export const YILDIZNAME_SIGNS = [
  'aries',
  'taurus',
  'gemini',
  'cancer',
  'leo',
  'virgo',
  'libra',
  'scorpio',
  'sagittarius',
  'capricorn',
  'aquarius',
  'pisces',
] as const;

export const YILDIZNAME_ASPECT_TYPES = [
  'conjunction',
  'sextile',
  'square',
  'trine',
  'opposition',
] as const;

export const YILDIZNAME_HOUSE_SYSTEMS = ['wholeSign'] as const;

export const YILDIZNAME_OMITTED_LAYERS = [
  'moon',
  'exactDegrees',
  'ascendant',
  'midheaven',
  'houses',
  'aspects',
  'retrograde',
  'balances',
  'angles',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
  'pluto',
  'transits',
] as const;

export const YILDIZNAME_LIMITS = {
  maxPlacements: 10,
  maxHouses: 12,
  maxAspects: 48,
  maxAngles: 2,
  maxBalances: 2,
  maxThemes: 3,
  maxOmittedLayers: 20,
  maxSections: 10,
  maxNarrativeJsonChars: 32_000,
  maxFactRefChars: 80,
  maxThemeRefChars: 64,
  maxBodyChars: 24,
  maxSignChars: 24,
  maxLabelChars: 120,
  maxOmittedLayerChars: 40,
  maxCalculationVersionChars: 64,
  maxOrb: 12,
  summary: 1200,
  section: 1600,
  reflectionPrompt: 400,
  closingMessage: 600,
  totalVisible: 9000,
  maxFactRefsPerBlock: 12,
  maxThemeRefsPerBlock: 3,
} as const;

export function asEnumSet<T extends string>(values: readonly T[]): Set<string> {
  return new Set(values);
}
