export const COFFEE_INTENTION_MAX_LENGTH = 200;

const CONTROL_CHARACTERS = /[\u0000-\u001f\u007f-\u009f]/u;
const HTML_MARKUP = /<[^>]*>|[<>]/u;

/** Canonical trusted Coffee context. Never logs or interpolates the value. */
export function sanitizeCoffeeIntention(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const normalized = value.trim();
  if (!normalized || normalized.length > COFFEE_INTENTION_MAX_LENGTH) return null;
  if (CONTROL_CHARACTERS.test(normalized) || HTML_MARKUP.test(normalized)) return null;
  return normalized;
}
