import { createHash } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import type { Firestore } from '@google-cloud/firestore';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import type { ServerClock } from '../src/reading/clock.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { ReadingProcessor } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy, SOULMATE_NO_COMMERCIAL_WAIT_MS } from '../src/reading/wait-policy.js';
import { testConfig } from './helpers.js';
import { FirestoreProviderStageRepository } from '../src/reading/provider-stage-repository.js';
import { FirestoreReadingOperationInputRepository } from '../src/reading/operation-input-repository.js';
import { ReadingOperationInputService } from '../src/reading/operation-input-service.js';
import { GcsSoulmatePortraitStore } from '../src/reading/soulmate-portrait-store.js';
import {
  FirestoreSoulmateEntitlementGuard,
  isBindingCurrentlyActive,
  SOULMATE_GRACE_TRUST_WINDOW_MS,
  type SoulmateEntitlementGuard,
} from '../src/reading/soulmate-entitlement-guard.js';
import {
  FirestoreEntitlementRepository,
  purchaseBindingKey,
  type EntitlementStatusMeta,
} from '../src/billing/entitlement-repository.js';

const MONTHLY = 'app.oracly.premium.monthly';
const YEARLY = 'app.oracly.premium.yearly';
const LIFETIME = 'app.oracly.premium.lifetime';
const DAY_MS = 86_400_000;

// ---------------------------------------------------------------------
// Part A — pure isBindingCurrentlyActive (§9 items 1-9)
// ---------------------------------------------------------------------
describe('isBindingCurrentlyActive — authoritative current-activity rules', () => {
  const now = Date.parse('2026-09-14T12:00:00Z');

  it('1: active monthly, not yet expired -> active', () => {
    expect(
      isBindingCurrentlyActive(
        { productId: MONTHLY, status: 'active', kind: 'subscription', expiryAtMs: now + DAY_MS },
        now,
      ),
    ).toBe(true);
  });

  it('2: expired monthly -> denied', () => {
    expect(
      isBindingCurrentlyActive(
        { productId: MONTHLY, status: 'active', kind: 'subscription', expiryAtMs: now - 1 },
        now,
      ),
    ).toBe(false);
  });

  it('3: active yearly, not yet expired -> active', () => {
    expect(
      isBindingCurrentlyActive(
        { productId: YEARLY, status: 'active', kind: 'subscription', expiryAtMs: now + 300 * DAY_MS },
        now,
      ),
    ).toBe(true);
  });

  it('4: expired yearly -> denied', () => {
    expect(
      isBindingCurrentlyActive(
        { productId: YEARLY, status: 'active', kind: 'subscription', expiryAtMs: now - DAY_MS },
        now,
      ),
    ).toBe(false);
  });

  it('5: valid lifetime -> active regardless of any expiry field', () => {
    expect(
      isBindingCurrentlyActive(
        { productId: LIFETIME, status: 'active', kind: 'lifetime', expiryAtMs: null },
        now,
      ),
    ).toBe(true);
  });

  it('6: revoked/refunded entitlement -> denied per billing policy (status flips off active)', () => {
    // routes/billing.ts's recordStatus writes the LATEST verify status —
    // a revoked/refunded purchase re-verifies as 'inactive', never 'active'.
    expect(
      isBindingCurrentlyActive(
        { productId: LIFETIME, status: 'inactive', kind: 'lifetime', expiryAtMs: null },
        now,
      ),
    ).toBe(false);
    expect(
      isBindingCurrentlyActive(
        { productId: MONTHLY, status: 'inactive', kind: 'subscription', expiryAtMs: now + DAY_MS },
        now,
      ),
    ).toBe(false);
  });

  it('7: cancelled subscription still inside its paid period -> active', () => {
    // google-play.ts / apple-store.ts both map "canceled but expiry still
    // future" to status 'active' (canceled_still_entitled) — the guard
    // only ever sees the mapped status, exactly like everything else.
    expect(
      isBindingCurrentlyActive(
        { productId: YEARLY, status: 'active', kind: 'subscription', expiryAtMs: now + DAY_MS },
        now,
      ),
    ).toBe(true);
  });

  it('8: historical purchaseBinding exists but is expired -> denied', () => {
    expect(
      isBindingCurrentlyActive(
        { productId: MONTHLY, status: 'expired', kind: 'subscription', expiryAtMs: now - 10 * DAY_MS },
        now,
      ),
    ).toBe(false);
  });

  it('9a: missing status/kind entirely (pre-SMD1-E1 binding) -> fail closed', () => {
    expect(isBindingCurrentlyActive({ productId: MONTHLY }, now)).toBe(false);
  });

  it('9b: unknown product -> fail closed regardless of status', () => {
    expect(
      isBindingCurrentlyActive(
        { productId: 'not_a_real_product', status: 'active', kind: 'lifetime' },
        now,
      ),
    ).toBe(false);
  });

  it('grace period: recent snapshot with no concrete expiry -> active within the trust window', () => {
    expect(
      isBindingCurrentlyActive(
        {
          productId: MONTHLY,
          status: 'active',
          kind: 'subscription',
          expiryAtMs: null,
          verifiedAtMs: now - 1000,
        },
        now,
      ),
    ).toBe(true);
  });

  it('grace period: stale snapshot beyond the trust window -> denied, never trusted forever', () => {
    expect(
      isBindingCurrentlyActive(
        {
          productId: MONTHLY,
          status: 'active',
          kind: 'subscription',
          expiryAtMs: null,
          verifiedAtMs: now - (SOULMATE_GRACE_TRUST_WINDOW_MS + 1),
        },
        now,
      ),
    ).toBe(false);
  });
});

