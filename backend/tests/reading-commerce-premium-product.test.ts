/**
 * Gate B2 cross-listener finding — the app's reading-commerce listener sends
 * every Play purchase, Premium included, to /v1/reading-entitlements/verify.
 * This proves what the backend does with a Premium product there: it is
 * refused by the reading catalog before any store verification, so it can
 * never become a reading credit, even with a verifier that approves every
 * token. Measures current behavior; no source is changed.
 */
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import type { ConsumableVerifier } from '../src/reading/reading-commerce-verify.js';
import { ReadingEntitlementLedger } from '../src/reading/reading-entitlement-ledger.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

const SECRET = 'unit-test-jwt-secret';
const NOW = Date.parse('2026-10-26T15:24:14.000Z');
const WAIT = provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 });

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

async function harness() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(NOW);
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(repository, clock, WAIT);
  const entitlements = new ReadingEntitlementLedger(store);
  const gems = new GemLedger(store, clock, provisionalGemCostPolicy());
  let verifierCalls = 0;
  // Approves every token: whatever refuses Premium here is not the store.
  const approvesAll: ConsumableVerifier = {
    admitted: true,
    async verify(request) {
      verifierCalls += 1;
      return { ok: true, transactionId: `tx-${request.purchaseToken}` };
    },
  };
  const app = await testApp(
    testConfig({
      AI_JWT_SECRET: SECRET,
      AI_APP_CHECK_REQUIRED: 'true',
      ORACLY_COFFEE_V3_ENABLED: 'true',
      ORACLY_READING_COMMERCE_ENABLED: 'true',
      ORACLY_READING_BILLING_QA: 'true',
    }),
    async () => {
      throw new Error('commerce must not call the provider');
    },
    {
      appCheck: new StaticAppCheckVerifier('good-token'),
      readingOperationRepository: repository,
      readingClock: clock,
      readingWaitPolicy: WAIT,
      gemStore: store,
      gemLedger: gems,
      readingFlow: new ReadingFlow(store, clock, operations, gems, entitlements),
      readingCommerceVerifier: approvesAll,
    },
  );
  const verify = (productId: string, platform = 'android') =>
    app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/verify',
      headers: {
        ...authHeader(signHs256(SECRET, { sub: 'user-a' })),
        ...appCheckHeader('good-token'),
      },
      payload: { platform, productId, purchaseToken: 'premium-yearly-token' },
    });
  return { app, store, verify, verifierCalls: () => verifierCalls };
}

describe('a Premium product at the reading verify endpoint', () => {
  for (const productId of [
    'app.oracly.premium.yearly',
    'app.oracly.premium.monthly',
    'app.oracly.premium.lifetime',
  ]) {
    for (const platform of ['android', 'ios']) {
      it(`${productId} (${platform}): 400, store never asked, nothing stored`,
        async () => {
          const h = await harness();
          const before = h.store.docs.size;
          const res = await h.verify(productId, platform);
          expect(res.statusCode).toBe(400);
          expect(res.json()).toMatchObject({ success: false });
          expect(h.verifierCalls()).toBe(0);
          expect(h.store.docs.size).toBe(before);
          await h.app.close();
        });
    }
  }

  it('control: the same harness does grant a real reading product', async () => {
    const h = await harness();
    const res = await h.verify('app.oracly.reading.coffee');
    expect(res.statusCode).toBe(200);
    expect(h.verifierCalls()).toBe(1);
    expect(identityKeyFromSubject('user-a')).toMatch(/^sub:/);
    await h.app.close();
  });
});
