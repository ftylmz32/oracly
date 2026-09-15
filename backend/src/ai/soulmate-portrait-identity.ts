/**
 * Stable Soulmate portrait identity. Not a face, not a biometric.
 *
 * NOTE: the trait pools and `SoulmatePortraitCore` below are superseded by
 * the Soulmate Signature Premium Portrait System (`soulmate-visual-profile.ts`
 * / `soulmate-portrait-prompt-builder.ts`) — kept only because
 * `coresEqual`/`coreFromSeed`/`portraitSeed` are not imported anywhere else
 * and removing them is a larger diff than this task's scope requires.
 * `SOULMATE_MAX_IMAGE_CALLS`, `presenceFor`, `PortraitPresentation`, and the
 * nonce helpers below ARE still the live implementation, unchanged.
 */
import { createHash, randomBytes } from 'node:crypto';
import type { SoulmateVisualProfile } from './soulmate-visual-profile.js';

export const PORTRAIT_IDENTITY_VERSION = 1;

/** One logical draw: primary image plus one uniqueness render. Not a loop. */
export const SOULMATE_MAX_IMAGE_CALLS = 2;

export type PortraitPresentation = 'feminine' | 'masculine' | 'unspecified';

export type SoulmatePortraitCore = {
  version: number;
  ageBand: string;
  faceShape: string;
  hairFamily: string;
  hairLength: string;
  hairTexture: string;
  eyePresentation: string;
  browStyle: string;
  skinToneRange: string;
  facialHair: string;
  stylingEnergy: string;
  expressionEnergy: string;
  visualMood: string;
  distinguishingTrait: string;
  relationshipArchetype: string;
};

export type SoulmateRenderVariation = {
  pose: string;
  framing: string;
  background: string;
  wardrobeDetail: string;
  lighting: string;
};

const AGE = [
  'early twenties',
  'late twenties',
  'early thirties',
  'mid thirties',
  'early forties',
];
const FACE = [
  'soft oval',
  'gently angular',
  'rounded rectangular',
  'heart-leaning oval',
  'long oval',
  'quiet square',
];
const HAIR = [
  'dark brown',
  'deep black',
  'warm chestnut',
  'ash brown',
  'black-brown',
  'copper brown',
];
const LENGTH = [
  'cropped',
  'ear-length',
  'collar-length',
  'shoulder-length',
  'long and loosely gathered',
];
const TEXTURE = ['straight', 'loose wave', 'defined wave', 'soft coil', 'fine straight'];
const EYES = [
  'deep brown',
  'warm hazel',
  'cool grey-green',
  'amber brown',
  'muted green',
  'dark brown',
];
const BROW = [
  'straight and quiet',
  'soft arch',
  'low and defined',
  'natural and slightly uneven',
];
const SKIN = [
  'warm medium',
  'cool fair',
  'golden olive',
  'deep warm brown',
  'light olive',
  'neutral beige',
];
const BEARD = ['clean-shaven', 'light stubble', 'short trimmed beard', 'clean jaw'];
const STYLE = [
  'quiet linen ease',
  'muted knit ease',
  'tailored dark layer',
  'soft cotton everyday',
  'understated wool coat',
  'minimal dark knit',
];
const ENERGY = [
  'inward calm',
  'quiet warmth',
  'concentrated stillness',
  'gentle reserve',
  'open thoughtfulness',
];
const MOOD = [
  'reserved',
  'tender',
  'clear',
  'grounded',
  'luminous',
  'reflective',
];
const TRAIT = [
  'faint freckles across the nose',
  'a small natural mark near one cheek',
  'slightly uneven brows',
  'a soft unposed dimple',
  'fine lines at the outer eye',
  'a quietly distinctive jaw angle',
];
const ARCHETYPE = [
  'steady listener',
  'quietly curious companion',
  'grounded presence',
  'softly playful reserve',
  'reserved warmth',
  'attentive calm',
];
const POSE = [
  'three-quarter gaze toward soft light',
  'soft frontal presence, chin slightly lowered',
  'glance past the camera',
  'head tilted as if listening',
  'seated stillness, gaze off-axis',
];
const FRAME = [
  'head and upper chest, generous headroom',
  'three-quarter portrait, eyes in the upper third',
  'near-window close portrait, face fully inside',
  'slight shoulder turn, face clear of the edges',
];
const BACKGROUND = [
  'quiet interior with shallow depth of field',
  'soft window light and a blurred room',
  'evening room with one practical lamp',
  'muted terrace air, distant bokeh',
  'night interior, low lamps, no neon',
];
const WARDROBE = [
  'same styling energy, collar slightly open',
  'same styling energy, sleeves relaxed',
  'same styling energy, layer unbuttoned',
  'same styling energy, a quieter knit under it',
];
const LIGHT = [
  'soft key from camera-left, subtle rim on hair',
  'cool soft key with a gentle gold rim',
  'warm interior key, faint rim from the room',
  'window key, quiet shadow falloff',
];

