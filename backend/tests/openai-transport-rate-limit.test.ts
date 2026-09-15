/**
 * SM-RL2 §1/§2/§9 — bounded, sanitized 429 evidence capture in
 * OpenAiTransport. Proves (a) Retry-After/request-id/rate-limit headers/
 * a bounded provider message land on ProxyError.details when present,
 * (b) a 429 with no body/headers is still classified rate_limited (never
 * throws on a body-parse failure), and (c) the API key/Authorization
 * header can never appear in the captured details.
 */
import { describe, expect, it } from 'vitest';
import { OpenAiTransport } from '../src/ai/openai-transport.js';
import { ErrorCode, ProxyError } from '../src/errors.js';
import { testConfig } from './helpers.js';

function rateLimitResponse(init: {
  headers?: Record<string, string>;
  body?: unknown;
  rawBody?: string;
} = {}): Response {
  const body =
    init.rawBody !== undefined
      ? init.rawBody
      : init.body !== undefined
        ? JSON.stringify(init.body)
        : '';
  return new Response(body, {
    status: 429,
    headers: { 'content-type': 'application/json', ...init.headers },
  });
}

async function expectRateLimited(promise: Promise<unknown>): Promise<ProxyError> {
  try {
    await promise;
  } catch (error) {
    expect(error).toBeInstanceOf(ProxyError);
    const proxyError = error as ProxyError;
    expect(proxyError.code).toBe(ErrorCode.rateLimited);
    expect(proxyError.httpStatus).toBe(429);
    return proxyError;
  }
  throw new Error('expected a ProxyError to be thrown');
}

describe('SM-RL2 OpenAiTransport 429 evidence capture', () => {
  it('1: 429 JSON response with Retry-After -> ProxyError contains parsed metadata', async () => {
    const transport = new OpenAiTransport(
      testConfig(),
      async () =>
        rateLimitResponse({
          headers: { 'retry-after': '45' },
          body: { error: { type: 'rate_limit_error', code: 'rate_limited', message: 'Too many requests' } },
        }),
    );
    const error = await expectRateLimited(transport.generateImage('a prompt'));
    expect(error.details?.retryAfterMs).toBe(45_000);
    expect(error.details?.providerMessage).toContain('rate_limit_error');
    expect(error.details?.providerMessage).toContain('Too many requests');
  });

  it('2: 429 without body -> still classified rate_limited', async () => {
    const transport = new OpenAiTransport(
      testConfig(),
      async () => rateLimitResponse({ rawBody: '' }),
    );
    const error = await expectRateLimited(transport.generateImage('a prompt'));
    expect(error.code).toBe(ErrorCode.rateLimited);
    expect(error.details?.providerMessage).toBeUndefined();
  });

  it('2b: 429 with unparseable (non-JSON) body -> still classified rate_limited, no throw', async () => {
    const transport = new OpenAiTransport(
      testConfig(),
      async () => rateLimitResponse({ rawBody: 'not json at all {{{' }),
    );
    const error = await expectRateLimited(transport.generateImage('a prompt'));
    expect(error.code).toBe(ErrorCode.rateLimited);
    expect(error.details?.providerMessage).toBeUndefined();
  });

  it('3: 429 with request-id + rate-limit headers -> bounded fields captured', async () => {
    const transport = new OpenAiTransport(
      testConfig(),
      async () =>
        rateLimitResponse({
          headers: {
            'x-request-id': 'req_abc123',
            'x-ratelimit-limit-requests': '5000',
            'x-ratelimit-remaining-requests': '0',
            'x-ratelimit-reset-requests': '12s',
          },
        }),
    );
    const error = await expectRateLimited(transport.generateImage('a prompt'));
    expect(error.details?.requestId).toBe('req_abc123');
    expect(error.details?.rateLimit).toMatchObject({
      'x-ratelimit-limit-requests': '5000',
      'x-ratelimit-remaining-requests': '0',
      'x-ratelimit-reset-requests': '12s',
    });
  });

  it('3b: also captured on the chat/completions path (complete()), same shared transport', async () => {
    const transport = new OpenAiTransport(
      testConfig(),
      async () =>
        rateLimitResponse({
          headers: { 'retry-after': '5', 'x-request-id': 'req_chat_1' },
        }),
    );
    const error = await expectRateLimited(
      transport.complete({ messages: [{ role: 'user', content: 'hi' }], model: 'gpt-4o' }),
    );
    expect(error.details?.retryAfterMs).toBe(5_000);
    expect(error.details?.requestId).toBe('req_chat_1');
  });

  it('4: authorization/API key never appears in captured details', async () => {
    let sentAuthHeader = '';
    const transport = new OpenAiTransport(
      testConfig({ OPENAI_API_KEY: 'sk-super-secret-value' }),
      async (_url, init) => {
        sentAuthHeader = String((init?.headers as Record<string, string>)?.Authorization ?? '');
        return rateLimitResponse({
          headers: { 'retry-after': '30' },
          body: { error: { message: 'rate limited for key sk-super-secret-value' } },
        });
      },
    );
    const error = await expectRateLimited(transport.generateImage('a prompt'));
    // The real request did carry the key (sanity check the mock is wired) —
    // but nothing captured on the error may ever repeat it.
    expect(sentAuthHeader).toContain('sk-super-secret-value');
    expect(JSON.stringify(error.details ?? {})).not.toContain('sk-super-secret-value');
  });

  it('bounds an oversized provider message rather than storing it unbounded', async () => {
    const hugeMessage = 'x'.repeat(10_000);
    const transport = new OpenAiTransport(
      testConfig(),
      async () => rateLimitResponse({ body: { error: { message: hugeMessage } } }),
    );
    const error = await expectRateLimited(transport.generateImage('a prompt'));
    expect((error.details?.providerMessage as string).length).toBeLessThanOrEqual(300);
  });

  it('caps the number of captured rate-limit headers', async () => {
    const headers: Record<string, string> = {};
    for (let i = 0; i < 30; i++) {
      headers[`x-ratelimit-limit-bucket${i}`] = String(i);
    }
    const transport = new OpenAiTransport(testConfig(), async () => rateLimitResponse({ headers }));
    const error = await expectRateLimited(transport.generateImage('a prompt'));
    expect(Object.keys(error.details?.rateLimit as Record<string, string>).length).toBeLessThanOrEqual(12);
  });
});