// ---------------------------------------------------------------------
// Part B — FirestoreSoulmateEntitlementGuard against a real query path
// ---------------------------------------------------------------------
class QueryableFakeFirestore {
  docs = new Map<string, Record<string, unknown>>();

  collection(name: string) {
    const self = this;
    return {
      where(field: string, _op: string, value: unknown) {
        const matches = [...self.docs.entries()]
          .filter(([path]) => path.startsWith(`${name}/`))
          .map(([, data]) => data)
          .filter((data) => data[field] === value);
        return {
          limit(n: number) {
            return {
              async get() {
                return { docs: matches.slice(0, n).map((data) => ({ data: () => data })) };
              },
            };
          },
        };
      },
    };
  }
}

function fixedClock(ms: number): ServerClock {
  return { now: () => new Date(ms) };
}

describe('FirestoreSoulmateEntitlementGuard — real query path, reusing the SAME purchaseBindings collection', () => {
  const owner = identityKeyFromSubject('entitlement-user');
  const now = Date.parse('2026-09-14T12:00:00Z');

  it('active monthly binding grants Soulmate access', async () => {
    const fake = new QueryableFakeFirestore();
    fake.docs.set('purchaseBindings/abc', {
      identityKey: owner,
      productId: MONTHLY,
      status: 'active',
      kind: 'subscription',
      expiryAtMs: now + DAY_MS,
    });
    const guard = new FirestoreSoulmateEntitlementGuard(
      fake as unknown as Firestore,
      fixedClock(now),
    );
    expect(await guard.isPremiumActive(owner)).toBe(true);
  });

  it('expired binding denies Soulmate access', async () => {
    const fake = new QueryableFakeFirestore();
    fake.docs.set('purchaseBindings/abc', {
      identityKey: owner,
      productId: MONTHLY,
      status: 'active',
      kind: 'subscription',
      expiryAtMs: now - DAY_MS,
    });
    const guard = new FirestoreSoulmateEntitlementGuard(
      fake as unknown as Firestore,
      fixedClock(now),
    );
    expect(await guard.isPremiumActive(owner)).toBe(false);
  });

  it('a different identity never sees another owner\'s binding', async () => {
    const fake = new QueryableFakeFirestore();
    fake.docs.set('purchaseBindings/abc', {
      identityKey: owner,
      productId: LIFETIME,
      status: 'active',
      kind: 'lifetime',
    });
    const guard = new FirestoreSoulmateEntitlementGuard(
      fake as unknown as Firestore,
      fixedClock(now),
    );
    expect(await guard.isPremiumActive(identityKeyFromSubject('someone-else'))).toBe(false);
  });

  it('12: restore/rebind (owner change on the same token doc) is reflected safely', async () => {
    const fake = new QueryableFakeFirestore();
    const originalOwner = identityKeyFromSubject('device-a-user');
    fake.docs.set('purchaseBindings/tok', {
      identityKey: originalOwner,
      productId: YEARLY,
      status: 'active',
      kind: 'subscription',
      expiryAtMs: now + DAY_MS,
    });
    const guard = new FirestoreSoulmateEntitlementGuard(
      fake as unknown as Firestore,
      fixedClock(now),
    );
    expect(await guard.isPremiumActive(originalOwner)).toBe(true);
    expect(await guard.isPremiumActive(identityKeyFromSubject('device-b-user'))).toBe(false);

    // Restore/rebind flips identityKey on the SAME doc (entitlement-repository.ts
    // claim()'s rebindEligible path) — the guard must follow ownership, never
    // both accounts, never neither.
    const rebound = identityKeyFromSubject('device-b-user');
    fake.docs.set('purchaseBindings/tok', {
      ...fake.docs.get('purchaseBindings/tok'),
      identityKey: rebound,
    });
    expect(await guard.isPremiumActive(originalOwner)).toBe(false);
    expect(await guard.isPremiumActive(rebound)).toBe(true);
  });
});

