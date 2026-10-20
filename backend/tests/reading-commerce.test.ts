/**
 * Dark reading commerce. Fake store verifier only. No provider call.
 * A closed live verifier is not a store-payment pass.
 */
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { loadConfig } from '../src/config.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { GEM_DAILY_REWARD } from '../src/reading/gem-wallet-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { createClosedConsumableVerifier } from '../src/reading/reading-commerce-verify.js';
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

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

const SECRET = 'unit-test-jwt-secret';
const NOW = Date.parse('2026-10-20T12:00:00.000Z');
const INTENTION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';

const admitting: ConsumableVerifier = {
  admitted: true,
  async verify(request) {
    if (!request.purchaseToken.startsWith('valid-')) return { ok: false, reason: 'unverified' };
    return { ok: true, transactionId: `tx-${request.purchaseToken}` };
  },
};

function commerceConfig(extra: Record<string, string> = {}) {
  return testConfig({
    AI_JWT_SECRET: SECRET,
    AI_APP_CHECK_REQUIRED: 'true',
    AI_DAILY_SPEND_CAP_USD: '5',
    ORACLY_COFFEE_V3_ENABLED: 'true',
    ORACLY_READING_COMMERCE_ENABLED: 'true',
    ORACLY_READING_TRIAL_ENABLED: 'true',
    ...extra,
  });
}

async function harness(verifier: ConsumableVerifier = createClosedConsumableVerifier(), config = commerceConfig()) {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(NOW);
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ coffee: 2 * 60 * 60 * 1000, palm: 4 * 60 * 60 * 1000, soulmate: 1000 }),
  );
  const entitlements = new ReadingEntitlementLedger(store);
  const gems = new GemLedger(store, clock, provisionalGemCostPolicy());
  const flow = new ReadingFlow(store, clock, operations, gems, entitlements);
  const app = await testApp(config, async () => {
    throw new Error('commerce must not call the provider');
  }, {
    appCheck: new StaticAppCheckVerifier('good-token'),
    readingOperationRepository: repository,
    readingClock: clock,
    readingWaitPolicy: provisionalWaitPolicy({ coffee: 2 * 60 * 60 * 1000, palm: 4 * 60 * 60 * 1000, soulmate: 1000 }),
    gemStore: store,
    gemLedger: gems,
    readingFlow: flow,
    readingCommerceVerifier: verifier,
  });
  const headers = (sub = 'user-a') => ({
    ...authHeader(signHs256(SECRET, { sub })),
    ...appCheckHeader('good-token'),
  });
  return { app, store, clock, operations, entitlements, gems, flow, headers };
}

function events(store: MemoryDocumentStore) {
  return [...store.docs.entries()]
    .filter(([key]) => key.startsWith('readingCommerceEvents/'))
    .map(([, value]) => value);
}

describe('reading commerce stays dark and store-closed', () => {
  it('defaults both flags off and the deploy script does not turn commerce on', () => {
    const config = testConfig();
    expect(config.readingCommerceEnabled).toBe(false);
    expect(config.readingTrialEnabled).toBe(false);
    expect(loadConfig({ APP_ENV: 'production', OPENAI_API_KEY: 'sk-test' }).readingCommerceEnabled).toBe(false);
    const script = readFileSync(new URL('../scripts/deploy-cloud-run.sh', import.meta.url), 'utf8');
    expect(script.includes('ORACLY_READING_COMMERCE_ENABLED=true')).toBe(false);
    expect(createClosedConsumableVerifier().admitted).toBe(false);
    expect(GEM_DAILY_REWARD).toBe(25);
  });

  it('closed commerce keeps the palm wait and hides prices', async () => {
    const { app, headers } = await harness(createClosedConsumableVerifier(), testConfig({
      AI_JWT_SECRET: SECRET,
      AI_APP_CHECK_REQUIRED: 'true',
    }));
    const catalog = await app.inject({ method: 'GET', url: '/v1/reading-entitlements/catalog', headers: headers() });
    expect(catalog.json().data.commerce).toBe('closed');
    expect(catalog.json().data.proposals).toBeUndefined();
    const created = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: headers(),
      payload: { readingType: 'palm', sourceRequestId: 'palm-legacy-01' },
    });
    expect(created.statusCode).toBe(200);
    expect(created.json().data.remainingMs).toBe(4 * 60 * 60 * 1000);
  });

  it('the live verifier grants nothing and a client price is rejected', async () => {
    const { app, headers, entitlements } = await harness();
    const owner = identityKeyFromSubject('user-a');
    const catalog = await app.inject({ method: 'GET', url: '/v1/reading-entitlements/catalog', headers: headers() });
    expect(catalog.json().data.purchasable).toBe(false);
    expect(catalog.json().data.storeAdmitted).toBe(false);
    expect(catalog.json().data.proposals[0].chargeAuthority).toBe('store_catalog');
    const denied = await app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/verify',
      headers: headers(),
      payload: { platform: 'android', productId: 'app.oracly.reading.palm', purchaseToken: 'valid-palm', priceMinor: 1 },
    });
    expect(denied.statusCode).toBe(400);
    const closed = await app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/verify',
      headers: headers(),
      payload: { platform: 'android', productId: 'app.oracly.reading.palm', purchaseToken: 'valid-palm' },
    });
    expect(closed.json().data).toMatchObject({ granted: false, reason: 'store_not_admitted' });
    expect((await entitlements.balance(owner)).palm).toBe(0);
  });
});

