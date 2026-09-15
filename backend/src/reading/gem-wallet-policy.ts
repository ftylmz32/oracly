/** Server-owned wallet policy. Clients never choose these values. */
export const GEM_STARTER_GRANT = 20;
export const GEM_DAILY_REWARD = 50;
export const GEM_TAROT_READING_COST = 20;
/** Provisional only: replace after commercial economy approval. Server authority. */
export const PROVISIONAL_NON_COMMERCIAL_REWARDED_AD_GEMS = 5;

export function serverDayKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}
