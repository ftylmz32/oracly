import { describe, expect, it } from 'vitest';
import { testApp, testConfig } from './helpers.js';

describe('health', () => {
  it('returns ok without secrets and without auth', async () => {
    const app = await testApp(testConfig());
    const res = await app.inject({ method: 'GET', url: '/health' });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body).toEqual({ status: 'ok' });
    expect(JSON.stringify(body).toLowerCase()).not.toContain('sk-');
    expect(JSON.stringify(body)).not.toContain('OPENAI');
    expect(JSON.stringify(body)).not.toContain('Authorization');
    await app.close();
  });

  it('readiness stays unauthenticated and hides configuration', async () => {
    const readyApp = await testApp(testConfig());
    const ready = await readyApp.inject({ method: 'GET', url: '/ready' });
    expect(ready.statusCode).toBe(200);
    expect(ready.json().status).toBe('ready');
    expect(ready.json().capabilities).toMatchObject({
      alive: true,
      authenticationConfigured: true,
      textProviderConfigured: true,
      visionConfigured: true,
      imageGenerationConfigured: true,
    });
    expect(JSON.stringify(ready.json()).toLowerCase()).not.toContain('sk-');
    expect(JSON.stringify(ready.json())).not.toContain('openai');
    await readyApp.close();

    const notReady = await testApp(
      testConfig({ APP_ENV: 'production', OPENAI_API_KEY: '' }),
    );
    const res = await notReady.inject({ method: 'GET', url: '/ready' });
    expect(res.statusCode).toBe(503);
    expect(res.json().status).toBe('not_ready');
    expect(res.json().capabilities.textProviderConfigured).toBe(false);
    expect(JSON.stringify(res.json())).not.toContain('JWT');
    await notReady.close();

    const noVerifier = await testApp(testConfig({ APP_ENV: 'production' }));
    const blocked = await noVerifier.inject({ method: 'GET', url: '/ready' });
    expect(blocked.statusCode).toBe(503);
    expect(JSON.stringify(blocked.json())).not.toContain('openai');
    await noVerifier.close();

    const firebaseReady = await testApp(
      testConfig({
        APP_ENV: 'production',
        FIREBASE_PROJECT_ID: 'oracly-7f613',
      }),
    );
    const ok = await firebaseReady.inject({ method: 'GET', url: '/ready' });
    expect(ok.statusCode).toBe(200);
    expect(ok.json().status).toBe('ready');
    expect(ok.json().capabilities.authenticationConfigured).toBe(true);
    expect(JSON.stringify(ok.json()).toLowerCase()).not.toContain('sk-');
    await firebaseReady.close();
  });

  it('reports billing provider configuration without gating readiness or leaking credentials', async () => {
    const unconfigured = await testApp(testConfig());
    const res1 = await unconfigured.inject({ method: 'GET', url: '/ready' });
    expect(res1.json().capabilities.billingGoogleConfigured).toBe(false);
    expect(res1.json().capabilities.billingAppleConfigured).toBe(false);
    // Billing being unconfigured must not block AI readiness.
    expect(res1.json().status).toBe('ready');
    await unconfigured.close();

    const googleConfigured = await testApp(
      testConfig({
        GOOGLE_PLAY_PACKAGE_NAME: 'app.oracly',
        GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: '{"type":"service_account"}',
      }),
    );
    const res2 = await googleConfigured.inject({ method: 'GET', url: '/ready' });
    expect(res2.json().capabilities.billingGoogleConfigured).toBe(true);
    expect(res2.json().capabilities.billingAppleConfigured).toBe(false);
    expect(JSON.stringify(res2.json())).not.toContain('service_account');
    await googleConfigured.close();
  });
});
