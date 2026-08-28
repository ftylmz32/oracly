import { randomBytes } from 'node:crypto';
import { sanitizeText } from './sanitize.js';
import {
  visualProfileFromBirthDate,
  type SoulmateVisualProfile,
} from './soulmate-profile.js';

export type SoulmatePromptInput = {
  name: string;
  birthDate: string;
  gender?: 'feminine' | 'masculine';
  intention?: string;
};

export type SoulmatePromptBuild = {
  prompt: string;
  nonce: string;
  profile: SoulmateVisualProfile;
};

const VARIATION = [
  {
    pose: 'three-quarter gaze toward left light, calm confidence',
    expression: 'natural, slightly mysterious, not smiling at camera',
    detail: 'visible skin microtexture, natural hair strands',
  },
  {
    pose: 'soft frontal presence, chin slightly lowered',
    expression: 'quiet composure, eyes alive but unforced',
    detail: 'believable pores and soft catchlights, no plastic skin',
  },
  {
    pose: 'profile turning slowly into key light',
    expression: 'inward calm, mouth relaxed',
    detail: 'correct ear and neck anatomy, real fabric folds',
  },
  {
    pose: 'glance past the camera, unhurried',
    expression: 'slight mystery, no posed smile',
    detail: 'asymmetry kept natural; no perfect mirrored face',
  },
  {
    pose: 'look over the near shoulder toward rim light',
    expression: 'restrained warmth without grinning',
    detail: 'hands only if fully correct — five fingers, real joints',
  },
  {
    pose: 'head tilted as if listening',
    expression: 'thoughtful stillness',
    detail: 'natural eyebrows and lashes, no AI-smooth glaze',
  },
  {
    pose: 'seated stillness, gaze gently off-axis',
    expression: 'calm confidence',
    detail: 'wardrobe sits on real shoulders; no fantasy costume',
  },
  {
    pose: 'eyes half-lidded, soft breath in the face',
    expression: 'intimate quiet, never theatrical',
    detail: 'cinematic shallow depth, background softly out of focus',
  },
];

export function newSoulmateNonce(): string {
  return randomBytes(8).toString('hex');
}

export function soulmateVariation(nonce: string): (typeof VARIATION)[number] {
  const n = Number.parseInt(nonce.slice(0, 4), 16);
  const index = Number.isFinite(n) ? n % VARIATION.length : 0;
  return VARIATION[index] ?? VARIATION[0]!;
}

export function buildSoulmateImagePrompt(
  input: SoulmatePromptInput,
  nonce = newSoulmateNonce(),
): SoulmatePromptBuild {
  const profile = visualProfileFromBirthDate(input.birthDate);
  const variation = soulmateVariation(nonce);
  const presence =
    input.gender === 'feminine'
      ? 'feminine-presenting adult'
      : input.gender === 'masculine'
        ? 'masculine-presenting adult'
        : 'adult of unspecified presentation';
  const name = sanitizeText(input.name, 80);
  const intention = sanitizeText(input.intention ?? '', 200);
  const prompt = [
    'Photorealistic cinematic portrait photograph — editorial luxury still, not illustration.',
    'This is a creative, symbolic companion image — not a real person, a prediction, or a future partner.',
    'Shoot like premium film photography: photoreal skin, eyes, hair, clothing, and body proportions.',
    'Natural skin texture with subtle pores; no porcelain, no over-smoothed plastic face.',
    'Natural eye asymmetry; realistic lashes; no glassy AI eyes.',
    'If hands appear: anatomically correct, five fingers, no distortion — otherwise keep hands out of frame.',
    'Lighting: soft key light plus subtle rim light; warm gold and violet environmental balance; no neon.',
    'Expression: emotionally subtle — calm confidence and slight mystery. Avoid a generic smile-at-camera.',
    'Wardrobe: contemporary and believable everyday clothing. No costume, fantasy armor, or mystical robes.',
    'Background: photoreal atmospheric environment with shallow depth of field — never a flat studio void.',
    'Composition: face fully inside the frame with headroom; never crop through eyes, forehead, or chin.',
    'No text, watermark, logo, hearts, sparkles, cartoon effects, celebrity likeness, or stock-template face.',
    `Presence: a calm ${presence}.`,
    `Color family: ${profile.colorFamily}.`,
    `Mood: ${profile.mood}.`,
    `Setting: ${profile.setting}.`,
    `Light: ${profile.lighting}.`,
    `Wardrobe: ${profile.wardrobe}.`,
    `Composition: ${profile.composition}.`,
    `Pose: ${variation.pose}.`,
    `Expression: ${variation.expression}.`,
    `Craft detail: ${variation.detail}.`,
    name ? `Given-name inspiration only — never paint letters: ${name}.` : '',
    intention
      ? `Quiet intention may tint mood only, never literal props of text: ${intention}.`
      : '',
    `Unrepeatable sitting reference for composition only, never visible as text: ${nonce}.`,
  ]
    .filter(Boolean)
    .join(' ');
  return { prompt, nonce, profile };
}
