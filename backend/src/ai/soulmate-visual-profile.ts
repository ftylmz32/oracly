/**
 * Soulmate Signature Premium Portrait System — deterministic identity layer.
 *
 * Architect-locked specification. This file implements ONLY the trait
 * pools, emotional archetypes, and deterministic seed -> profile mapping
 * exactly as specified. It does not decide art direction — see
 * `soulmate-portrait-prompt-builder.ts` for the master prompt that renders
 * this profile.
 *
 * SEED (spec section 10): SHA-256("oracly:soulmate:portrait:v2:" + stable
 * identifier). The current Soulmate flow (`soulmate_draw` in ai/service.ts)
 * is a stateless `/v1/ai/complete` call with no ReadingOperation/operationId
 * — there is no `stableOperationId` at the point traits are built. Per the
 * spec's own fallback ("use the closest existing stable reading
 * identifier"), the authenticated account key is used instead — the same
 * stable source the pre-existing Soulmate identity system already used.
 * Presentation is folded in alongside it (as the prior system already did)
 * so an explicit presence change yields a fresh — not colliding — profile;
 * no trait pool below is itself gender-restricted.
 */
import { createHash } from 'node:crypto';
import type { PortraitPresentation } from './soulmate-portrait-identity.js';

export type { PortraitPresentation };

export const SOULMATE_VISUAL_PROFILE_VERSION = 2;

export type EmotionalArchetype =
  | 'calm_deep'
  | 'warm_protective'
  | 'creative_free'
  | 'quietly_confident'
  | 'playful_balanced'
  | 'mature_grounded'
  | 'mysterious_introspective'
  | 'romantic_gentle';

export type OptionalDetail =
  | 'none'
  | 'understated_earring'
  | 'simple_necklace'
  | 'subtle_eyeglasses';

/** One coherent, deterministic identity — spec sections 9, 13–19. */
export type SoulmateVisualProfile = {
  version: number;
  presentation: PortraitPresentation;
  ageDescriptor: string;
  faceShape: string;
  eyeCharacter: string;
  eyebrows: string;
  nose: string;
  lips: string;
  jawChin: string;
  hairTexture: string;
  hairLength: string;
  hairStyling: string;
  expression: string;
  portraitAngle: string;
  gaze: string;
  linework: string;
  archetype: EmotionalArchetype;
  clothing: string;
  optionalDetail: OptionalDetail;
};

// ---------------------------------------------------------------------------
// Locked trait pools — spec section 13. Verbatim option text.
// ---------------------------------------------------------------------------

const FACE_SHAPE = [
  'balanced oval',
  'soft heart-shaped',
  'softly angular',
  'long oval',
  'gentle diamond',
  'softly rectangular',
  'rounded oval',
] as const;

const EYE_CHARACTER = [
  'softly almond-shaped',
  'deep-set and calm',
  'slightly hooded',
  'open and warm',
  'narrow and quietly intense',
  'balanced round-almond',
] as const;

const EYEBROWS = [
  'naturally straight',
  'soft arch',
  'defined natural arch',
  'fuller natural brow',
  'fine understated brow',
] as const;

const NOSE = [
  'straight natural bridge',
  'softly rounded tip',
  'subtle aquiline character',
  'narrow refined bridge',
  'broader natural structure',
] as const;

const LIPS = [
  'balanced natural lips',
  'softly full lips',
  "defined cupid's bow",
  'slightly fuller lower lip',
  'understated medium lips',
] as const;

const JAW_CHIN = [
  'softly defined jaw',
  'clean tapered jaw',
  'moderately angular jaw',
  'broad but gentle jaw',
  'subtle rounded jaw',
] as const;

const HAIR_TEXTURE = [
  'straight',
  'softly wavy',
  'defined wavy',
  'loose curls',
  'textured natural hair',
] as const;

const HAIR_LENGTH = ['short', 'medium', 'medium-long', 'long'] as const;

const HAIR_STYLING = [
  'naturally parted',
  'softly swept',
  'relaxed textured',
  'understated layered',
  'slightly tousled but elegant',
  'clean and simple',
] as const;

const EXPRESSION = [
  'calm neutral warmth',
  'faint restrained smile',
  'quiet confidence',
  'thoughtful softness',
  'gentle direct warmth',
  'introspective calm',
] as const;

const PORTRAIT_ANGLE = [
  'almost frontal with a subtle turn',
  'a gentle three-quarter turn to the left',
  'a gentle three-quarter turn to the right',
  'shoulders angled, face returning toward the viewer',
  'a subtle head tilt with natural posture',
] as const;

