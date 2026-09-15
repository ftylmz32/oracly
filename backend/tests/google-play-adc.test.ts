/**
 * Google Play Application Default Credentials (ADC) opt-in — proves the
 * precedence rule (explicit credentials always win), the fail-closed
 * behavior when neither credentials nor ADC are configured, and that the
 * ADC path really does construct `GoogleAuth` with no `credentials` field
 * (so it resolves against the attached Cloud Run service account / local
 * ADC file) rather than silently reusing a service-account JSON.
 */
import { describe, expect, it, vi } from 'vitest';
import { billingResult } from '../src/billing/types.js';

const MONTHLY = 'app.oracly.premium.monthly';

describe('createGooglePlayVerifier — Application Default Credentials opt-in', () => {
  it('explicit credentials present: configured true, existing credential path still verifies', async () => {
    const { createGooglePlayVerifier } = await import(
      '../src/billing/google-play.js'
    );
    const verifier = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: { client_email: 'x', private_key: 'y' } as never,
      useApplicationDefaultCredentials: true, // must not matter — credentials win
      getAccessToken: async () => 'access-token',
      fetchImpl: async () =>
        new Response(JSON.stringify({ purchaseState: 0 }), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
    });
    expect(verifier.configured).toBe(true);
    const result = await verifier.verify({
      platform: 'android',
      productId: 'app.oracly.premium.lifetime',
      purchaseToken: 'tok',
    });
    expect(result.status).toBe('active');
  });

  it('no credentials, ADC false: not configured, fails closed without ever calling the store', async () => {
    const { createGooglePlayVerifier } = await import(
      '../src/billing/google-play.js'
    );
    let fetchCalled = false;
    const verifier = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: null,
      useApplicationDefaultCredentials: false,
      fetchImpl: async () => {
        fetchCalled = true;
        return new Response('{}', { status: 200 });
      },
    });
    expect(verifier.configured).toBe(false);
    const result = await verifier.verify({
      platform: 'android',
      productId: MONTHLY,
      purchaseToken: 'tok',
    });
    expect(result).toEqual(
      billingResult('unverified', 'provider_not_configured'),
    );
    expect(fetchCalled).toBe(false);
  });

  it('no credentials, ADC true: configured true', async () => {
    const { createGooglePlayVerifier } = await import(
      '../src/billing/google-play.js'
    );
    const verifier = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: null,
      useApplicationDefaultCredentials: true,
      getAccessToken: async () => 'adc-access-token',
      fetchImpl: async () =>
        new Response(JSON.stringify({ purchaseState: 0 }), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
    });
    expect(verifier.configured).toBe(true);
    const result = await verifier.verify({
      platform: 'android',
      productId: 'app.oracly.premium.lifetime',
      purchaseToken: 'tok',
    });
    expect(result.status).toBe('active');
  });

  it('no packageName: never configured even with ADC true', async () => {
    const { createGooglePlayVerifier } = await import(
      '../src/billing/google-play.js'
    );
    const verifier = createGooglePlayVerifier({
      packageName: '',
      credentials: null,
      useApplicationDefaultCredentials: true,
      getAccessToken: async () => 'adc-access-token',
    });
    expect(verifier.configured).toBe(false);
  });

  it('ADC token acquisition constructs GoogleAuth with no credentials field', async () => {
    vi.resetModules();
    const ctorArgs: unknown[] = [];
    vi.doMock('google-auth-library', () => ({
      GoogleAuth: class {
        constructor(options: unknown) {
          ctorArgs.push(options);
        }
        async getClient() {
          return { getAccessToken: async () => ({ token: 'mock-adc-token' }) };
        }
      },
    }));
    const { createGooglePlayVerifier } = await import(
      '../src/billing/google-play.js'
    );
    const verifier = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: null,
      useApplicationDefaultCredentials: true,
      fetchImpl: async () =>
        new Response(JSON.stringify({ purchaseState: 0 }), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
    });
    const result = await verifier.verify({
      platform: 'android',
      productId: 'app.oracly.premium.lifetime',
      purchaseToken: 'tok',
    });
    expect(result.status).toBe('active');
    expect(ctorArgs).toHaveLength(1);
    expect(ctorArgs[0]).toEqual({
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    // No `credentials` key at all — must not silently fall back to a
    // service-account shape when the ADC path is the one taken.
    expect(
      Object.prototype.hasOwnProperty.call(ctorArgs[0] as object, 'credentials'),
    ).toBe(false);
    vi.doUnmock('google-auth-library');
    vi.resetModules();
  });

  it('access-token acquisition failure fails closed, never grants active', async () => {
    const { createGooglePlayVerifier } = await import(
      '../src/billing/google-play.js'
    );
    const verifier = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: null,
      useApplicationDefaultCredentials: true,
      getAccessToken: async () => {
        throw new Error('adc_unavailable');
      },
    });
    expect(verifier.configured).toBe(true);
    const result = await verifier.verify({
      platform: 'android',
      productId: MONTHLY,
      purchaseToken: 'tok',
    });
    expect(result.status).not.toBe('active');
    expect(result).toEqual(billingResult('error', 'provider_unavailable'));
  });

  it('ADC resolving to an empty access token fails closed, never grants active', async () => {
    vi.resetModules();
    vi.doMock('google-auth-library', () => ({
      GoogleAuth: class {
        constructor(_options: unknown) {}
        async getClient() {
          // ADC resolved (e.g. no attached service account) but produced
          // no usable token — must never be treated as success.
          return { getAccessToken: async () => ({ token: undefined }) };
        }
      },
    }));
    const { createGooglePlayVerifier } = await import(
      '../src/billing/google-play.js'
    );
    const verifier = createGooglePlayVerifier({
      packageName: 'app.oracly',
      credentials: null,
      useApplicationDefaultCredentials: true,
    });
    const result = await verifier.verify({
      platform: 'android',
      productId: MONTHLY,
      purchaseToken: 'tok',
    });
    expect(result).toEqual(billingResult('error', 'provider_unavailable'));
    vi.doUnmock('google-auth-library');
    vi.resetModules();
  });
});