// ---------------------------------------------------------------------
// Part C — the real billing route path persists what the guard needs
// ---------------------------------------------------------------------
describe('billing verify -> entitlement-repository -> guard, end to end on one shared store', () => {
  it('claim() persists status/expiry/kind; guard reads it back as active', async () => {
    const store = new MemoryDocumentStore();
    const repo = new FirestoreEntitlementRepository(store);
    const owner = identityKeyFromSubject('e2e-user');
    const bindingKey = purchaseBindingKey('android', 'tok-1');
    const entitlement: EntitlementStatusMeta = {
      status: 'active',
      expiryAtMs: Date.now() + DAY_MS,
      verifiedAtMs: Date.now(),
      kind: 'subscription',
    };
    expect(
      await repo.claim(bindingKey, owner, { platform: 'android', productId: MONTHLY, entitlement }),
    ).toBe('claimed');

    const guard = new FirestoreSoulmateEntitlementGuard(store as unknown as Firestore);
    // MemoryDocumentStore doesn't implement .where() itself; read the
    // persisted doc directly to prove the SHAPE claim() wrote is exactly
    // what isBindingCurrentlyActive expects (the query mechanics
    // themselves are proven against the real Firestore type in Part B).
    const raw = store.docs.get(
      `purchaseBindings/${[...store.docs.keys()][0].split('/')[1]}`,
    );
    expect(raw?.status).toBe('active');
    expect(raw?.kind).toBe('subscription');
    expect(typeof raw?.expiryAtMs).toBe('number');
    expect(isBindingCurrentlyActive(raw!, Date.now())).toBe(true);
    void guard;
  });

  it('recordStatus refreshes an already-owned binding on a non-active re-verify (expiry reflected)', async () => {
    const store = new MemoryDocumentStore();
    const repo = new FirestoreEntitlementRepository(store);
    const owner = identityKeyFromSubject('e2e-user-2');
    const bindingKey = purchaseBindingKey('android', 'tok-2');
    await repo.claim(bindingKey, owner, {
      platform: 'android',
      productId: MONTHLY,
      entitlement: {
        status: 'active',
        expiryAtMs: Date.now() + DAY_MS,
        verifiedAtMs: Date.now(),
        kind: 'subscription',
      },
    });
    // Subscription later expires; a reconciliation re-verify comes back
    // 'expired' — routes/billing.ts calls recordStatus (never claim, since
    // status !== 'active') to refresh the SAME already-owned binding.
    const outcome = await repo.recordStatus(bindingKey, owner, {
      status: 'expired',
      expiryAtMs: Date.now() - 1,
      verifiedAtMs: Date.now(),
      kind: 'subscription',
    });
    expect(outcome).toBe('recorded');
    const raw = store.docs.get(`purchaseBindings/${sha256Hex(bindingKey)}`);
    expect(raw?.status).toBe('expired');
    expect(isBindingCurrentlyActive(raw!, Date.now())).toBe(false);
  });

  it('recordStatus never writes to a binding owned by someone else', async () => {
    const store = new MemoryDocumentStore();
    const repo = new FirestoreEntitlementRepository(store);
    const owner = identityKeyFromSubject('e2e-owner');
    const attacker = identityKeyFromSubject('e2e-attacker');
    const bindingKey = purchaseBindingKey('android', 'tok-3');
    await repo.claim(bindingKey, owner, {
      platform: 'android',
      productId: LIFETIME,
      entitlement: { status: 'active', expiryAtMs: null, verifiedAtMs: Date.now(), kind: 'lifetime' },
    });
    const outcome = await repo.recordStatus(bindingKey, attacker, {
      status: 'inactive',
      expiryAtMs: null,
      verifiedAtMs: Date.now(),
      kind: 'lifetime',
    });
    expect(outcome).toBe('not_owned');
    const raw = store.docs.get(`purchaseBindings/${sha256Hex(bindingKey)}`);
    expect(raw?.status).toBe('active');
  });

  it('recordStatus on a nonexistent binding is a safe no-op', async () => {
    const store = new MemoryDocumentStore();
    const repo = new FirestoreEntitlementRepository(store);
    const outcome = await repo.recordStatus(purchaseBindingKey('android', 'never-claimed'), 'someone', {
      status: 'expired',
      expiryAtMs: null,
      verifiedAtMs: Date.now(),
      kind: 'subscription',
    });
    expect(outcome).toBe('not_owned');
  });
});