const GAZE = [
  'direct but soft',
  'slightly off-camera',
  'a reflective side gaze',
  'quiet eye contact',
  'a gently lowered then forward-feeling gaze',
] as const;

const LINEWORK = [
  'fine refined graphite',
  'refined graphite with subtle cross-hatching',
  'soft graphite realism',
  'graphite with restrained charcoal depth',
] as const;

// Section 12 — age direction: tasteful adult appearance roughly 25–35,
// subtle variation only, never a gimmick.
const AGE_DESCRIPTOR = [
  'an adult in their mid-twenties',
  'an adult in their late twenties',
  'an adult in their early thirties',
] as const;

// Section 19 — understated, timeless clothing only.
const CLOTHING = [
  'a simple knit top',
  'a plain collared shirt',
  'a clean blouse',
  'an understated collared top',
  'a simple dark neutral garment',
  'a simple light neutral garment',
] as const;

// Section 18 — optional details, strictly limited and low-probability.
const OPTIONAL_DETAIL: readonly OptionalDetail[] = [
  'understated_earring',
  'simple_necklace',
  'subtle_eyeglasses',
];

export const OPTIONAL_DETAIL_TEXT: Record<OptionalDetail, string> = {
  none: '',
  understated_earring: 'a small understated earring',
  simple_necklace: 'a simple thin chain necklace',
  subtle_eyeglasses: 'subtle eyeglasses',
};

// ---------------------------------------------------------------------------
// Locked emotional archetypes — spec section 16. One of these eight only.
// ---------------------------------------------------------------------------

export const EMOTIONAL_ARCHETYPES: readonly EmotionalArchetype[] = [
  'calm_deep',
  'warm_protective',
  'creative_free',
  'quietly_confident',
  'playful_balanced',
  'mature_grounded',
  'mysterious_introspective',
  'romantic_gentle',
];

/** Verbatim visual direction per archetype, condensed to flowing prose. */
export const ARCHETYPE_VISUAL_DIRECTION: Record<EmotionalArchetype, string> = {
  calm_deep:
    'a relaxed gaze, a quiet expression, balanced composition, softer graphite shadow transitions, and an introspective feeling',
  warm_protective:
    'gentle eye contact, subtle warmth around the mouth, a grounded posture, and a balanced, confident composition',
  creative_free:
    'a slightly more dynamic portrait angle, expressive brows and eyes, relaxed hair styling, and a lighter visual energy',
  quietly_confident:
    'a steady gaze, clean composition, a controlled expression, and a slightly stronger tonal structure',
  playful_balanced:
    'a faint restrained smile, brighter eyes, a lighter graphite touch, and a natural, relaxed posture',
  mature_grounded:
    'a composed posture, stable framing, neutral warmth, and understated styling',
  mysterious_introspective:
    'a subtle side gaze, deeper graphite shadows, a restrained expression, and a quiet emotional distance',
  romantic_gentle:
    'a soft eye expression, delicate shading, an intimate composition, and a warm, understated emotional presence',
};

/**
 * Coherence rule (spec section 15/16): archetype constrains the EMOTIONAL
 * fields (expression, gaze, linework depth) to the subset of the locked
 * pool that is already implied by that archetype's own stated visual
 * direction above — it never touches physical identity (face/eyes/brows/
 * nose/lips/jaw/hair). Indexes are into EXPRESSION / GAZE / LINEWORK.
 */
const ARCHETYPE_EXPRESSION_SUBSET: Record<EmotionalArchetype, number[]> = {
  calm_deep: [0, 3, 5],
  warm_protective: [4, 0, 2],
  creative_free: [1, 4],
  quietly_confident: [2, 0],
  playful_balanced: [1],
  mature_grounded: [0, 2],
  mysterious_introspective: [5, 3],
  romantic_gentle: [3, 4],
};

const ARCHETYPE_GAZE_SUBSET: Record<EmotionalArchetype, number[]> = {
  calm_deep: [0, 3, 4],
  warm_protective: [3, 0],
  creative_free: [1, 0],
  quietly_confident: [3, 0],
  playful_balanced: [0, 1],
  mature_grounded: [0, 3],
  mysterious_introspective: [2, 1],
  romantic_gentle: [4, 0],
};

const ARCHETYPE_LINEWORK_SUBSET: Record<EmotionalArchetype, number[]> = {
  calm_deep: [2, 0],
  warm_protective: [1, 2],
  creative_free: [0, 2],
  quietly_confident: [3, 1],
  playful_balanced: [0, 2],
  mature_grounded: [1, 3],
  mysterious_introspective: [3, 1],
  romantic_gentle: [2, 0],
};

