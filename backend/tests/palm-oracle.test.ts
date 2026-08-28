import { describe, expect, it } from 'vitest';
import {
  authHeader,
  palmOracleBody,
  testApp,
  testConfig,
} from './helpers.js';

describe('oracle kind palm contract', () => {
  it('accepts oracle/palm and builds Palm context for the provider', async () => {
    let seen = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      seen = String(init?.body ?? '');
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: 'Bu el okumasi sembolik bir yansima; kesin kader yok.',
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
      payload: palmOracleBody,
    });
    expect(res.json().success).toBe(true);
    expect(res.json().error).toBeUndefined();
    expect(seen).toContain('Palm');
    expect(seen).toContain('palm');
    expect(seen).toContain('Avuc acik');
    expect(seen).toContain('Kalp');
    expect(seen).not.toContain('invalid_request');
    await app.close();
  });

  it('rejects unknown oracle kinds with invalid_request', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        operation: 'oracle',
        payload: {
          userMessage: 'Ne anlatiyor?',
          context: { kind: 'hand_reading', overall: 'x'.repeat(20) },
        },
      },
    });
    expect(res.json().success).toBe(false);
    expect(res.json().error.code).toBe('invalid_request');
    await app.close();
  });
});