export function portraitSeed(
  accountKey: string,
  presentation: PortraitPresentation,
): string {
  return createHash('sha256')
    .update(
      `oracly-soulmate-portrait-v${PORTRAIT_IDENTITY_VERSION}|${accountKey}|${presentation}`,
    )
    .digest('hex');
}

export function newRenderNonce(): string {
  return randomBytes(8).toString('hex');
}

export function alternateRenderNonce(nonce: string): string {
  return createHash('sha256')
    .update(`oracly-soulmate-render|${nonce}`)
    .digest('hex')
    .slice(0, 16);
}

export function coreFromSeed(
  seed: string,
  presentation: PortraitPresentation,
): SoulmatePortraitCore {
  const pick = (list: string[], at: number) =>
    list[Number.parseInt(seed.slice(at, at + 2), 16) % list.length]!;
  return {
    version: PORTRAIT_IDENTITY_VERSION,
    ageBand: pick(AGE, 0),
    faceShape: pick(FACE, 2),
    hairFamily: pick(HAIR, 4),
    hairLength: pick(LENGTH, 6),
    hairTexture: pick(TEXTURE, 8),
    eyePresentation: pick(EYES, 10),
    browStyle: pick(BROW, 12),
    skinToneRange: pick(SKIN, 14),
    facialHair:
      presentation === 'masculine' ? pick(BEARD, 16) : 'clean jawline, no beard',
    stylingEnergy: pick(STYLE, 18),
    expressionEnergy: pick(ENERGY, 20),
    visualMood: pick(MOOD, 22),
    distinguishingTrait: pick(TRAIT, 24),
    relationshipArchetype: pick(ARCHETYPE, 26),
  };
}

export function renderFromNonce(nonce: string): SoulmateRenderVariation {
  const n = Number.parseInt(nonce.slice(0, 4), 16);
  const index = Number.isFinite(n) ? n : 0;
  return {
    pose: POSE[index % POSE.length]!,
    framing: FRAME[(index >> 2) % FRAME.length]!,
    background: BACKGROUND[(index >> 4) % BACKGROUND.length]!,
    wardrobeDetail: WARDROBE[(index >> 6) % WARDROBE.length]!,
    lighting: LIGHT[(index >> 8) % LIGHT.length]!,
  };
}

/** Generic over the caller's core/profile shape — used today with
 * `SoulmateVisualProfile` (see ai/service.ts); a plain JSON hash needs no
 * knowledge of the specific fields. */
export function coreSignature(core: SoulmatePortraitCore | SoulmateVisualProfile): string {
  return createHash('sha256')
    .update(JSON.stringify(core))
    .digest('hex')
    .slice(0, 24);
}

export function coresEqual(
  a: SoulmatePortraitCore,
  b: SoulmatePortraitCore,
): boolean {
  return coreSignature(a) === coreSignature(b);
}

export function presenceFor(presentation: PortraitPresentation): string {
  if (presentation === 'feminine') return 'feminine-presenting adult';
  if (presentation === 'masculine') return 'masculine-presenting adult';
  return 'adult of unspecified presentation';
}
