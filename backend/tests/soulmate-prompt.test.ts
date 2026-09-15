import { beforeEach, describe, expect, it } from 'vitest';
import { createHash } from 'node:crypto';
import {
  coreFromSeed,
  coresEqual,
  portraitSeed,
} from '../src/ai/soulmate-portrait-identity.js';
import {
  buildSoulmateImagePrompt,
  newSoulmateNonce,
} from '../src/ai/soulmate-prompt.js';
import { resetSoulmateUniquenessIndex } from '../src/ai/soulmate-uniqueness-index.js';
import {
  authHeader,
  openaiImage,
  soulmateBody,
  testApp,
  testConfig,
} from './helpers.js';

const USER_A = { name: 'Asel', birthDate: '2019-05-26', gender: 'feminine' as const };
const USER_B = { name: 'Deniz', birthDate: '1995-08-15', gender: 'masculine' as const };

describe('soulmate prompt personalization', () => {
  beforeEach(() => {
    resetSoulmateUniquenessIndex();
  });

  it('keeps the same account on one core identity', () => {
    const seed = portraitSeed('acct-a', 'feminine');
    const first = coreFromSeed(seed, 'feminine');
    const second = coreFromSeed(seed, 'feminine');
    expect(coresEqual(first, second)).toBe(true);
    const again = portraitSeed('acct-a', 'feminine');
    expect(coreFromSeed(again, 'feminine')).toEqual(first);
  });

  it('issues a new nonce for every draw, while the identity-locked prompt itself stays stable for the same user', () => {
    const first = buildSoulmateImagePrompt(USER_A);
    const second = buildSoulmateImagePrompt(USER_A);
    expect(first.nonce).not.toBe(second.nonce);
    expect(first.nonce).toHaveLength(16);
    expect(second.nonce).toHaveLength(16);
    // Every visual dimension is locked to the deterministic per-account seed,
    // not the render nonce -- see soulmate-uniqueness.test.ts's dedicated
    // determinism test for the full rationale.
    expect(first.prompt).toBe(second.prompt);
    expect(newSoulmateNonce()).not.toBe(newSoulmateNonce());
  });

  it('lets user inputs change the prompt, not only the nonce', () => {
    const nonce = 'aaaaaaaaaaaaaaaa';
    const a = buildSoulmateImagePrompt(USER_A, nonce);
    const b = buildSoulmateImagePrompt(USER_B, nonce);
    expect(a.nonce).toBe(b.nonce);
    expect(a.prompt).not.toBe(b.prompt);
    expect(a.prompt).toContain('Identity direction');
    expect(b.prompt).toContain('Identity direction');
    expect(a.prompt).not.toContain('Asel');
    expect(b.prompt).not.toContain('Deniz');
    expect(a.prompt).not.toContain(USER_A.birthDate);
    expect(b.prompt).not.toContain(USER_B.birthDate);
    expect(a.identity.presence).not.toBe(b.identity.presence);
    expect(a.identity.faceShape).toBeTruthy();
  });

  it('never places a firebase uid or client user id in the prompt', () => {
    const built = buildSoulmateImagePrompt({
      ...USER_A,
      name: 'asel@example.com',
      accountKey: 'sub:firebase-uid-user-1',
    });
    expect(built.prompt.toLowerCase()).not.toContain('uid');
    expect(built.prompt).not.toContain('user-1');
    expect(built.prompt).not.toContain('asel@example.com');
    expect(built.prompt).not.toContain(built.seed);
    expect(built.prompt).not.toMatch(/firebase/i);
  });

  it('reads as a graphite pencil portrait and explicitly rejects 3D/CGI/photographic aesthetics', () => {
    const built = buildSoulmateImagePrompt(USER_A);
    const lower = built.prompt.toLowerCase();
    expect(lower).toContain('graphite');
    expect(lower).toContain('hand-drawn');
    expect(lower).toContain('pencil');
    expect(lower).not.toContain('photorealistic');
    expect(lower).not.toContain('film photography');
    // "photograph" only ever appears inside an explicit rejection phrase
    // (spec section 3), never as a positive instruction to render one.
    expect(lower).toContain('not a photograph with a sketch filter');
    expect(lower).not.toContain('shoot like');
    expect(lower).not.toContain('photoreal');
    expect(lower).toContain('not 3d, not cgi');
    expect(lower).toContain('strictly avoid 3d rendering, cgi');
    expect(lower).toContain('plastic skin');
    expect(lower).toContain('generic ai-model faces');
    expect(lower).toContain('sketch filter');
  });

  it('routes two users through soulmate_draw with different prompt signatures', async () => {
    const seen: string[] = [];
    const fetchImpl: typeof fetch = async (url, init) => {
      const body = JSON.parse(String(init?.body ?? '{}')) as {
        prompt?: string;
        seed?: unknown;
      };
      expect(body.seed).toBeUndefined();
      if (body.prompt) seen.push(body.prompt);
      return openaiImage()(url, init);
    };
    const app = await testApp(testConfig(), fetchImpl);
    for (const payload of [USER_A, USER_B]) {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: authHeader(),
        payload: {
          operation: 'soulmate_draw',
          payload: {
            ...payload,
            userId: 'firebase-uid-must-never-appear',
            user_id: 'firebase-uid-must-never-appear',
          },
        },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().data.operation).toBe('soulmate_draw');
    }
    expect(seen).toHaveLength(2);
    expect(seen[0]).not.toBe(seen[1]);
    expect(signature(seen[0]!)).not.toBe(signature(seen[1]!));
    expect(seen.join('\n')).not.toContain('firebase-uid-must-never-appear');
    await app.close();
  });

  it('keeps auth and image envelope intact on personalized draws', async () => {
    const app = await testApp(testConfig(), openaiImage());
    const denied = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: soulmateBody,
    });
    expect(denied.statusCode).toBe(401);
    const ok = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: soulmateBody,
    });
    expect(ok.statusCode).toBe(200);
    expect(ok.json().data.mimeType).toBe('image/png');
    expect(typeof ok.json().data.imageBase64).toBe('string');
    expect(ok.json().data.imageBase64.length).toBeGreaterThan(8);
    await app.close();
  });
});

function signature(prompt: string): string {
  return createHash('sha256').update(prompt).digest('hex').slice(0, 12);
}
