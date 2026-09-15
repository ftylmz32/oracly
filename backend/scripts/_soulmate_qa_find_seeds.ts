import { soulmatePortraitSeed, buildSoulmateVisualProfile, type EmotionalArchetype, type PortraitPresentation } from '../src/ai/soulmate-visual-profile.js';

const targets: { label: string; presentation: PortraitPresentation; archetype: EmotionalArchetype }[] = [
  { label: 'A', presentation: 'masculine', archetype: 'calm_deep' },
  { label: 'B', presentation: 'masculine', archetype: 'creative_free' },
  { label: 'C', presentation: 'feminine', archetype: 'warm_protective' },
  { label: 'D', presentation: 'feminine', archetype: 'mysterious_introspective' },
];

for (const t of targets) {
  let foundKey: string | null = null;
  let foundProfile = null;
  for (let i = 0; i < 5000; i++) {
    const accountKey = `qa-soulmate-fixture-${t.label}-${i}`;
    const seed = soulmatePortraitSeed(accountKey, t.presentation);
    const profile = buildSoulmateVisualProfile(seed, t.presentation);
    if (profile.archetype === t.archetype) {
      foundKey = accountKey;
      foundProfile = profile;
      break;
    }
  }
  if (!foundKey) {
    console.log(t.label, 'NOT FOUND in 5000 tries');
    continue;
  }
  console.log(t.label, JSON.stringify({ accountKey: foundKey, ...foundProfile }));
}
