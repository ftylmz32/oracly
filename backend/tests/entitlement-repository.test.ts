/**
 * Durable purchase-token <-> authenticated-uid entitlement binding.
 *
 * Proves semantics (never implementation details): a purchase token/
 * transaction bound to one identity can never be claimed by a different
 * identity, same-identity re-verification is idempotent, concurrent claims
 * resolve to exactly one winner, a storage failure never grants access, and
 * a "process restart" (a fresh repository instance over the same durable
 * backing store) does not lose or bypass an existing binding.
 */
import { describe, expect, it } from 'vitest';
import {
  FirestoreEntitlementRepository,
  InMemoryEntitlementRepository,
  FailClosedEntitlementRepository,
  purchaseBindingKey,
  type FirestoreDocSnapshotLike,
  type FirestoreLike,
  type FirestoreTransactionLike,
} from '../src/billing/entitlement-repository.js';
import { billingResult } from '../src/billing/types.js';
import type { StoreVerifier } from '../src/billing/types.js';
import { testApp, testConfig, signHs256 } from './helpers.js';

const ANDROID_META = { platform: 'android' as const, productId: 'app.oracly.premium.yearly' };
const IOS_META = { platform: 'ios' as const, productId: 'app.oracly.premium.yearly' };

/**
 * A tiny durable store standing in for Firestore itself (not the client
 * library) — a plain object map with per-document transaction
 * serialization. Two `FirestoreEntitlementRepository` instances can wrap
 * the *same* store to simulate two Cloud Run instances / a restart: if the
 * repository class held any hidden process-local state, a second instance
 * would not see the first instance's writes. It does, because the
 * repository delegates everything to this store.
 */
class FakeFirestoreStore implements FirestoreLike {
  private readonly docs = new Map<string, Record<string, unknown>>();
  private readonly queues = new Map<string, Promise<unknown>>();
  public failNextTransaction = false;
  anonymizeFirstBinding(): void {
    const first = this.docs.entries().next().value as [string, Record<string, unknown>] | undefined;
    if (first) this.docs.set(first[0], { ...first[1], identityKey: null, rebindEligible: true, previousOwnerHash: 'deleted-owner-hash' });
  }

  collection(_name: string) {
    return {
      doc: (id: string) => ({
        get: async (): Promise<FirestoreDocSnapshotLike> => {
          const data = this.docs.get(id);
          return { exists: data != null, data: () => data };
        },
      }),
    };
  }

  async runTransaction<T>(
    fn: (tx: FirestoreTransactionLike) => Promise<T>,
  ): Promise<T> {
    // Firestore serializes concurrent transactions touching the same
    // document; a single global queue is a safe (if coarser) stand-in.
    const prior = this.queues.get('*') ?? Promise.resolve();
    const run = prior.then(async () => {
      if (this.failNextTransaction) {
        this.failNextTransaction = false;
        throw new Error('simulated_storage_error');
      }
      const writes: Array<() => void> = [];
      const tx: FirestoreTransactionLike = {
        get: async (ref) => (ref as { get(): Promise<FirestoreDocSnapshotLike> }).get(),
        set: (ref, data) => {
          const id = (ref as unknown as { __id: string }).__id;
          writes.push(() => this.docs.set(id, data));
          return tx;
        },
        update: (ref, data) => {
          const id = (ref as unknown as { __id: string }).__id;
          writes.push(() => {
            const existing = this.docs.get(id) ?? {};
            this.docs.set(id, { ...existing, ...data });
          });
          return tx;
        },
        delete: (ref) => {
          const id = (ref as unknown as { __id: string }).__id;
          writes.push(() => this.docs.delete(id));
          return tx;
        },
      };
      const result = await fn(tx);
      for (const w of writes) w();
      return result;
    });
    this.queues.set(
      '*',
      run.then(
        () => undefined,
        () => undefined,
      ),
    );
    return run;
  }
}

// doc() above returns a plain ref without an id the transaction can use —
// give every ref its id so the fake transaction can address the same
// underlying map entry the non-transactional get() reads.
function collectionWithId(store: FakeFirestoreStore, name: string) {
  const real = store.collection(name);
  return {
    doc: (id: string) => Object.assign(real.doc(id), { __id: id }),
  };
}

function fakeFirestore(store: FakeFirestoreStore): FirestoreLike {
  return {
    collection: (name: string) => collectionWithId(store, name),
    runTransaction: (fn) => store.runTransaction(fn),
  };
}