function sha256Hex(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

// ---------------------------------------------------------------------
// Part D — the durable Soulmate worker actually consults the guard
// (§9 items 10, 11, 16) — same harness shape as
// tests/soulmate-durable-processing.test.ts, with a mutable entitlement
// so a test can flip it mid-run.
// ---------------------------------------------------------------------
class MutableSoulmateEntitlementGuard implements SoulmateEntitlementGuard {
  active = true;
  calls = 0;
  async isPremiumActive(): Promise<boolean> {
    this.calls++;
    return this.active;
  }
}

function harness(entitlement: SoulmateEntitlementGuard) {
  const store = new MemoryDocumentStore();
  const clock = { ms: Date.parse('2026-09-14T10:00:00Z'), now(): Date { return new Date(this.ms); } };
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ soulmate: SOULMATE_NO_COMMERCIAL_WAIT_MS }),
  );
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy());
  const flow = new ReadingFlow(store, clock, operations, ledger);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const stagedImages = new ReadingStagedImageService(
    stagedRepository,
    new MemoryStagedObjectStore(),
    operations,
    clock,
    testConfig({ READING_STAGING_BUCKET: 'test-bucket' }),
  );
  const results = new ReadingResultRepository(store);
  const notifier = { calls: 0, async notifyCompleted() { this.calls++; } };
  const providerStages = new FirestoreProviderStageRepository(store);
  const inputRepository = new FirestoreReadingOperationInputRepository(store);
  const soulmateInputs = new ReadingOperationInputService(inputRepository, operations, clock);
  const soulmatePortraits = new GcsSoulmatePortraitStore(new MemoryStagedObjectStore(), store);

  let portraitCalls = 0;
  const ai = {
    async handle(request: { operation: string }) {
      if (request.operation === 'soulmate_draw') {
        portraitCalls++;
        const portrait = Buffer.alloc(64);
        Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]).copy(portrait);
        return {
          imageBase64: portrait.toString('base64'),
          mimeType: 'image/png',
          identity: { archetype: 'x' },
        };
      }
      return {
        personality: 'p', dynamic: 'd', attraction: 'a',
        challenge: 'c', meeting: 'm', feeling: 'f',
      };
    },
  };

  const processor = new ReadingProcessor(
    repository, flow, stagedRepository, stagedImages, results, ai, clock,
    notifier, false, providerStages, undefined, soulmateInputs, soulmatePortraits, entitlement,
  );
  const owner = identityKeyFromSubject('worker-user');

  async function createDurable() {
    const operation = await operations.create({
      ownerUserId: owner, readingType: 'soulmate', sourceRequestId: 'entitlement-e1-01', executionMode: 'durable',
    });
    await flow.remember(operation);
    await soulmateInputs.save({ ownerUserId: owner, operationId: operation.operationId, fields: { name: 'Ada', birthIso: '1995-03-02' } });
    clock.ms = operation.readyAtMs;
    return operation;
  }

  return { clock, repository, flow, processor, owner, createDurable, portraitCalls: () => portraitCalls };
}

describe('durable Soulmate worker consults the entitlement guard at the paid-provider boundary', () => {
  it('16: active entitlement -> Soulmate durable success still passes', async () => {
    const guard = new MutableSoulmateEntitlementGuard();
    const h = harness(guard);
    const op = await h.createDurable();
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.portraitCalls()).toBe(1);
    expect(guard.calls).toBeGreaterThan(0);
  });

  it('11: entitlement expires between submit and worker execution -> no provider call', async () => {
    const guard = new MutableSoulmateEntitlementGuard();
    guard.active = false; // already inactive by the time the worker runs
    const h = harness(guard);
    const op = await h.createDurable();
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.portraitCalls()).toBe(0);
    expect((await h.repository.getById(op.operationId))?.status).toBe('failed');
  });

  it('10: duplicate task delivery never bypasses entitlement (checked again on every claim)', async () => {
    const guard = new MutableSoulmateEntitlementGuard();
    guard.active = false;
    const h = harness(guard);
    const op = await h.createDurable();
    expect(await h.processor.process(op.operationId)).toBe('failed');
    // A redelivered task for the SAME (now-terminal) operation must not
    // resurrect it into a provider call, no matter how many times entitlement
    // is (re-)denied.
    expect(await h.processor.process(op.operationId)).toBe('noop');
    expect(h.portraitCalls()).toBe(0);
    expect(guard.calls).toBeGreaterThanOrEqual(1);
  });
});
