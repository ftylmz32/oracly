import { beforeEach, describe, expect, it } from 'vitest';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import {
  authHeader,
  chatBody,
  coffeeBody,
  coffeeJson,
  coffeeObserverJson,
  coffeeWriterJson,
  openaiReadingSequence,
  jsonResponse,
  fakeJpeg,
  openaiText,
  testApp,
  testConfig,
  TINY_PNG_B64,
} from './helpers.js';

describe('ai abuse protection', () => {
  beforeEach(() => readingStageStore.clear());
  it('rejects rapid duplicate chat bodies', async () => {
    const app = await testApp(testConfig(), openaiText('Merhaba.'));
    const headers = authHeader();
    const first = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload: chatBody,
    });
    expect(first.statusCode).toBe(200);
    expect(first.json().success).toBe(true);
    const second = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload: chatBody,
    });
    expect(second.statusCode).toBe(429);
    expect(second.json().error.code).toBe('rate_limited');
    await app.close();
  });

  it('allows a different chat message immediately', async () => {
    const app = await testApp(testConfig(), openaiText('Tamam.'));
    const headers = authHeader();
    await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload: chatBody,
    });
    const other = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload: {
        ...chatBody,
        payload: {
          ...chatBody.payload,
          userMessage: 'Bugun nasil hissediyorum?',
        },
      },
    });
    expect(other.statusCode).toBe(200);
    expect(other.json().success).toBe(true);
    await app.close();
  });

  it('replays soulmate success for the same idempotency key', async () => {
    let calls = 0;
    const app = await testApp(testConfig(), async () => {
      calls += 1;
      return new Response(
        JSON.stringify({
          data: [{ b64_json: TINY_PNG_B64 }],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const headers = {
      ...authHeader(),
      'idempotency-key': 'or-soulmate-test-1',
    };
    const payload = {
      operation: 'soulmate_draw',
      payload: {
        name: 'Ada',
        birthDate: '1994-03-12',
        gender: 'feminine',
        intention: 'sakin',
        language: 'tr',
      },
    };
    const first = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload,
    });
    expect(first.statusCode).toBe(200);
    expect(first.json().success).toBe(true);
    const second = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload,
    });
    expect(second.statusCode).toBe(200);
    expect(second.json().success).toBe(true);
    expect(calls).toBe(1);
    await app.close();
  });

  it('replays coffee success for the same paid operation id', async () => {
    let calls = 0;
    const app = await testApp(testConfig(), async () => {
      calls += 1;
      const text = calls % 2 === 1 ? coffeeObserverJson : coffeeWriterJson;
      return jsonResponse({ choices: [{ message: { content: text } }] });
    });
    const headers = {
      ...authHeader(),
      'idempotency-key': 'or-coffee-op-resume-1',
    };
    const payload = coffeeBody(fakeJpeg());
    const first = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload,
    });
    expect(first.statusCode).toBe(200);
    expect(first.json().success).toBe(true);
    const second = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload,
    });
    expect(second.statusCode).toBe(200);
    expect(second.json().success).toBe(true);
    expect(calls).toBe(2);
    await app.close();
  });

  it('expensive coffee burst is capped without blocking chat forever', async () => {
    let stage = 0;
    const app = await testApp(
      testConfig({ AI_EXPENSIVE_RATE_MAX: '2' }),
      async (_url, init) => {
        const body = String(init?.body ?? '');
        if (body.includes('image_url') || body.includes('coffee_observation') || body.includes('coffee_narrative') || body.includes('json_schema')) {
          stage += 1;
          const text = stage % 2 === 1 ? coffeeObserverJson : coffeeWriterJson;
          return jsonResponse({ choices: [{ message: { content: text } }] });
        }
        return openaiText('Sakin bir nefes.')();
      },
    );
    const headers = authHeader();
    for (let i = 0; i < 2; i++) {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: {
          ...headers,
          'idempotency-key': `or-coffee-${i}`,
        },
        payload: coffeeBody(fakeJpeg(9000 + i * 100)),
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().success).toBe(true);
    }
    const blocked = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: {
        ...headers,
        'idempotency-key': 'or-coffee-block',
      },
      payload: coffeeBody(fakeJpeg(9400)),
    });
    expect(blocked.statusCode).toBe(429);
    const chat = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload: {
        ...chatBody,
        payload: {
          ...chatBody.payload,
          userMessage: 'Farkli bir sohbet.',
        },
      },
    });
    expect(chat.statusCode).toBe(200);
    expect(chat.json().success).toBe(true);
    await app.close();
  });
});
