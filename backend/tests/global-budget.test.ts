import { describe, expect, it } from 'vitest';
import {
  authHeader,
  chatBody,
  openaiText,
  testApp,
  testConfig,
} from './helpers.js';

describe('global cost safety valves', () => {
  it('global RPM limit returns 429 across subjects', async () => {
    const app = await testApp(
      testConfig({
        AI_DEV_AUTH_BYPASS: 'true',
        AI_RATE_LIMIT_MAX: '100',
        AI_GLOBAL_RPM: '2',
        AI_GLOBAL_CONCURRENCY: '10',
      }),
      openaiText('Merhaba.'),
    );
    const first = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Bir.' },
      },
    });
    const second = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Iki.' },
      },
    });
    const third = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Uc.' },
      },
    });
    expect(first.json().success).toBe(true);
    expect(second.json().success).toBe(true);
    expect(third.statusCode).toBe(429);
    expect(third.json().error.code).toBe('rate_limited');
    expect(JSON.stringify(third.json()).toLowerCase()).not.toContain('openai');
    await app.close();
  });

  it('global concurrency limit blocks while a request is inflight', async () => {
    let release!: () => void;
    const gate = new Promise<void>((resolve) => {
      release = resolve;
    });
    const app = await testApp(
      testConfig({
        AI_DEV_AUTH_BYPASS: 'true',
        AI_MAX_CONCURRENT: '10',
        AI_GLOBAL_RPM: '100',
        AI_GLOBAL_CONCURRENCY: '1',
      }),
      async () => {
        await gate;
        return new Response(
          JSON.stringify({
            choices: [{ message: { content: 'Tamam.' } }],
          }),
          { status: 200, headers: { 'content-type': 'application/json' } },
        );
      },
    );

    const firstPromise = app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Ilk.' },
      },
    });
    await new Promise((r) => setTimeout(r, 40));

    const blocked = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Ikinci.' },
      },
    });
    expect(blocked.statusCode).toBe(429);
    expect(blocked.json().error.code).toBe('rate_limited');

    release();
    const first = await firstPromise;
    expect(first.json().success).toBe(true);

    const after = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Ucuncu.' },
      },
    });
    expect(after.json().success).toBe(true);
    await app.close();
  });

  it('concurrency slot releases after provider error', async () => {
    let calls = 0;
    const app = await testApp(
      testConfig({
        AI_DEV_AUTH_BYPASS: 'true',
        AI_MAX_CONCURRENT: '10',
        AI_GLOBAL_RPM: '100',
        AI_GLOBAL_CONCURRENCY: '1',
      }),
      async () => {
        calls += 1;
        if (calls === 1) {
          return new Response('boom', {
            status: 500,
            headers: { 'content-type': 'text/plain' },
          });
        }
        return new Response(
          JSON.stringify({
            choices: [{ message: { content: 'Kurtuldu.' } }],
          }),
          { status: 200, headers: { 'content-type': 'application/json' } },
        );
      },
    );

    const failed = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Hata.' },
      },
    });
    expect(failed.json().success).toBe(false);

    const next = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Sonra.' },
      },
    });
    expect(next.json().success).toBe(true);
    expect(calls).toBe(2);
    await app.close();
  });

  it('subject auth headers still work with global valves present', async () => {
    const app = await testApp(
      testConfig({
        AI_GLOBAL_RPM: '50',
        AI_GLOBAL_CONCURRENCY: '8',
      }),
      openaiText('Merhaba.'),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: chatBody,
    });
    expect(res.json().success).toBe(true);
    await app.close();
  });
});
