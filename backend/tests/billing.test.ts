import { describe, expect, it } from 'vitest';
import { testApp, testConfig } from './helpers.js';

describe('billing verify stub', () => {
  it('returns unverified and never invents active', async () => {
    const app = await testApp(testConfig());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/billing/verify',
      payload: {
        platform: 'android',
        productId: 'app.oracly.premium.yearly',
        purchaseToken: 'test-token',
      },
    });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      status: 'unverified',
      reason: 'provider_not_configured',
    });
    expect(JSON.stringify(res.json()).includes('"active"')).toBe(false);
    await app.close();
  });
});