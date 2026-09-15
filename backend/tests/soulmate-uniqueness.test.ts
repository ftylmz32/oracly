import { createHash } from 'node:crypto';
import { beforeEach, describe, expect, it } from 'vitest';
import {
  SOULMATE_MAX_IMAGE_CALLS,
  coreFromSeed,
  coresEqual,
  portraitSeed,
} from '../src/ai/soulmate-portrait-identity.js';
import { buildSoulmateImagePrompt } from '../src/ai/soulmate-prompt.js';
import {
  contentHashOf,
  ownerHashOf,
  resetSoulmateUniquenessIndex,
  soulmateUniquenessIndex,
} from '../src/ai/soulmate-uniqueness-index.js';
import {
  authHeader,
  jsonResponse,
  openaiImage,
  soulmateBody,
  testApp,
  testConfig,
  TINY_PNG_B64,
} from './helpers.js';

function png(byte: number): string {
  const raw = Buffer.from(TINY_PNG_B64, 'base64');
  const copy = Buffer.from(raw);
  copy[copy.length - 1] = byte;
  return copy.toString('base64');
}

describe('soulmate portrait uniqueness', () => {
  beforeEach(() => {
    resetSoulmateUniquenessIndex();
  });

  it('locks the image-call budget at two', () => {
    expect(SOULMATE_MAX_IMAGE_CALLS).toBe(2);
  });

  it('keeps the whole identity (and the rendered prompt) stable across nonces for the same account', () => {
    const first = buildSoulmateImagePrompt(
      { ...soulmateBody.payload, accountKey: 'acct-a' },
      '1111111111111111',
    );
    const second = buildSoulmateImagePrompt(
      { ...soulmateBody.payload, accountKey: 'acct-a' },
      '2222222222222222',
    );
    // Every visual dimension is now locked to the deterministic seed, not
    // the render nonce -- the nonce only exists for the collision-retry
    // loop's bookkeeping, so two draws of the same account are byte-identical.
    expect(coresEqual(first.core, second.core)).toBe(true);
    expect(first.identity.faceShape).toBe(second.identity.faceShape);
    expect(first.prompt).toBe(second.prompt);
    expect(first.nonce).not.toBe(second.nonce);
    expect(first.prompt).toContain('Identity direction');
    expect(first.prompt).toContain('Emotional direction');
    expect(first.prompt).not.toContain(first.seed);
  });

  it('gives four accounts distinct seeds and cores', () => {
    const ids = ['acct-1', 'acct-2', 'acct-3', 'acct-4'];
    const seeds = ids.map((id) => portraitSeed(id, 'feminine'));
    const cores = seeds.map((seed) => coreFromSeed(seed, 'feminine'));
    expect(new Set(seeds).size).toBe(4);
    const signatures = cores.map((core) => JSON.stringify(core));
    expect(new Set(signatures).size).toBe(4);
    const again = ids.map((id) => coreFromSeed(portraitSeed(id, 'feminine'), 'feminine'));
    expect(again).toEqual(cores);
  });

  it('spreads descriptors across a synthetic sample', () => {
    const faces = new Set<string>();
    const hair = new Set<string>();
    const eyes = new Set<string>();
    for (let i = 0; i < 48; i += 1) {
      const core = coreFromSeed(portraitSeed(`user-${i}`, 'masculine'), 'masculine');
      faces.add(core.faceShape);
      hair.add(core.hairFamily);
      eyes.add(core.eyePresentation);
    }
    expect(faces.size).toBeGreaterThan(3);
    expect(hair.size).toBeGreaterThan(3);
    expect(eyes.size).toBeGreaterThan(3);
  });

  it('rejects an exact cross-user image and stops at one uniqueness retry', async () => {
    let calls = 0;
    const fetchImpl: typeof fetch = async (url) => {
      if (String(url).includes('/images/generations')) {
        calls += 1;
        return jsonResponse({ data: [{ b64_json: TINY_PNG_B64 }] });
      }
      return jsonResponse({ choices: [{ message: { content: 'unused' } }] });
    };
    const app = await testApp(testConfig(), fetchImpl);
    const first = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader('account-a'),
      payload: soulmateBody,
    });
    expect(first.statusCode).toBe(200);
    expect(calls).toBe(1);

    const second = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader('account-b'),
      payload: soulmateBody,
    });
    expect(second.statusCode).toBe(200);
    expect(second.json().success).toBe(false);
    expect(second.json().error.code).toBe('invalid_response');
    expect(calls).toBe(3);
    expect(second.json().data?.imageBase64).toBeUndefined();
    await app.close();
  });

  it('accepts a uniqueness retry when the second render differs', async () => {
    let calls = 0;
    const fetchImpl: typeof fetch = async (url) => {
      if (String(url).includes('/images/generations')) {
        calls += 1;
        const body = calls < 3 ? TINY_PNG_B64 : png(9);
        return jsonResponse({ data: [{ b64_json: body }] });
      }
      return jsonResponse({ choices: [{ message: { content: 'unused' } }] });
    };
    const app = await testApp(testConfig(), fetchImpl);
    const first = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader('account-a'),
      payload: soulmateBody,
    });
    expect(first.json().success).toBe(true);

    const second = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader('account-b'),
      payload: soulmateBody,
    });
    expect(second.json().success).toBe(true);
    expect(calls).toBe(3);
    expect(
      [
        second.json().data.identity.faceShape,
        second.json().data.identity.hairFamily,
        second.json().data.identity.eyePresentation,
      ].join('|'),
    ).not.toBe(
      [
        first.json().data.identity.faceShape,
        first.json().data.identity.hairFamily,
        first.json().data.identity.eyePresentation,
      ].join('|'),
    );
    expect(second.json().data.identity.contentHash).not.toBe(
      first.json().data.identity.contentHash,
    );
    await app.close();
  });

  it('allows the same owner to reopen the same exact bytes', () => {
    const index = soulmateUniquenessIndex();
    const owner = ownerHashOf('acct-a');
    const hash = contentHashOf(Buffer.from(TINY_PNG_B64, 'base64'));
    index.remember({ owner, contentHash: hash, coreSignature: 'core-a' });
    expect(index.decide(owner, hash)).toBe('same-owner');
    expect(index.decide(ownerHashOf('acct-b'), hash)).toBe('collision');
    expect(JSON.stringify(index)).not.toContain('acct-a');
    expect(createHash('sha256').update(hash).digest('hex')).not.toContain('@');
  });
});