describe('InMemoryEntitlementRepository — semantics', () => {
  it('1. first user claims a valid token', async () => {
    const repo = new InMemoryEntitlementRepository();
    const key = purchaseBindingKey('android', 'tok-1');
    expect(await repo.claim(key, 'user-a', ANDROID_META)).toBe('claimed');
    expect(await repo.peekOwner(key)).toBe('user-a');
  });

  it('2. same user repeats the same token — idempotent', async () => {
    const repo = new InMemoryEntitlementRepository();
    const key = purchaseBindingKey('android', 'tok-2');
    expect(await repo.claim(key, 'user-a', ANDROID_META)).toBe('claimed');
    expect(await repo.claim(key, 'user-a', ANDROID_META)).toBe('already_owned');
    expect(await repo.claim(key, 'user-a', ANDROID_META)).toBe('already_owned');
  });

  it('3. a second user attempting the same token is rejected', async () => {
    const repo = new InMemoryEntitlementRepository();
    const key = purchaseBindingKey('android', 'tok-3');
    expect(await repo.claim(key, 'user-a', ANDROID_META)).toBe('claimed');
    expect(await repo.claim(key, 'user-b', ANDROID_META)).toBe('owned_by_other');
    // The rejection must not silently reassign ownership.
    expect(await repo.peekOwner(key)).toBe('user-a');
  });

  it('4. concurrent claims from the same user resolve to exactly one claim + rest idempotent', async () => {
    const repo = new InMemoryEntitlementRepository();
    const key = purchaseBindingKey('android', 'tok-4');
    const results = await Promise.all([
      repo.claim(key, 'user-a', ANDROID_META),
      repo.claim(key, 'user-a', ANDROID_META),
      repo.claim(key, 'user-a', ANDROID_META),
    ]);
    expect(results.filter((r) => r === 'claimed')).toHaveLength(1);
    expect(results.filter((r) => r === 'already_owned')).toHaveLength(2);
    expect(await repo.peekOwner(key)).toBe('user-a');
  });

  it('5. concurrent claims from different users: exactly one wins, never both', async () => {
    const repo = new InMemoryEntitlementRepository();
    const key = purchaseBindingKey('android', 'tok-5');
    const results = await Promise.all([
      repo.claim(key, 'user-a', ANDROID_META),
      repo.claim(key, 'user-b', ANDROID_META),
    ]);
    const claimed = results.filter((r) => r === 'claimed');
    const rejected = results.filter((r) => r === 'owned_by_other');
    expect(claimed).toHaveLength(1);
    expect(rejected).toHaveLength(1);
    // The final owner must be whichever result was 'claimed'.
    const owner = await repo.peekOwner(key);
    expect(['user-a', 'user-b']).toContain(owner);
  });

  it('9. iOS transaction claims and rejects cross-user exactly like Android', async () => {
    const repo = new InMemoryEntitlementRepository();
    const key = purchaseBindingKey('ios', 'ios-transaction-1');
    expect(await repo.claim(key, 'user-a', IOS_META)).toBe('claimed');
    expect(await repo.claim(key, 'user-b', IOS_META)).toBe('owned_by_other');
    expect(await repo.claim(key, 'user-a', IOS_META)).toBe('already_owned');
  });
});

describe('FirestoreEntitlementRepository — restart / multi-instance safety', () => {
  it('6. a second repository instance over the same durable store sees the first instance\'s claim', async () => {
    const store = new FakeFirestoreStore();
    // Two independent repository objects — simulates a fresh instance
    // after a restart, or a second concurrently-running Cloud Run replica.
    const instanceA = new FirestoreEntitlementRepository(fakeFirestore(store));
    const instanceB = new FirestoreEntitlementRepository(fakeFirestore(store));

    const key = purchaseBindingKey('android', 'tok-restart');
    expect(await instanceA.claim(key, 'user-a', ANDROID_META)).toBe('claimed');

    // instanceB has never seen this claim in-process — if the class held
    // any hidden local cache, this would incorrectly say 'claimed' again.
    expect(await instanceB.claim(key, 'user-b', ANDROID_META)).toBe(
      'owned_by_other',
    );
    expect(await instanceB.peekOwner(key)).toBe('user-a');

    // The original owner re-verifying (e.g. after their own app restart)
    // through a brand new instance remains idempotent.
    expect(await instanceB.claim(key, 'user-a', ANDROID_META)).toBe(
      'already_owned',
    );
  });

  it('7. a storage failure returns error, never a grant', async () => {
    const store = new FakeFirestoreStore();
    store.failNextTransaction = true;
    const repo = new FirestoreEntitlementRepository(fakeFirestore(store));
    const key = purchaseBindingKey('android', 'tok-storage-fail');
    expect(await repo.claim(key, 'user-a', ANDROID_META)).toBe('error');
    // No partial/ghost binding was left behind by the failed attempt.
    expect(await repo.peekOwner(key)).toBeNull();
  });

  it('FailClosedEntitlementRepository never grants, regardless of caller', async () => {
    const repo = new FailClosedEntitlementRepository();
    expect(await repo.claim('any', 'user-a', ANDROID_META)).toBe('error');
    expect(await repo.peekOwner('any')).toBeNull();
  });
});

