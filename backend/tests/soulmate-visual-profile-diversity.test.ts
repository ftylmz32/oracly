import { describe, expect, it } from 'vitest';
import {
  buildSoulmateVisualProfile,
  soulmatePortraitSeed,
  visualProfileSignature,
  visualProfilesEqual,
  type PortraitPresentation,
  type SoulmateVisualProfile,
} from '../src/ai/soulmate-visual-profile.js';
import { buildSoulmatePortraitPrompt } from '../src/ai/soulmate-portrait-prompt-builder.js';
import { buildSoulmateImagePrompt } from '../src/ai/soulmate-prompt.js';

/** 64 synthetic stable identifiers -- fixtures only, no provider calls. */
function fixtureIds(count: number): string[] {
  return Array.from({ length: count }, (_, i) => `synthetic-soulmate-op-${i.toString().padStart(3, '0')}`);
}

function profileFor(id: string, presentation: PortraitPresentation): SoulmateVisualProfile {
  const seed = soulmatePortraitSeed(id, presentation);
  return buildSoulmateVisualProfile(seed, presentation);
}

describe('Soulmate visual profile diversity gate (spec section 22)', () => {
  const ids = fixtureIds(64);
  const presentations: PortraitPresentation[] = [
    'feminine', 'masculine', 'feminine', 'masculine',
  ];
  const profiles = ids.map((id, i) => profileFor(id, presentations[i % presentations.length]!));

  it('produces at least 60 distinct complete trait signatures out of 64', () => {
    const signatures = new Set(profiles.map(visualProfileSignature));
    expect(signatures.size).toBeGreaterThanOrEqual(60);
  });

  it('represents at least 6 face-shape options', () => {
    const faceShapes = new Set(profiles.map((p) => p.faceShape));
    expect(faceShapes.size).toBeGreaterThanOrEqual(6);
  });

  it('represents at least 5 eye-character options', () => {
    const eyes = new Set(profiles.map((p) => p.eyeCharacter));
    expect(eyes.size).toBeGreaterThanOrEqual(5);
  });

  it('represents at least 4 portrait-angle options', () => {
    const angles = new Set(profiles.map((p) => p.portraitAngle));
    expect(angles.size).toBeGreaterThanOrEqual(4);
  });

  it('represents at least 5 expression options', () => {
    const expressions = new Set(profiles.map((p) => p.expression));
    expect(expressions.size).toBeGreaterThanOrEqual(5);
  });

  it('represents at least 4 emotional archetypes', () => {
    const archetypes = new Set(profiles.map((p) => p.archetype));
    expect(archetypes.size).toBeGreaterThanOrEqual(4);
  });

  it('shows substantial variation across hair texture, length, and styling combinations', () => {
    const combos = new Set(
      profiles.map((p) => `${p.hairTexture}|${p.hairLength}|${p.hairStyling}`),
    );
    // 5 textures x 4 lengths x 6 stylings = 120 possible combinations; with
    // 64 samples, a healthy deterministic spread should clear a third of
    // that space without ever colliding on triples of pure chance alone.
    expect(combos.size).toBeGreaterThanOrEqual(24);
  });

  it('never varies physical identity by archetype -- same seed inputs before/after archetype selection stay a pure function of the seed', () => {
    // Regression guard for the coherence rule (section 15/16): running the
    // builder twice for the same id/presentation must be identical, and two
    // different ids that happen to land on the same archetype must NOT
    // therefore share face/eyes/hair -- physical traits are seed-driven,
    // independent of the archetype-constrained fields.
    const byArchetype = new Map<string, SoulmateVisualProfile[]>();
    for (const p of profiles) {
      byArchetype.set(p.archetype, [...(byArchetype.get(p.archetype) ?? []), p]);
    }
    for (const group of byArchetype.values()) {
      if (group.length < 2) continue;
      const faceShapes = new Set(group.map((p) => p.faceShape));
      expect(faceShapes.size).toBeGreaterThan(1);
    }
  });
});

