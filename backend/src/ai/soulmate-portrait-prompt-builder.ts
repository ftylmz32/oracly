/**
 * Soulmate Signature Premium Portrait System — master prompt builder.
 *
 * Architect-locked creative content (spec section 20). This renders a
 * `SoulmateVisualProfile` into the runtime image-generation prompt. The
 * creative MASTER INTENT text below is reproduced from the specification;
 * only syntax/punctuation was adjusted to integrate variables. No new
 * artistic concept, medium, or direction is introduced here.
 */
import { presenceFor } from './soulmate-portrait-identity.js';
import {
  ARCHETYPE_VISUAL_DIRECTION,
  OPTIONAL_DETAIL_TEXT,
  type SoulmateVisualProfile,
} from './soulmate-visual-profile.js';

/** Section 8 — explicit, positive rejection of the forbidden aesthetics. */
const FORBIDDEN_AESTHETICS =
  'Strictly avoid 3D rendering, CGI, glossy digital illustration, plastic skin, ' +
  'waxy skin, video-game character aesthetics, cinematic 3D character rendering, ' +
  'Pixar-like or animation rendering, digital fantasy portrait effects, ' +
  'hyper-polished synthetic faces, beauty-advertisement or stock-photo faces, ' +
  'generic AI-model faces, airbrushed synthetic shading, a photograph with a ' +
  'sketch filter applied, a repeated template face, neon lighting, glowing eyes ' +
  'or supernatural visual effects, zodiac symbols, hearts, glowing particles, ' +
  'magical portals, tarot symbols, mystical clip art, cosmic backgrounds, extra ' +
  'people, a second person, a couple, a silhouette, visible hands, text, logos, ' +
  'watermarks, decorative frames, malformed facial anatomy, duplicated facial ' +
  'features, or unfinished rough-sketch quality.';

function identityDirection(profile: SoulmateVisualProfile): string {
  const presence = presenceFor(profile.presentation);
  const hair = `${profile.hairLength}, ${profile.hairTexture} hair, styled ${profile.hairStyling}`;
  const detail =
    profile.optionalDetail === 'none'
      ? ''
      : `, wearing ${OPTIONAL_DETAIL_TEXT[profile.optionalDetail]}`;
  return (
    `${profile.ageDescriptor}, a ${presence} with a ${profile.faceShape} face shape, ` +
    `${profile.eyeCharacter} eyes with ${profile.eyebrows} eyebrows, a ${profile.nose} nose, ` +
    `${profile.lips}, and a ${profile.jawChin}. Hair: ${hair}. ` +
    `Wearing ${profile.clothing}${detail}, kept understated and timeless with no logos or text.`
  );
}

/**
 * Builds the exact runtime prompt for one Soulmate portrait render.
 * Pure function of the profile — independently testable without calling
 * the image provider (spec section 33).
 */
export function buildSoulmatePortraitPrompt(profile: SoulmateVisualProfile): string {
  return [
    'Create a finished premium graphite pencil portrait of one adult person, ' +
      'rendered as a sophisticated hand-drawn fine-art commission on subtle ' +
      'archival drawing paper.',
    'The portrait must unmistakably look hand-drawn in graphite — not 3D, not ' +
      'CGI, not a digital render, not a photograph with a sketch filter.',
    'Use refined HB-to-soft-graphite linework, natural pencil texture, ' +
      'controlled cross-hatching, soft tonal blending, realistic facial anatomy, ' +
      'subtle hand-made stroke variation and restrained deep graphite shadows.',
    'Frame the subject as a head-and-shoulders or upper-bust portrait in a ' +
      'vertical composition. Keep the face fully visible, anatomically clean and ' +
      'emotionally expressive. Avoid hands and additional people.',
    `Identity direction: ${identityDirection(profile)}`,
    `Emotional direction: ${ARCHETYPE_VISUAL_DIRECTION[profile.archetype]}.`,
    `Portrait angle: ${profile.portraitAngle}.`,
    `Gaze: ${profile.gaze}.`,
    `Linework: ${profile.linework}.`,
    'The person should look naturally attractive and individual rather than ' +
      'like a generic AI beauty model. Preserve believable human proportions ' +
      'and subtle natural asymmetry.',
    'Use a clean warm-white paper background with only a restrained graphite ' +
      'vignette or faint graphite haze. The face must remain the clear focal point.',
    'The finished result should feel like a high-end commissioned portrait: ' +
      'intimate, elegant, soulful, romantic in an understated way, slightly ' +
      'mysterious and worthy of a premium product.',
    FORBIDDEN_AESTHETICS,
    'This is a creative symbolic companion image, not a real person, a ' +
      'prediction, or a future partner.',
  ].join(' ');
}
