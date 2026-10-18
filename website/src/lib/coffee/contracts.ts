export const COFFEE_V3_CAPTURE_CONTRACT = 'three_view_v3' as const;
export const COFFEE_INPUT_CONTRACT = 'trusted_intention_v1' as const;
export const COFFEE_LANGUAGE = 'tr' as const;
export const COFFEE_INTENTION_MAX_LENGTH = 200;

export const COFFEE_V3_SLOTS = [
  'v3_cup_view_a',
  'v3_cup_view_b',
  'v3_saucer_view',
] as const;

export type CoffeeV3Slot = (typeof COFFEE_V3_SLOTS)[number];

export const WEB_SLOT_TO_SERVER_SLOT = {
  'cup-primary': 'v3_cup_view_a',
  'cup-secondary': 'v3_cup_view_b',
  saucer: 'v3_saucer_view',
} as const satisfies Record<string, CoffeeV3Slot>;

export type WebCoffeeSlot = keyof typeof WEB_SLOT_TO_SERVER_SLOT;

const CONTROL_CHARACTERS = /[\u0000-\u001f\u007f-\u009f]/u;
const HTML_MARKUP = /<[^>]*>|[<>]/u;
const SOURCE_REQUEST_ID = /^[A-Za-z0-9._:-]{8,64}$/;

export function sanitizeCoffeeIntention(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const normalized = value.trim();
  if (!normalized || normalized.length > COFFEE_INTENTION_MAX_LENGTH) return null;
  if (CONTROL_CHARACTERS.test(normalized) || HTML_MARKUP.test(normalized)) return null;
  return normalized;
}

export function createSourceRequestId(): string {
  return `web_coffee_v3_${crypto.randomUUID()}`;
}

export function buildCoffeeV3CreateBody(sourceRequestId: string, intention: string) {
  const safeIntention = sanitizeCoffeeIntention(intention);
  if (!SOURCE_REQUEST_ID.test(sourceRequestId) || !safeIntention) {
    throw new Error('invalid_coffee_v3_create_input');
  }
  return {
    readingType: 'coffee' as const,
    sourceRequestId,
    language: COFFEE_LANGUAGE,
    intention: safeIntention,
    coffeeInputContract: COFFEE_INPUT_CONTRACT,
    coffeeCaptureContract: COFFEE_V3_CAPTURE_CONTRACT,
  };
}

export async function fileToBase64(file: File): Promise<string> {
  const bytes = new Uint8Array(await file.arrayBuffer());
  let binary = '';
  for (let offset = 0; offset < bytes.length; offset += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + 0x8000));
  }
  return btoa(binary);
}
