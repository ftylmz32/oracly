import { sanitizeText } from './sanitize.js';
import {
  alternateRenderNonce,
  newRenderNonce,
  presenceFor,
  type PortraitPresentation,
} from './soulmate-portrait-identity.js';
import { buildSoulmatePortraitPrompt } from './soulmate-portrait-prompt-builder.js';
import {
  ARCHETYPE_LABEL,
  buildSoulmateVisualProfile,
  soulmatePortraitSeed,
  type SoulmateVisualProfile,
} from './soulmate-visual-profile.js';

export type SoulmatePromptInput = {
  name: string;
  birthDate: string;
  gender?: 'feminine' | 'masculine';
  intention?: string;
  accountKey?: string;
};

/**
 * Public portrait identity. `nonce`, `presence`, `mood` are required by the
 * client (see `SoulMateIdentity.fromMap`) and by the soulmate-interpretation
 * text prompt below — every other field is optional context, populated on a
 * best-effort basis from the new visual profile for continuity with
 * existing consumers (local cache, interpretation tone tags).
 */
export type SoulmateIdentity = {
  version: number;
  nonce: string;
  presence: string;
  mood: string;
  expression: string;
  wardrobe: string;
  ageBand: string;
  faceShape: string;
  hairFamily: string;
  eyePresentation: string;
  relationshipArchetype: string;
  expressionEnergy: string;
  stylingEnergy: string;
  contentHash?: string;
  // Legacy optional fields from the pre-signature-portrait identity shape
  // (render-variation-per-sitting concepts that no longer exist once every
  // visual dimension is locked to the deterministic profile). Kept optional,
  // never populated by the current builder, so validate-request.ts's
  // existing client-echo parser (shared across all AI operations) needs no
  // change to keep accepting an older cached client identity payload.
  colorFamily?: string;
  setting?: string;
  lighting?: string;
  composition?: string;
  pose?: string;
};

export type SoulmatePromptBuild = {
  prompt: string;
  nonce: string;
  identity: SoulmateIdentity;
  core: SoulmateVisualProfile;
  seed: string;
};

export function newSoulmateNonce(): string {
  return newRenderNonce();
}

export function nextSoulmateRenderNonce(nonce: string): string {
  return alternateRenderNonce(nonce);
}

export function soulmatePresence(gender?: 'feminine' | 'masculine'): string {
  return presenceFor(presentationOf(gender));
}

export function describeSoulmateIdentity(
  input: SoulmatePromptInput,
  nonce: string,
): SoulmateIdentity {
  const presentation = presentationOf(input.gender);
  const accountKey = input.accountKey?.trim() || 'anon';
  const seed = soulmatePortraitSeed(accountKey, presentation);
  const profile = buildSoulmateVisualProfile(seed, presentation);
  return toIdentity(profile, nonce);
}

export function buildSoulmateImagePrompt(
  input: SoulmatePromptInput,
  nonce = newRenderNonce(),
): SoulmatePromptBuild {
  const presentation = presentationOf(input.gender);
  const accountKey = input.accountKey?.trim() || 'anon';
  const seed = soulmatePortraitSeed(accountKey, presentation);
  const profile = buildSoulmateVisualProfile(seed, presentation);
  const identity = toIdentity(profile, nonce);
  const prompt = buildSoulmatePortraitPrompt(profile);
  return { prompt, nonce, identity, core: profile, seed };
}

function toIdentity(profile: SoulmateVisualProfile, nonce: string): SoulmateIdentity {
  const archetypeLabel = ARCHETYPE_LABEL[profile.archetype];
  return {
    version: profile.version,
    nonce,
    presence: presenceFor(profile.presentation),
    mood: archetypeLabel,
    expression: profile.expression,
    wardrobe: profile.clothing,
    ageBand: profile.ageDescriptor,
    faceShape: profile.faceShape,
    hairFamily: profile.hairTexture,
    eyePresentation: profile.eyeCharacter,
    relationshipArchetype: archetypeLabel,
    expressionEnergy: profile.expression,
    stylingEnergy: profile.linework,
  };
}

function presentationOf(gender?: string): PortraitPresentation {
  if (gender === 'feminine' || gender === 'masculine') return gender;
  return 'unspecified';
}

export function publicSoulmateIdentity(
  identity: SoulmateIdentity,
  contentHash: string,
): SoulmateIdentity {
  return {
    ...identity,
    contentHash,
    nonce: sanitizeText(identity.nonce, 32),
  };
}