export const ARCHETYPE_LABEL: Record<EmotionalArchetype, string> = {
  calm_deep: 'Calm / Deep',
  warm_protective: 'Warm / Protective',
  creative_free: 'Creative / Free',
  quietly_confident: 'Quietly Confident',
  playful_balanced: 'Playful / Balanced',
  mature_grounded: 'Mature / Grounded',
  mysterious_introspective: 'Mysterious / Introspective',
  romantic_gentle: 'Romantic / Gentle',
};

// ---------------------------------------------------------------------------
// Deterministic seed -> profile
// ---------------------------------------------------------------------------

/** Spec section 10 canonical construction, extended with presentation so an
 * explicit presence change yields a distinct (not colliding) profile. */
export function soulmatePortraitSeed(
  stableIdentifier: string,
  presentation: PortraitPresentation,
): string {
  return createHash('sha256')
    .update(`oracly:soulmate:portrait:v${SOULMATE_VISUAL_PROFILE_VERSION}:${stableIdentifier}|${presentation}`)
    .digest('hex');
}

function byteAt(seedHex: string, offset: number): number {
  return Number.parseInt(seedHex.slice(offset, offset + 2), 16);
}

function pick<T>(pool: readonly T[], seedHex: string, offset: number): T {
  return pool[byteAt(seedHex, offset) % pool.length]!;
}

function pickFromSubset<T>(
  pool: readonly T[],
  subset: readonly number[],
  seedHex: string,
  offset: number,
): T {
  const index = subset[byteAt(seedHex, offset) % subset.length]!;
  return pool[index]!;
}

export function buildSoulmateVisualProfile(
  seedHex: string,
  presentation: PortraitPresentation,
): SoulmateVisualProfile {
  // Physical identity (A–I): pure seed, never touched by archetype.
  const faceShape = pick(FACE_SHAPE, seedHex, 0);
  const eyeCharacter = pick(EYE_CHARACTER, seedHex, 2);
  const eyebrows = pick(EYEBROWS, seedHex, 4);
  const nose = pick(NOSE, seedHex, 6);
  const lips = pick(LIPS, seedHex, 8);
  const jawChin = pick(JAW_CHIN, seedHex, 10);
  const hairTexture = pick(HAIR_TEXTURE, seedHex, 12);
  const hairLength = pick(HAIR_LENGTH, seedHex, 14);
  const hairStyling = pick(HAIR_STYLING, seedHex, 16);

  // Archetype first — expression/gaze/linework are coherence-constrained by it.
  const archetype = pick(EMOTIONAL_ARCHETYPES, seedHex, 26);

  const portraitAngle = pick(PORTRAIT_ANGLE, seedHex, 20);
  const expression = pickFromSubset(
    EXPRESSION,
    ARCHETYPE_EXPRESSION_SUBSET[archetype],
    seedHex,
    18,
  );
  const gaze = pickFromSubset(GAZE, ARCHETYPE_GAZE_SUBSET[archetype], seedHex, 22);
  const linework = pickFromSubset(
    LINEWORK,
    ARCHETYPE_LINEWORK_SUBSET[archetype],
    seedHex,
    24,
  );

  const ageDescriptor = pick(AGE_DESCRIPTOR, seedHex, 28);
  const clothing = pick(CLOTHING, seedHex, 34);

  // Section 18: strictly limited, low probability (~1 in 6 -> ~16%).
  const detailGate = byteAt(seedHex, 30) % 6;
  const optionalDetail: OptionalDetail =
    detailGate === 0 ? pick(OPTIONAL_DETAIL, seedHex, 32) : 'none';

  return {
    version: SOULMATE_VISUAL_PROFILE_VERSION,
    presentation,
    ageDescriptor,
    faceShape,
    eyeCharacter,
    eyebrows,
    nose,
    lips,
    jawChin,
    hairTexture,
    hairLength,
    hairStyling,
    expression,
    portraitAngle,
    gaze,
    linework,
    archetype,
    clothing,
    optionalDetail,
  };
}

export function visualProfileSignature(profile: SoulmateVisualProfile): string {
  return createHash('sha256').update(JSON.stringify(profile)).digest('hex').slice(0, 24);
}

export function visualProfilesEqual(
  a: SoulmateVisualProfile,
  b: SoulmateVisualProfile,
): boolean {
  return visualProfileSignature(a) === visualProfileSignature(b);
}
