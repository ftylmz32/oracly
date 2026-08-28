import { describe, expect, it } from 'vitest';
import {
  authHeader,
  openaiImage,
  openaiText,
  soulmateBody,
  testApp,
  testConfig,
  TINY_PNG_B64,
} from './helpers.js';

describe('soulmate_draw', () => {
  it('rejects unauthenticated requests', async () => {
    const app = await testApp(testConfig(), openaiImage());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: soulmateBody,
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('unauthorized');
    expect(JSON.stringify(res.json()).toLowerCase()).not.toContain('sk-');
    expect(JSON.stringify(res.json())).not.toContain('Bearer');
    await app.close();
  });

  it('routes authenticated soulmate_draw to images generations', async () => {
    const seen: {
      url: string;
      model?: string;
      prompt?: string;
      n?: number;
      size?: string;
      response_format?: unknown;
    }[] = [];
    const fetchImpl: typeof fetch = async (url, init) => {
      const body = JSON.parse(String(init?.body ?? '{}')) as {
        model?: string;
        prompt?: string;
        n?: number;
        size?: string;
        response_format?: unknown;
      };
      seen.push({
        url: String(url),
        model: body.model,
        prompt: body.prompt,
        n: body.n,
        size: body.size,
        response_format: body.response_format,
      });
      return openaiImage()(url, init);
    };
    const app = await testApp(testConfig(), fetchImpl);
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: {
        ...soulmateBody,
        payload: {
          ...soulmateBody.payload,
          prompt: 'CLIENT_AUTHORED_PROMPT_MUST_BE_IGNORED',
        },
      },
    });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      success: true,
      data: {
        imageBase64: TINY_PNG_B64,
        mimeType: 'image/png',
        operation: 'soulmate_draw',
      },
    });
    expect(seen).toHaveLength(1);
    expect(seen[0]?.url).toContain('/images/generations');
    expect(seen[0]?.model).toBe('gpt-image-2');
    expect(seen[0]?.n).toBe(1);
    expect(seen[0]?.size).toBe('1024x1536');
    expect(seen[0]?.response_format).toBeUndefined();
    expect(seen[0]?.prompt).toContain('Elif');
    expect(seen[0]?.prompt).toContain('mist lilac');
    expect(seen[0]?.prompt).not.toContain('1994-03-12');
    expect(seen[0]?.prompt).not.toContain(
      'CLIENT_AUTHORED_PROMPT_MUST_BE_IGNORED',
    );
    expect(JSON.stringify(seen[0])).not.toMatch(/"seed"\s*:/);
    expect(JSON.stringify(res.json())).not.toContain('sk-test');
    await app.close();
  });

  it('rejects invalid soulmate payload', async () => {
    const app = await testApp(testConfig(), openaiImage());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: {
        operation: 'soulmate_draw',
        payload: { name: 'A', birthDate: 'not-a-date' },
      },
    });
    expect(res.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('maps provider error, rate limit, and unavailable key', async () => {
    const provider = await testApp(testConfig(), openaiImage(TINY_PNG_B64, 500));
    const providerRes = await provider.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: soulmateBody,
    });
    expect(providerRes.json().error.code).toBe('provider_error');
    await provider.close();

    const limited = await testApp(testConfig(), openaiImage(TINY_PNG_B64, 429));
    const limitedRes = await limited.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: soulmateBody,
    });
    expect(limitedRes.json().error.code).toBe('rate_limited');
    await limited.close();

    const missing = await testApp(
      testConfig({ OPENAI_API_KEY: '', AI_DEV_AUTH_BYPASS: 'true' }),
      openaiImage(),
    );
    const missingRes = await missing.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: soulmateBody,
    });
    expect(missingRes.json().error.code).toBe('no_configuration');
    expect(JSON.stringify(missingRes.json()).toLowerCase()).not.toContain(
      'sk-',
    );
    await missing.close();
  });

  it('does not send chat completions for soulmate_draw', async () => {
    const app = await testApp(testConfig(), openaiText('chat-only'));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: soulmateBody,
    });
    expect(res.json().error.code).toBe('invalid_response');
    await app.close();
  });
});
