import {
  buildSoulmateVisualProfile,
  soulmatePortraitSeed,
  visualProfileSignature,
  type PortraitPresentation,
  type SoulmateVisualProfile,
} from '../src/ai/soulmate-visual-profile.js';

const presentations: PortraitPresentation[] = ['feminine', 'masculine', 'feminine', 'masculine'];
const profiles: SoulmateVisualProfile[] = [];
for (let i = 0; i < 64; i++) {
  const id = 'synthetic-soulmate-op-' + String(i).padStart(3, '0');
  const presentation = presentations[i % presentations.length]!;
  const seed = soulmatePortraitSeed(id, presentation);
  profiles.push(buildSoulmateVisualProfile(seed, presentation));
}

function count<K extends keyof SoulmateVisualProfile>(key: K): number {
  return new Set(profiles.map((p) => p[key])).size;
}

const sig = new Set(profiles.map(visualProfileSignature));
const hairCombos = new Set(profiles.map((p) => `${p.hairTexture}|${p.hairLength}|${p.hairStyling}`));
const withDetail = profiles.filter((p) => p.optionalDetail !== 'none').length;

console.log(JSON.stringify({
  distinctSignatures: sig.size,
  totalProfiles: profiles.length,
  faceShapes: count('faceShape'),
  eyeCharacter: count('eyeCharacter'),
  eyebrows: count('eyebrows'),
  nose: count('nose'),
  lips: count('lips'),
  jawChin: count('jawChin'),
  hairTexture: count('hairTexture'),
  hairLength: count('hairLength'),
  hairStyling: count('hairStyling'),
  hairCombinations: hairCombos.size,
  expression: count('expression'),
  portraitAngle: count('portraitAngle'),
  gaze: count('gaze'),
  linework: count('linework'),
  archetype: count('archetype'),
  profilesWithOptionalDetail: withDetail,
}, null, 2));