describe('entitled creates are immediate and old rights stay', () => {
  it('refuses a free palm or coffee v3, then spends one credit with no gem offer', async () => {
    const { app, store, headers, entitlements, gems } = await harness(admitting);
    const owner = identityKeyFromSubject('user-a');
    await gems.credit({ ownerUserId: owner, amount: 25, idempotencyKey: 'daily-seed-01' });
    const blocked = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: headers(),
      payload: { readingType: 'palm', sourceRequestId: 'palm-paid-0001' },
    });
    expect(blocked.statusCode).toBe(403);
    expect(blocked.json().error.code).toBe('reading_entitlement_required');
    const legacy = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: headers(),
      payload: { readingType: 'coffee', sourceRequestId: 'coffee-old-001' },
    });
    expect(legacy.json().data.remainingMs).toBe(2 * 60 * 60 * 1000);
    const bought = await app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/verify',
      headers: headers(),
      payload: { platform: 'android', productId: 'app.oracly.reading.palm', purchaseToken: 'valid-palm-1' },
    });
    expect(bought.json().data.granted).toBe(true);
    expect(bought.json().data.balance.palm).toBe(1);
    const replay = await app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/verify',
      headers: headers(),
      payload: { platform: 'android', productId: 'app.oracly.reading.palm', purchaseToken: 'valid-palm-1' },
    });
    expect(replay.json().data.idempotent).toBe(true);
    expect(replay.json().data.balance.palm).toBe(1);
    const other = await app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/verify',
      headers: headers('user-b'),
      payload: { platform: 'android', productId: 'app.oracly.reading.palm', purchaseToken: 'valid-palm-1' },
    });
    expect(other.json().data.reason).toBe('purchase_bound_to_other_account');
    const opened = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: headers(),
      payload: { readingType: 'palm', sourceRequestId: 'palm-paid-0001' },
    });
    expect(opened.statusCode).toBe(200);
    expect(opened.json().data.remainingMs).toBe(0);
    expect(opened.json().data.waitFinished).toBe(true);
    expect((await entitlements.balance(owner)).palm).toBe(0);
    expect(await gems.balanceOf(owner)).toBe(25);
    const again = await app.inject({
      method: 'POST',
      url: '/v1/reading-operations',
      headers: headers(),
      payload: { readingType: 'palm', sourceRequestId: 'palm-paid-0001' },
    });
    expect(again.json().data.operationId).toBe(opened.json().data.operationId);
    expect((await entitlements.balance(owner)).palm).toBe(0);
    const quote = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${opened.json().data.operationId}/accelerate`,
      headers: headers(),
    });
    expect(quote.json().data.payable).toBe(false);
    const accel = await gems.accelerate({
      ownerUserId: owner,
      operationId: opened.json().data.operationId,
      idempotencyKey: 'accel-instant-1',
    });
    expect(accel.outcome).toBe('already_eligible');
    expect(await gems.balanceOf(owner)).toBe(25);
    for (const event of events(store)) {
      expect(JSON.stringify(event)).not.toMatch(/image|photo|intention|byte/i);
    }
  });

  it('restores one credit after failure and keeps it after success', async () => {
    const { app, store, headers, entitlements, flow } = await harness(admitting);
    const owner = identityKeyFromSubject('user-a');
    await app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/verify',
      headers: headers(),
      payload: { platform: 'ios', productId: 'app.oracly.reading.coffee.pack3', purchaseToken: 'valid-pack' },
    });
    expect((await entitlements.balance(owner)).coffee).toBe(3);
    const first = await openV3(app, headers(), 'coffee-pack-001');
    const failed = await flow.failFinal({ ownerUserId: owner, operationId: first, failureCode: 'unavailable' });
    expect(failed.status).toBe('failed');
    expect((await entitlements.balance(owner)).coffee).toBe(3);
    await flow.failFinal({ ownerUserId: owner, operationId: first, failureCode: 'unavailable' });
    expect((await entitlements.balance(owner)).coffee).toBe(3);
    const second = await openV3(app, headers(), 'coffee-pack-002');
    await flow.claim(owner, second);
    await flow.complete({ ownerUserId: owner, operationId: second, resultId: 'result-coffee-1' });
    expect((await entitlements.balance(owner)).coffee).toBe(2);
    const names = events(store).map((event) => event.name);
    expect(names).toContain('purchase_completed');
    expect(names).toContain('reading_completed');
    expect(names).toContain('entitlement_restored');
    expect(names.filter((name) => name === 'entitlement_restored')).toHaveLength(1);
  });

  it('stops before a trial when the spend guard is shut, and grants one coffee when it is open', async () => {
    const shut = await harness(admitting, commerceConfig({ AI_SPEND_KILL_SWITCH: 'true' }));
    const trial = await shut.app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/trial',
      headers: shut.headers(),
      payload: {},
    });
    expect(trial.statusCode).toBe(503);
    expect(trial.json().error.code).toBe('spend_guard');
    const { app, headers, entitlements } = await harness(admitting);
    const owner = identityKeyFromSubject('user-a');
    const granted = await app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/trial',
      headers: headers(),
      payload: {},
    });
    expect(granted.json().data.granted).toBe(true);
    const repeat = await app.inject({
      method: 'POST',
      url: '/v1/reading-entitlements/trial',
      headers: headers(),
      payload: {},
    });
    expect(repeat.json().data.reason).toBe('already');
    expect((await entitlements.balance(owner)).coffee).toBe(1);
    const capped = new ReadingEntitlementLedger(new MemoryDocumentStore());
    expect(await capped.grantTrial({ ownerUserId: 'one', atMs: NOW, dailyCap: 1 })).toBe('granted');
    expect(await capped.grantTrial({ ownerUserId: 'two', atMs: NOW, dailyCap: 1 })).toBe('capped');
  });

  it('an already waiting palm can still be accelerated with gems', async () => {
    const { operations, gems } = await harness(admitting);
    const owner = identityKeyFromSubject('user-a');
    await gems.credit({ ownerUserId: owner, amount: 15, idempotencyKey: 'old-gems-0001' });
    const created = await operations.create({
      ownerUserId: owner,
      readingType: 'palm',
      sourceRequestId: 'palm-old-wait1',
    });
    const accelerated = await gems.accelerate({
      ownerUserId: owner,
      operationId: created.operationId,
      idempotencyKey: 'old-accel-001',
    });
    expect(accelerated.outcome).toBe('accelerated');
    expect(await gems.balanceOf(owner)).toBe(0);
  });
});

function openV3(
  app: { inject: (opts: { method: string; url: string; headers: Record<string, string>; payload: Record<string, unknown> }) => Promise<{ json: () => { data: { operationId: string } } }> },
  headers: Record<string, string>,
  sourceRequestId: string,
) {
  return app.inject({
    method: 'POST',
    url: '/v1/reading-operations',
    headers,
    payload: {
      readingType: 'coffee',
      sourceRequestId,
      language: 'tr',
      coffeeInputContract: 'trusted_intention_v1',
      intention: INTENTION,
      coffeeCaptureContract: 'three_view_v3',
    },
  }).then((response) => response.json().data.operationId);
}
