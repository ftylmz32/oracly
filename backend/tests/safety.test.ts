import { describe, expect, it } from 'vitest';
import { logSafe } from '../src/logging.js';
import {
  authHeader,
  chatBody,
  coffeeBody,
  fakeJpeg,
  jsonResponse,
  testApp,
  testConfig,
} from './helpers.js';

describe('safety', () => {
  it('never returns the API key or provider diagnostics', async () => {
    const app = await testApp(testConfig(), async () =>
      jsonResponse({ error: { message: 'Invalid sk-test-server-only key' } }, 401),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: chatBody,
    });
    const text = res.body;
    expect(text.toLowerCase()).not.toContain('sk-');
    expect(text).not.toContain('stack');
    expect(text).not.toContain('Authorization');
    expect(res.json().error.code).toBe('no_configuration');
    await app.close();
  });

  it('does not let the client override the server model', async () => {
    let sentModel = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      const parsed = JSON.parse(String(init?.body ?? '{}')) as { model?: string };
      sentModel = parsed.model ?? '';
      return jsonResponse({
        choices: [
          { message: { content: 'Sakin bir nefes al ve bugunu yumusak tut.' } },
        ],
      });
    });
    await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: { ...chatBody, model: 'gpt-5-ultra-expensive' },
    });
    expect(sentModel).toBe('gpt-4o');
    await app.close();
  });

  it('allows only allowlisted model hints', async () => {
    let sentModel = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      sentModel = JSON.parse(String(init?.body ?? '{}')).model;
      return jsonResponse({
        choices: [
          { message: { content: 'Sakin bir nefes al ve bugunu yumusak tut.' } },
        ],
      });
    });
    await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: { ...chatBody, model: 'gpt-4o-mini' },
    });
    expect(sentModel).toBe('gpt-4o-mini');
    await app.close();
  });

  it('rate limits repeated identity requests', async () => {
    const app = await testApp(
      testConfig({ AI_RATE_LIMIT_MAX: '2', AI_RATE_LIMIT_WINDOW_MS: '60000' }),
    );
    const headers = authHeader('same-user');
    const first = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Ilk mesaj.' },
      },
    });
    const second = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Ikinci mesaj.' },
      },
    });
    const third = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers,
      payload: {
        ...chatBody,
        payload: { ...chatBody.payload, userMessage: 'Ucuncu mesaj.' },
      },
    });
    expect(first.json().success).toBe(true);
    expect(second.json().success).toBe(true);
    expect(third.statusCode).toBe(429);
    expect(third.json().error.code).toBe('rate_limited');
    await app.close();
  });

  it('rejects oversized coffee payloads before provider call', async () => {
    let called = false;
    const app = await testApp(
      testConfig({ AI_MAX_IMAGE_BYTES: '20000', AI_MIN_IMAGE_BYTES: '8192' }),
      async () => {
      called = true;
      return jsonResponse({ choices: [{ message: { content: 'nope' } }] });
    });
    const huge = fakeJpeg(25000);
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: coffeeBody(huge),
    });
    expect(called).toBe(false);
    expect(res.json().error.code).toBe('image_too_large');
    await app.close();
  });

  it('safe logs omit secrets and payloads', () => {
    const lines: unknown[] = [];
    const logger = {
      info: (fields: unknown) => lines.push(fields),
      warn: () => undefined,
      error: () => undefined,
    };
    logSafe(logger as never, 'info', 'ai_complete', {
      requestId: 'req-1',
      operation: 'chat',
      model: 'gpt-4o',
      latencyMs: 12,
      status: 200,
      errorCode: undefined,
    });
    const dumped = JSON.stringify(lines);
    expect(dumped).toContain('chat');
    expect(dumped).not.toContain('sk-');
    expect(dumped).not.toContain('Bearer');
    expect(dumped).not.toContain('imageBase64');
    expect(dumped).not.toContain('Merhaba');
  });
});