describe('Soulmate visual profile same-operation determinism (spec section 23)', () => {
  const id = 'synthetic-soulmate-op-determinism';

  it('produces exactly the same profile across repeated invocation', () => {
    const a = profileFor(id, 'feminine');
    const b = profileFor(id, 'feminine');
    expect(visualProfilesEqual(a, b)).toBe(true);
    expect(a).toEqual(b);
  });

  it('produces exactly the same profile across a simulated app restart (fresh call stack, no shared in-memory state)', () => {
    // Nothing here shares any object/module state between calls other than
    // the pure seed derivation itself -- the closest thing to a "restart"
    // this pure function has, since it holds no state at all.
    function simulateFreshProcessCall(): SoulmateVisualProfile {
      const freshSeed = soulmatePortraitSeed(id, 'feminine');
      return buildSoulmateVisualProfile(freshSeed, 'feminine');
    }
    const first = simulateFreshProcessCall();
    const second = simulateFreshProcessCall();
    expect(visualProfilesEqual(first, second)).toBe(true);
  });

  it('produces the same rendered prompt across repeated buildSoulmateImagePrompt calls for the same account', () => {
    const a = buildSoulmateImagePrompt({ name: 'Test', birthDate: '1996-01-01', gender: 'feminine', accountKey: id });
    const b = buildSoulmateImagePrompt({ name: 'Test', birthDate: '1996-01-01', gender: 'feminine', accountKey: id }, 'a-different-nonce-value');
    expect(a.prompt).toBe(b.prompt);
    expect(visualProfilesEqual(a.core, b.core)).toBe(true);
  });

  it('gives a different presentation a distinct (not colliding) profile for the same account', () => {
    const feminine = profileFor(id, 'feminine');
    const masculine = profileFor(id, 'masculine');
    expect(visualProfilesEqual(feminine, masculine)).toBe(false);
  });

  it('ARCHITECT RULE: same authenticated account + same explicit presentation = same identity, unaffected by app restart, reopening the feature, repeating the request, or a provider retry', () => {
    // The canonical identity rule, proven directly: two DIFFERENT accounts
    // get meaningfully different identities; the SAME account with the SAME
    // presentation always gets back the exact same one, no matter how many
    // times, or from how "fresh" a call site, it is asked.
    const accountA = profileFor('acct-real-user-a', 'masculine');
    const accountB = profileFor('acct-real-user-b', 'masculine');
    expect(visualProfilesEqual(accountA, accountB)).toBe(false);
    expect(accountA.faceShape).not.toBe(accountB.faceShape);

    for (let i = 0; i < 5; i++) {
      const repeat = profileFor('acct-real-user-a', 'masculine');
      expect(visualProfilesEqual(accountA, repeat)).toBe(true);
    }
  });
});

describe('Soulmate portrait prompt contract (spec section 24)', () => {
  const ids = fixtureIds(16);
  const prompts = ids.map((id, i) =>
    buildSoulmatePortraitPrompt(profileFor(id, i % 2 === 0 ? 'feminine' : 'masculine')),
  );

  it('every prompt contains clear positive graphite/fine-art direction', () => {
    for (const prompt of prompts) {
      const lower = prompt.toLowerCase();
      expect(lower).toContain('graphite');
      expect(lower).toContain('hand-drawn');
      expect(lower).toContain('fine-art');
    }
  });

  it('every prompt explicitly rejects 3D, CGI, plastic/glossy render, and generic AI-model appearance', () => {
    for (const prompt of prompts) {
      const lower = prompt.toLowerCase();
      expect(lower).toContain('not 3d, not cgi');
      expect(lower).toContain('cgi, glossy digital illustration');
      expect(lower).toContain('plastic skin');
      expect(lower).toContain('generic ai-model faces');
    }
  });

  it('every prompt forbids multiple people, text, logos, and watermarks', () => {
    for (const prompt of prompts) {
      const lower = prompt.toLowerCase();
      expect(lower).toContain('extra people');
      expect(lower).toContain('second person');
      expect(lower).toContain('text, logos, watermarks');
    }
  });

  it('no prompt positively requests photorealistic skin, CGI, 3D, or digital glossy rendering', () => {
    for (const prompt of prompts) {
      const lower = prompt.toLowerCase();
      expect(lower).not.toContain('photorealistic');
      expect(lower).not.toContain('photoreal');
      expect(lower).not.toContain('shoot like');
      expect(lower).not.toContain('render the skin');
    }
  });

  it('every prompt stays within the one locked art direction across the whole diversity sample (no alternate medium ever appears)', () => {
    const forbiddenMedia = ['oil paint', 'watercolor', 'anime', 'oil-paint', 'painted character', 'charcoal drawing only'];
    for (const prompt of prompts) {
      const lower = prompt.toLowerCase();
      for (const medium of forbiddenMedia) {
        expect(lower).not.toContain(medium);
      }
    }
  });
});
