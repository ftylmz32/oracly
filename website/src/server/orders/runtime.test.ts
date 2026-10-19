import { afterEach, describe, expect, it } from 'vitest';
import { loadCheckoutServerConfig } from './runtime';

const keys = ['ORACLY_IYZICO_CHECKOUT_ENABLED','ORACLY_IYZICO_PRODUCTION_ENABLED','IYZICO_ENVIRONMENT','IYZICO_API_KEY','IYZICO_SECRET_KEY','IYZICO_CALLBACK_URL'] as const;
const before = Object.fromEntries(keys.map((key) => [key, process.env[key]]));
afterEach(() => { for (const key of keys) { const value = before[key]; if (value === undefined) delete process.env[key]; else process.env[key] = value; } });

describe('iyzico runtime feature gates', () => {
  it('is fail-closed by default and refuses production without its second explicit guard', () => {
    for (const key of keys) delete process.env[key];
    expect(() => loadCheckoutServerConfig()).toThrow('order_server_unavailable');
    Object.assign(process.env, { ORACLY_IYZICO_CHECKOUT_ENABLED: 'true', IYZICO_ENVIRONMENT: 'production', IYZICO_API_KEY: 'key', IYZICO_SECRET_KEY: 'secret', IYZICO_CALLBACK_URL: 'https://example.test/callback' });
    expect(() => loadCheckoutServerConfig()).toThrow('order_server_unavailable');
  });

  it('uses the fixed sandbox origin and keeps secrets server-side', () => {
    Object.assign(process.env, { ORACLY_IYZICO_CHECKOUT_ENABLED: 'true', ORACLY_IYZICO_PRODUCTION_ENABLED: 'false', IYZICO_ENVIRONMENT: 'sandbox', IYZICO_API_KEY: 'key', IYZICO_SECRET_KEY: 'secret', IYZICO_CALLBACK_URL: 'https://example.test/callback' });
    expect(loadCheckoutServerConfig()).toMatchObject({ environment: 'sandbox', baseUrl: 'https://sandbox-api.iyzipay.com' });
  });
});
