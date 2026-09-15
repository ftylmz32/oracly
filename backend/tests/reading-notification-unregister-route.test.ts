import { describe, expect, it } from 'vitest';
import { buildServer } from '../src/server.js';
import { StaticAppCheckVerifier } from '../src/auth/app-check.js';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { ReadingNotificationTokens } from '../src/reading/reading-notifications.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemorySharedWindowStore } from '../src/rate-limit/shared-window-store.js';
import { FirestoreResponseReplayRepository } from '../src/middleware/response-replay-repository.js';
import { authHeader, appCheckHeader, signHs256, testConfig } from './helpers.js';

const SECRET = 'unregister-route-secret';
const APP_CHECK = 'unregister-app-check';

function headersFor(sub: string): Record<string, string> {
  return {
    ...authHeader(signHs256(SECRET, { sub })),
    ...appCheckHeader(APP_CHECK),
  };
}

async function buildTestApp(tokens: ReadingNotificationTokens) {
  return buildServer({
    config: testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
    logger: false,
    appCheck: new StaticAppCheckVerifier(APP_CHECK),
    sharedWindowStore: new MemorySharedWindowStore(),
    responseReplayRepository: new FirestoreResponseReplayRepository(
      new MemoryDocumentStore(),
    ),
    readingNotificationTokens: tokens,
  });
}

describe('POST /v1/reading-notifications/token/unregister', () => {
  it("removes the caller's own token using only the authenticated identity — no token in the request body at all", async () => {
    const tokens = new ReadingNotificationTokens(new MemoryDocumentStore());
    const app = await buildTestApp(tokens);
    const headers = headersFor('owner-a');

    const registered = await app.inject({
      method: 'POST',
      url: '/v1/reading-notifications/token',
      headers,
      payload: { token: 'a'.repeat(40) },
    });
    expect(registered.statusCode).toBe(200);
    expect(await tokens.get(identityKeyFromSubject('owner-a'))).toBe('a'.repeat(40));

    const unregistered = await app.inject({
      method: 'POST',
      url: '/v1/reading-notifications/token/unregister',
      headers,
      payload: {},
    });
    expect(unregistered.statusCode).toBe(200);
    expect(unregistered.json().data.unregistered).toBe(true);
    expect(await tokens.get(identityKeyFromSubject('owner-a'))).toBeNull();

    await app.close();
  });

  it('is idempotent — unregistering when nothing is registered still succeeds', async () => {
    const app = await buildTestApp(new ReadingNotificationTokens(new MemoryDocumentStore()));
    const response = await app.inject({
      method: 'POST',
      url: '/v1/reading-notifications/token/unregister',
      headers: headersFor('owner-never-registered'),
      payload: {},
    });
    expect(response.statusCode).toBe(200);
    expect(response.json().data.unregistered).toBe(true);

    // Repeating it again is still safe.
    const again = await app.inject({
      method: 'POST',
      url: '/v1/reading-notifications/token/unregister',
      headers: headersFor('owner-never-registered'),
      payload: {},
    });
    expect(again.statusCode).toBe(200);

    await app.close();
  });

  it("owner B cannot remove owner A's token — the route reads no owner/user id from the request at all", async () => {
    const tokens = new ReadingNotificationTokens(new MemoryDocumentStore());
    const app = await buildTestApp(tokens);

    await app.inject({
      method: 'POST',
      url: '/v1/reading-notifications/token',
      headers: headersFor('owner-a'),
      payload: { token: 'b'.repeat(40) },
    });

    const response = await app.inject({
      method: 'POST',
      url: '/v1/reading-notifications/token/unregister',
      headers: headersFor('owner-b'),
      payload: {},
    });
    expect(response.statusCode).toBe(200);

    // Owner A's registration must have survived owner B's call untouched.
    expect(await tokens.get(identityKeyFromSubject('owner-a'))).toBe('b'.repeat(40));

    await app.close();
  });

  it('requires authentication — no auth header means no identity to unregister', async () => {
    const app = await buildTestApp(new ReadingNotificationTokens(new MemoryDocumentStore()));
    const response = await app.inject({
      method: 'POST',
      url: '/v1/reading-notifications/token/unregister',
      headers: appCheckHeader(APP_CHECK),
    });
    expect(response.statusCode).toBe(401);
    await app.close();
  });

  it('never logs or echoes a raw token value for either register or unregister', async () => {
    const tokens = new ReadingNotificationTokens(new MemoryDocumentStore());
    const app = await buildTestApp(tokens);
    const headers = headersFor('owner-a');
    const rawToken = 'super-secret-fcm-token-value-should-never-appear';

    const registered = await app.inject({
      method: 'POST',
      url: '/v1/reading-notifications/token',
      headers,
      payload: { token: rawToken },
    });
    expect(JSON.stringify(registered.json())).not.toContain(rawToken);

    const unregistered = await app.inject({
      method: 'POST',
      url: '/v1/reading-notifications/token/unregister',
      headers,
      payload: {},
    });
    expect(JSON.stringify(unregistered.json())).not.toContain(rawToken);

    await app.close();
  });
});
