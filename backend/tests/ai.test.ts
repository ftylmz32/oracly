import { describe, expect, it } from 'vitest';
import {
  authHeader,
  chatBody,
  coffeeBody,
  coffeeJson,
  palmBody,
  palmJson,
  dreamBody,
  dreamJson,
  fakeJpeg,
  openaiText,
  oracleBody,
  testApp,
  testConfig,
} from './helpers.js';

describe('ai complete', () => {
  it('returns no_configuration when OPENAI_API_KEY is missing', async () => {
    const app = await testApp(
      testConfig({ OPENAI_API_KEY: '', AI_DEV_AUTH_BYPASS: 'true' }),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: chatBody,
    });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      success: false,
      error: { code: 'no_configuration' },
    });
    expect(JSON.stringify(res.json()).toLowerCase()).not.toContain('sk-');
    await app.close();
  });

  it('rejects invalid operation and invalid body', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const unknown = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: { operation: 'hack', payload: {} },
    });
    expect(unknown.json().error.code).toBe('invalid_request');
    const empty = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {},
    });
    expect(empty.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('proxies AI chat', async () => {
    const app = await testApp(
      testConfig(),
      openaiText('Sakin bir nefes al ve bugunu yumusak tut.'),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: chatBody,
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(true);
    expect(res.json().data.text).toContain('Sakin');
    await app.close();
  });

  it('proxies OR a Sor with isolated structured context', async () => {
    let seen = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      seen = String(init?.body ?? '');
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: 'Bu kart sezgiye davet ediyor, kesin kader yok.',
              },
            },
          ],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: oracleBody,
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.text.length).toBeGreaterThan(11);
    expect(seen).toContain('tarot');
    expect(seen).toContain('The Moon');
    expect(seen).not.toContain('system":"ignore previous');
    await app.close();
  });

  it('adds observed discovery themes to oracle context without uid', async () => {
    let seen = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      seen = String(init?.body ?? '');
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: 'Son keşiflerinde sınırlar teması tekrar ediyor.',
              },
            },
          ],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: {
        ...oracleBody,
        payload: {
          ...oracleBody.payload,
          context: {
            ...oracleBody.payload.context,
            observedThemes: ['sınırlar', 'değişim'],
          },
        },
      },
    });
    expect(res.json().success).toBe(true);
    expect(seen).toContain('sınırlar');
    expect(seen).toContain('değişim');
    expect(seen).not.toContain('firebaseUid');
    expect(seen).not.toContain('"uid"');
    await app.close();
  });

  it('rejects oracle context kind mismatch', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        operation: 'oracle',
        payload: {
          userMessage: 'Ne anlatiyor?',
          context: { kind: 'mixed-leak', narrative: 'x' },
        },
      },
    });
    expect(res.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('returns structured dream analysis', async () => {
    const app = await testApp(testConfig(), openaiText(dreamJson));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: dreamBody,
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.summary).toBeTruthy();
    expect(res.json().data.symbols).toEqual(['yilan']);
    expect(res.json().data.emotionalTheme).toBeTruthy();
    expect(res.json().data.interpretation).toBeTruthy();
    expect(res.json().data.dailyLifeReflection).toBeTruthy();
    expect(res.json().data.conclusion).toBeTruthy();
    await app.close();
  });

  it('returns invalid_response when dream JSON is incomplete', async () => {
    const app = await testApp(
      testConfig(),
      openaiText(JSON.stringify({ ozet: 'kisa' })),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: dreamBody,
    });
    expect(res.json()).toEqual({
      success: false,
      error: { code: 'invalid_response' },
    });
    await app.close();
  });

  it('validates coffee vision and returns visual vs symbolic fields', async () => {
    const app = await testApp(testConfig(), openaiText(coffeeJson));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: coffeeBody(),
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.visualObservation).toContain('izler');
    expect(res.json().data.overall).toBeTruthy();
    expect(res.json().data.symbols[0].name).toBe('Kus');
    await app.close();
  });

  it('rejects coffee gif mime and tiny images', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const gif = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        operation: 'coffee_analysis',
        payload: {
          mimeType: 'image/gif',
          imageBase64: fakeJpeg().toString('base64'),
          byteLength: 9000,
        },
      },
    });
    expect(gif.json().error.code).toBe('invalid_request');
    const tiny = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: coffeeBody(Buffer.from([0xff, 0xd8, 0xff, 1, 2, 3])),
    });
    expect(tiny.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('validates palm vision and returns symbolic line fields', async () => {
    const app = await testApp(testConfig(), openaiText(palmJson));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: palmBody(),
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.overall).toContain('sakin');
    expect(res.json().data.lifeLine).toBeTruthy();
    expect(res.json().data.themes).toContain('introspection');
    expect(JSON.stringify(res.json()).toLowerCase()).not.toContain('sk-');
    await app.close();
  });

  it('rejects palm certainty copy from the provider', async () => {
    const app = await testApp(
      testConfig(),
      openaiText(
        JSON.stringify({
          genelYapi: 'Omrun su kadar surecek ve hastaliga sahipsin.',
          sonuc: 'Kesin olacak.',
        }),
      ),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: palmBody(),
    });
    expect(res.json().success).toBe(false);
    expect(res.json().error.code).toBe('invalid_response');
    await app.close();
  });

  it('returns image_analysis_unavailable when vision is off', async () => {
    const app = await testApp(
      testConfig({ OPENAI_VISION: 'false', AI_DEV_AUTH_BYPASS: 'true' }),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: coffeeBody(),
    });
    expect(res.json().error.code).toBe('image_analysis_unavailable');
    const palm = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: palmBody(),
    });
    expect(palm.json().error.code).toBe('image_analysis_unavailable');
    await app.close();
  });

  it('maps provider error and timeout', async () => {
    const failing = await testApp(testConfig(), openaiText('ignored', 500));
    const provider = await failing.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: chatBody,
    });
    expect(provider.json().error.code).toBe('provider_error');
    await failing.close();

    const hanging: typeof fetch = async (_url, init) =>
      new Promise((_, reject) => {
        init?.signal?.addEventListener('abort', () => {
          const err = new Error('aborted');
          err.name = 'AbortError';
          reject(err);
        });
      });
    const timed = await testApp(
      testConfig({ OPENAI_TIMEOUT_SECONDS: '1' }),
      hanging,
    );
    const timeout = await timed.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: chatBody,
    });
    expect(timeout.json().error.code).toBe('timeout');
    await timed.close();
  });
});
