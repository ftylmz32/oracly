import { describe, expect, it } from 'vitest';
import type { AccountDeletionRepository, DeletionReceipt } from '../src/account/account-deletion.js';
import { StaticAppCheckVerifier } from '../src/auth/app-check.js';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { authHeader, appCheckHeader, signHs256, testApp, testConfig } from './helpers.js';

/**
 * P0-3 / 3A + 3B — the client binds its durable deletion target uid to the
 * request BEFORE the async token/App-Check/header pipeline runs, but a
 * client-side check alone cannot stop the LIVE Firebase identity from
 * changing to a different uid before the request's own auth token is
 * finalized — the request would then arrive authenticated as the NEW
 * identity even though the client believed it was still deleting the old
 * one. The backend must independently re-assert expectedTargetUid ==
 * request.identityKey (the verified auth identity) before ANY destructive
 * repository call — the body value is an anti-race ASSERTION, never an
 * authorization mechanism: the repository is always called for
 * request.identityKey and nothing else.
 */
const SECRET = 'target-binding-secret';

class DeletionFake implements AccountDeletionRepository {
  calls: string[] = [];
  async deleteForIdentity(identity: string): Promise<DeletionReceipt> {
    this.calls.push(identity);
    return {
      receiptId: `receipt-${identity}`,
      status: 'accepted',
      completedAt: new Date(0).toISOString(),
      deletedDocuments: 1,
      deletedObjects: 0,
      anonymizedPurchaseBindings: 0,
    };
  }
}

async function buildApp(repository: AccountDeletionRepository) {
  return testApp(
    testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
    undefined,
    { appCheck: new StaticAppCheckVerifier('target-app-check'), accountDeletionRepository: repository },
  );
}

function headersFor(uid: string) {
  return {
    ...authHeader(signHs256(SECRET, { sub: uid })),
    ...appCheckHeader('target-app-check'),
  };
}

describe('account deletion — expected-target-uid backend binding', () => {
  it('token identity A + expectedTargetUid A: accepted, repository called for A', async () => {
    const repository = new DeletionFake();
    const app = await buildApp(repository);
    const res = await app.inject({
      method: 'POST', url: '/v1/account/deletion', headers: headersFor('user-a'),
      payload: { expectedTargetUid: 'user-a' },
    });
    expect(res.statusCode).toBe(202);
    expect(repository.calls).toEqual([identityKeyFromSubject('user-a')]);
    await app.close();
  });

  it('token identity B + expectedTargetUid A: rejected, repository call count 0 — neither identity is touched', async () => {
    const repository = new DeletionFake();
    const app = await buildApp(repository);
    const res = await app.inject({
      method: 'POST', url: '/v1/account/deletion', headers: headersFor('user-b'),
      payload: { expectedTargetUid: 'user-a' },
    });
    expect(res.statusCode).toBe(409);
    expect(repository.calls).toHaveLength(0);
    await app.close();
  });

  it('missing expectedTargetUid fails closed — repository is never called', async () => {
    const repository = new DeletionFake();
    const app = await buildApp(repository);
    const res = await app.inject({
      method: 'POST', url: '/v1/account/deletion', headers: headersFor('user-c'),
      payload: {},
    });
    expect(res.statusCode).toBe(400);
    expect(repository.calls).toHaveLength(0);
    await app.close();
  });

  it('blank/whitespace-only expectedTargetUid fails closed', async () => {
    const repository = new DeletionFake();
    const app = await buildApp(repository);
    const res = await app.inject({
      method: 'POST', url: '/v1/account/deletion', headers: headersFor('user-d'),
      payload: { expectedTargetUid: '   ' },
    });
    expect(res.statusCode).toBe(400);
    expect(repository.calls).toHaveLength(0);
    await app.close();
  });

  it('malformed (non-string) expectedTargetUid fails closed', async () => {
    const repository = new DeletionFake();
    const app = await buildApp(repository);
    const res = await app.inject({
      method: 'POST', url: '/v1/account/deletion', headers: headersFor('user-e'),
      payload: { expectedTargetUid: { nested: true } },
    });
    expect(res.statusCode).toBe(400);
    expect(repository.calls).toHaveLength(0);
    await app.close();
  });

  it('a legacy empty-body request is rejected outright — never silently deletes data', async () => {
    const repository = new DeletionFake();
    const app = await buildApp(repository);
    const res = await app.inject({
      method: 'POST', url: '/v1/account/deletion', headers: headersFor('user-f'),
      payload: {},
    });
    expect(res.statusCode).toBe(400);
    expect(repository.calls).toHaveLength(0);
    await app.close();
  });
});
