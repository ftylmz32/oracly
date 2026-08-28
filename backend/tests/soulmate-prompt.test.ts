import { describe, expect, it } from 'vitest';
import { createHash } from 'node:crypto';
import {
  profilesDiffer,
  visualProfileFromBirthDate,
} from '../src/ai/soulmate-profile.js';
import {
  buildSoulmateImagePrompt,
  newSoulmateNonce,
} from '../src/ai/soulmate-prompt.js';
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
  it('builds materially different profiles for different birth dates', () => {
    const a = visualProfileFromBirthDate(USER_A.birthDate);
    const b = visualProfileFromBirthDate(USER_B.birthDate);
    expect(profilesDiffer(a, b)).toBe(true);
    expect(a.colorFamily).toContain('sage');
    expect(b.colorFamily).toContain('amber');
    expect(a.setting).not.toBe(b.setting);
    expect(a.mood).not.toBe(b.mood);
  });

  it('keeps the same date deterministic', () => {
    const first = visualProfileFromBirthDate(USER_A.birthDate);
    const second = visualProfileFromBirthDate(USER_A.birthDate);
    expect(first).toEqual(second);
  });

  it('issues a new nonce for every draw of the same user', () => {
    const first = buildSoulmateImagePrompt(USER_A);
    const second = buildSoulmateImagePrompt(USER_A);
    expect(first.nonce).not.toBe(second.nonce);
    expect(first.nonce).toHaveLength(16);
    expect(second.nonce).toHaveLength(16);
    expect(first.prompt).not.toBe(second.prompt);
    expect(newSoulmateNonce()).not.toBe(newSoulmateNonce());
  });

  it('lets user inputs change the prompt, not only the nonce', () => {
    const nonce = 'aaaaaaaaaaaaaaaa';
    const a = buildSoulmateImagePrompt(USER_A, nonce);
    const b = buildSoulmateImagePrompt(USER_B, nonce);
    expect(a.nonce).toBe(b.nonce);
    expect(a.prompt).not.toBe(b.prompt);
    expect(a.prompt).toContain('sage');
    expect(b.prompt).toContain('amber');
    expect(a.prompt).toContain('Asel');
    expect(b.prompt).toContain('Deniz');
    expect(a.prompt).not.toContain(USER_A.birthDate);
    expect(b.prompt).not.toContain(USER_B.birthDate);
  });

  it('never places a firebase uid or client user id in the prompt', () => {
    const built = buildSoulmateImagePrompt({
      ...USER_A,
      name: 'Asel',
    });
    expect(built.prompt.toLowerCase()).not.toContain('uid');
    expect(built.prompt).not.toContain('user-1');
    expect(built.prompt).not.toMatch(/firebase/i);
    expect(built.prompt.toLowerCase()).toContain('photorealistic');
    expect(built.prompt.toLowerCase()).not.toContain('oil-paint');
    expect(built.prompt.toLowerCase()).not.toContain('painted character');
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
