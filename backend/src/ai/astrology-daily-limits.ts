/** Daily astrology writer — frozen enums and ceilings (`astrology_daily`). */

export const ASTROLOGY_DAILY_MODE = 'sky_daily_v1';
export const ASTROLOGY_DAILY_CONTRACT_VERSION = 1;
export const ASTROLOGY_DAILY_RESULT_VERSION = 1;
export const ASTROLOGY_DAILY_SCHEMA_NAME = 'oracly_astrology_daily_v1';

export const ASTROLOGY_SIGNS = [
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

export const ASTROLOGY_NATAL_POINTS = [
  'sun',
  'moon',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'ascendant',
  'midheaven',
] as const;

export const ASTROLOGY_TRANSIT_POINTS = [
  'moon',
  'sun',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
] as const;

export const ASTROLOGY_ASPECTS = [
  'conjunction',
  'sextile',
  'square',
  'trine',
  'opposition',
] as const;

export const ASTROLOGY_TONES = ['fusion', 'flow', 'friction'] as const;
export const ASTROLOGY_STRENGTHS = ['exact', 'close', 'wide'] as const;
export const ASTROLOGY_SPANS = ['hours', 'days', 'week', 'weeks'] as const;
export const ASTROLOGY_DEPTHS = ['full', 'dayOnly'] as const;

/** Visible lanes, in the order the writer returns them. */
export const ASTROLOGY_LANES = [
  'overall',
  'love',
  'career',
  'money',
  'mood',
  'drive',
  'opportunity',
  'caution',
] as const;

export const ASTROLOGY_DAILY_LIMITS = {
  maxThemes: 3,
  maxThemeChars: 64,
  maxAddressNameChars: 32,
  maxNarrativeJsonChars: 8_000,
  portrait: 420,
  overall: 900,
  lane: 650,
  reflection: 220,
  totalVisible: 5_200,
  /** A same-day request may differ from the server UTC day by one. */
  maxDaySkew: 1,
} as const;

/** Writing budgets; not schema ceilings. */
export const ASTROLOGY_DAILY_WORDS = {
  overallMin: 55,
  overallMax: 95,
  laneMin: 30,
  laneMax: 65,
} as const;