describe('POST /v1/billing/verify — durable binding end-to-end', () => {
  const YEARLY = 'app.oracly.premium.yearly';

  function authedConfig() {
    return testConfig({
      AI_DEV_AUTH_BYPASS: 'false',
      AI_AUTH_REQUIRED: 'true',
      AI_JWT_SECRET: 'entitlement-test-secret',
      AI_JWT_ISSUER: 'https://issuer.example',
      AI_JWT_AUDIENCE: 'oracly-ai',
      FIREBASE_PROJECT_ID: '',
      AI_JWKS_URL: '',
    });
  }

  function mockVerifier(impl: StoreVerifier['verify']): StoreVerifier {
    return { get configured() { return true; }, verify: impl };
  }

  function tokenFor(sub: string) {
    return signHs256('entitlement-test-secret', {
      sub,
      iss: 'https://issuer.example',
      aud: 'oracly-ai',
    });
  }

  async function verify(
    app: Awaited<ReturnType<typeof testApp>>,
    sub: string,
    payload: Record<string, unknown>,
  ) {
    return app.inject({
      method: 'POST',
      url: '/v1/billing/verify',
      headers: {
        authorization: `Bearer ${tokenFor(sub)}`,
        'content-type': 'application/json',
      },
      payload,
    });
  }

  it('8. Android: first claim active, second user rejected, same user idempotent', async () => {
    const app = await testApp(authedConfig(), undefined, {
      billing: { google: mockVerifier(async () => billingResult('active')) },
      entitlementRepository: new InMemoryEntitlementRepository(),
    });
    const payload = {
      platform: 'android',
      productId: YEARLY,
      purchaseToken: 'android-shared-token',
    };
    const first = await verify(app, 'user-a', payload);
    expect(first.json().status).toBe('active');

    const second = await verify(app, 'user-b', payload);
    expect(second.json()).toEqual({
      status: 'unverified',
      reason: 'purchase_bound_to_other_account',
    });

    // 10. Restore/reverification by the original owner must still succeed.
    const restore = await verify(app, 'user-a', payload);
    expect(restore.json().status).toBe('active');
    await app.close();
  });

  it('9. iOS: transaction id present, same cross-user + idempotency semantics', async () => {
    const app = await testApp(authedConfig(), undefined, {
      billing: { apple: mockVerifier(async () => billingResult('active')) },
      entitlementRepository: new InMemoryEntitlementRepository(),
    });
    const payload = {
      platform: 'ios',
      productId: YEARLY,
      purchaseToken: 'ios-receipt-blob',
      transactionId: 'ios-transaction-42',
    };
    const first = await verify(app, 'user-a', payload);
    expect(first.json().status).toBe('active');

    const second = await verify(app, 'user-b', payload);
    expect(second.json()).toEqual({
      status: 'unverified',
      reason: 'purchase_bound_to_other_account',
    });

    const restore = await verify(app, 'user-a', payload);
    expect(restore.json().status).toBe('active');
    await app.close();
  });

  it('a storage failure at claim time reports error, not active', async () => {
    const store = new FakeFirestoreStore();
    store.failNextTransaction = true;
    const app = await testApp(authedConfig(), undefined, {
      billing: { google: mockVerifier(async () => billingResult('active')) },
      entitlementRepository: new FirestoreEntitlementRepository(
        fakeFirestore(store),
      ),
    });
    const res = await verify(app, 'user-a', {
      platform: 'android',
      productId: YEARLY,
      purchaseToken: 'android-storage-fail-token',
    });
    expect(res.json()).toEqual({
      status: 'error',
      reason: 'entitlement_binding_unavailable',
    });
    await app.close();
  });

  it('concurrent verify requests from two different users for the same token: exactly one active', async () => {
    const app = await testApp(authedConfig(), undefined, {
      billing: { google: mockVerifier(async () => billingResult('active')) },
      entitlementRepository: new InMemoryEntitlementRepository(),
    });
    const payload = {
      platform: 'android',
      productId: YEARLY,
      purchaseToken: 'android-concurrent-token',
    };
    const [a, b] = await Promise.all([
      verify(app, 'user-a', payload),
      verify(app, 'user-b', payload),
    ]);
    const statuses = [a.json().status, b.json().status].sort();
    expect(statuses).toEqual(['active', 'unverified']);
    await app.close();
  });

  it('authoritative restore rebinds an anonymized deleted-owner binding to the new UID', async () => {
    const store = new FakeFirestoreStore();
    const repo = new FirestoreEntitlementRepository(fakeFirestore(store));
    const key = purchaseBindingKey('android', 'reinstall-token');
    expect(await repo.claim(key, 'old-uid', ANDROID_META)).toBe('claimed');
    store.anonymizeFirstBinding();
    expect(await repo.claim(key, 'new-uid', ANDROID_META)).toBe('claimed');
    expect(await repo.peekOwner(key)).toBe('new-uid');
    expect(await repo.claim(key, 'old-uid', ANDROID_META)).toBe('owned_by_other');
  });
});
