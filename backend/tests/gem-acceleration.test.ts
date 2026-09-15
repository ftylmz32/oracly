import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { GemLedger, priceTokenFor } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { COFFEE_V2_SLOTS, type CoffeeV2Slot } from '../src/reading/operation-staged-image-model.js';
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

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

function world() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-09-08T00:00:00.000Z'));
  const costs = provisionalGemCostPolicy({ coffee: 10, palm: 15, soulmate: 20 });
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(
    repository,
    clock,
    provisionalWaitPolicy({ coffee: 60_000, palm: 120_000, soulmate: 180_000 }),
  );
  const ledger = new GemLedger(store, clock, costs);
  return { store, clock, costs, operations, ledger };
}

function spendCount(store: MemoryDocumentStore): number {
  return [...store.docs.values()].filter((doc) => doc.type === 'spend').length;
}

async function seeded(balance = 40, readingType: 'coffee' | 'palm' = 'coffee') {
  const setup = world();
  const owner = identityKeyFromSubject('user-a');
  await setup.ledger.credit({
    ownerUserId: owner,
    amount: balance,
    idempotencyKey: 'seed-credit1',
  });
  const created = await setup.operations.create({
    ownerUserId: owner,
    readingType,
    sourceRequestId: `${readingType}-src-01`,
  });
  return { ...setup, owner, created };
}

async function stageInput(
  setup: Awaited<ReturnType<typeof seeded>>,
  readingType: 'coffee' | 'palm',
  slot?: CoffeeV2Slot,
) {
  const staged = new FirestoreReadingStagedImageRepository(setup.store);
  await staged.upsert({
    schemaVersion: 1,
    operationId: setup.created.operationId,
    ownerUserId: setup.owner,
    readingType,
    objectPath: `reading-staging/${readingType}/${setup.created.operationId}/${slot ?? 'input'}.jpg`,
    contentType: 'image/jpeg',
    byteSize: 1024,
    checksumSha256: 'a'.repeat(64),
    uploadState: 'complete',
    ...(slot ? { slot } : {}),
    createdAtMs: setup.clock.ms,
    updatedAtMs: setup.clock.ms,
  });
  return staged;
}

async function accelerationApp(setup: Awaited<ReturnType<typeof seeded>>) {
  return testApp(
    testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
    async () => { throw new Error('must not call AI'); },
    {
      appCheck: new StaticAppCheckVerifier('good-token'),
      readingOperationRepository: new FirestoreReadingOperationRepository(setup.store),
      readingStagedImageRepository: new FirestoreReadingStagedImageRepository(setup.store),
      readingClock: setup.clock,
      gemLedger: setup.ledger,
    },
  );
}

function accelerationHeaders() {
  return {
    ...authHeader(signHs256(SECRET, { sub: 'user-a' })),
    ...appCheckHeader('good-token'),
  };
}

describe('gem acceleration ledger', () => {
  it('allows complete Coffee V2 slots through precharge and debits once', async () => {
    const setup = await seeded(95);
    for (const slot of COFFEE_V2_SLOTS) await stageInput(setup, 'coffee', slot);
    const app = await accelerationApp(setup);
    const request = () => app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
      headers: accelerationHeaders(),
      payload: { idempotencyKey: 'coffee-v2-valid-01' },
    });
    const first = await request();
    const duplicate = await request();
    expect(first.statusCode).toBe(200);
    expect(first.json().data.canonicalCost).toBe(10);
    expect(first.json().data.balance).toBe(85);
    expect(duplicate.statusCode).toBe(200);
    expect(duplicate.json().data.idempotent).toBe(true);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(85);
    expect(spendCount(setup.store)).toBe(1);
    await app.close();
  });

  for (const missing of COFFEE_V2_SLOTS) {
    it(`fails closed when Coffee V2 is missing ${missing}`, async () => {
      const setup = await seeded(95);
      for (const slot of COFFEE_V2_SLOTS) {
        if (slot !== missing) await stageInput(setup, 'coffee', slot);
      }
      const app = await accelerationApp(setup);
      const response = await app.inject({
        method: 'POST',
        url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
        headers: accelerationHeaders(),
        payload: { idempotencyKey: `missing-${missing}` },
      });
      expect(response.statusCode).toBe(409);
      expect(await setup.ledger.balanceOf(setup.owner)).toBe(95);
      expect(spendCount(setup.store)).toBe(0);
      await app.close();
    });
  }

  it('preserves legacy Coffee staged input acceleration', async () => {
    const setup = await seeded(40);
    await stageInput(setup, 'coffee');
    const app = await accelerationApp(setup);
    const response = await app.inject({
      method: 'POST', url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
      headers: accelerationHeaders(), payload: { idempotencyKey: 'legacy-coffee-01' },
    });
    expect(response.statusCode).toBe(200);
    expect(response.json().data.balance).toBe(30);
    await app.close();
  });

  it('preserves Palm staged input acceleration and canonical cost', async () => {
    const setup = await seeded(40, 'palm');
    await stageInput(setup, 'palm');
    const app = await accelerationApp(setup);
    const response = await app.inject({
      method: 'POST', url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
      headers: accelerationHeaders(), payload: { idempotencyKey: 'legacy-palm-0001' },
    });
    expect(response.statusCode).toBe(200);
    expect(response.json().data.canonicalCost).toBe(15);
    expect(response.json().data.balance).toBe(25);
    await app.close();
  });

  it('returns typed insufficient_gems for valid V2 input without debiting', async () => {
    const setup = await seeded(5);
    for (const slot of COFFEE_V2_SLOTS) await stageInput(setup, 'coffee', slot);
    const app = await accelerationApp(setup);
    const response = await app.inject({
      method: 'POST', url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
      headers: accelerationHeaders(), payload: { idempotencyKey: 'coffee-v2-poor-01' },
    });
    expect(response.statusCode).toBe(409);
    expect(response.json().error.code).toBe('insufficient_gems');
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(5);
    expect(spendCount(setup.store)).toBe(0);
    await app.close();
  });

  it('never debits Coffee/Palm when durable staged input is missing', async () => {
    const setup = await seeded();
    const app = await testApp(
      testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
      async () => { throw new Error('must not call AI'); },
      {
        appCheck: new StaticAppCheckVerifier('good-token'),
        readingOperationRepository: new FirestoreReadingOperationRepository(setup.store),
        readingStagedImageRepository: new FirestoreReadingStagedImageRepository(setup.store),
        gemLedger: setup.ledger,
      },
    );
    const res = await app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
      headers: {
        ...authHeader(signHs256(SECRET, { sub: 'user-a' })),
        ...appCheckHeader('good-token'),
      },
      payload: { idempotencyKey: 'missing-stage-01' },
    });
    expect(res.statusCode).toBe(409);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(40);
    expect(spendCount(setup.store)).toBe(0);
    await app.close();
  });

  it('debits the canonical cost once and rejects a client amount', async () => {
    const { ledger, operations, owner, created, costs } = await seeded();
    const cost = costs.cost('coffee');
    const result = await ledger.accelerate({
      ownerUserId: owner,
      operationId: created.operationId,
      idempotencyKey: 'accel-key-01',
    });
    expect(result.outcome).toBe('accelerated');
    expect(result.balance).toBe(40 - cost);
    expect(result.canonicalCost).toBe(cost);
    const op = await operations.get(owner, created.operationId);
    expect(op.status).toBe('processing');
    expect(op.gemDebitId).toBeTruthy();
    expect(op.acceleratedAtMs).toBeTruthy();
    expect(op.readyAtMs).toBe(created.readyAtMs);
  });

  it('does not debit or transition when balance is insufficient', async () => {
    const setup = world();
    const owner = identityKeyFromSubject('user-a');
    const created = await setup.operations.create({
      ownerUserId: owner,
      readingType: 'soulmate',
      sourceRequestId: 'soul-src-001',
    });
    await expect(
      setup.ledger.accelerate({
        ownerUserId: owner,
        operationId: created.operationId,
        idempotencyKey: 'accel-poor-01',
      }),
    ).rejects.toMatchObject({ code: 'insufficient_gems' });
    expect(await setup.ledger.balanceOf(owner)).toBe(0);
    expect((await setup.operations.get(owner, created.operationId)).status).toBe('waiting');
    expect(spendCount(setup.store)).toBe(0);
  });

  it('charges once for five concurrent requests and a lost-response retry', async () => {
    const { ledger, owner, created, store } = await seeded();
    const results = await Promise.all(
      Array.from({ length: 5 }, () =>
        ledger.accelerate({
          ownerUserId: owner,
          operationId: created.operationId,
          idempotencyKey: 'accel-key-01',
        }),
      ),
    );
    expect(results.every((item) => item.outcome === 'accelerated' && item.balance === 30)).toBe(true);
    expect(new Set(results.map((item) => item.operation.gemDebitId)).size).toBe(1);
    expect(spendCount(store)).toBe(1);
    expect(await ledger.balanceOf(owner)).toBe(30);
    const retry = await ledger.accelerate({
      ownerUserId: owner,
      operationId: created.operationId,
      idempotencyKey: 'accel-key-01',
    });
    expect(retry.idempotent).toBe(true);
    expect(retry.balance).toBe(30);
    const secondKey = await ledger.accelerate({
      ownerUserId: owner,
      operationId: created.operationId,
      idempotencyKey: 'accel-key-02',
    });
    expect(secondKey.outcome).toBe('already_accelerated');
    expect(secondKey.balance).toBe(30);
    expect(spendCount(store)).toBe(1);
  });

  it('does not charge a ready result and does not permanently charge a ready race', async () => {
    const readyFirst = await seeded();
    await readyFirst.operations.attachResult({
      ownerUserId: readyFirst.owner,
      operationId: readyFirst.created.operationId,
      resultId: 'result-id-1',
    });
    const skipped = await readyFirst.ledger.accelerate({
      ownerUserId: readyFirst.owner,
      operationId: readyFirst.created.operationId,
      idempotencyKey: 'accel-ready-1',
    });
    expect(skipped.outcome).toBe('already_ready');
    expect(skipped.balance).toBe(40);
    expect(spendCount(readyFirst.store)).toBe(0);

    const raced = await seeded(40);
    const cost = raced.costs.cost('coffee');
    const [accel, attached] = await Promise.all([
      raced.ledger.accelerate({
        ownerUserId: raced.owner,
        operationId: raced.created.operationId,
        idempotencyKey: 'race-key-001',
      }),
      raced.operations.attachResult({
        ownerUserId: raced.owner,
        operationId: raced.created.operationId,
        resultId: 'result-id-9',
      }),
    ]);
    const after = await raced.ledger.balanceOf(raced.owner);
    const op = await raced.operations.get(raced.owner, raced.created.operationId);
    expect(spendCount(raced.store)).toBeLessThanOrEqual(1);
    if (accel.outcome === 'already_ready') {
      expect(after).toBe(40);
      expect(op.gemDebitId).toBeNull();
    } else {
      expect(after).toBe(40 - cost);
      expect(op.gemDebitId).toBeTruthy();
    }
    expect(attached.status === 'ready' || op.status === 'ready' || op.status === 'processing').toBe(true);
    if (op.status === 'ready' && op.gemDebitId == null) {
      expect(after).toBe(40);
    }
  });

  it('refunds an accelerated failure once and refuses refund after success', async () => {
    const { ledger, operations, owner, created, store } = await seeded();
    const spent = await ledger.accelerate({
      ownerUserId: owner,
      operationId: created.operationId,
      idempotencyKey: 'accel-key-01',
    });
    const refunded = await ledger.refundFailedAcceleration({
      ownerUserId: owner,
      operationId: created.operationId,
    });
    expect(refunded.balance).toBe(40);
    expect(refunded.spendTransactionId).toBe(spent.operation.gemDebitId);
    const again = await ledger.refundFailedAcceleration({
      ownerUserId: owner,
      operationId: created.operationId,
    });
    expect(again.idempotent).toBe(true);
    expect(again.refundTransactionId).toBe(refunded.refundTransactionId);
    expect(await ledger.balanceOf(owner)).toBe(40);
    const traced = await ledger.trace(owner, created.operationId);
    expect(traced.spend?.transactionId).toBe(refunded.spendTransactionId);
    expect(traced.refund?.relatedTransactionId).toBe(traced.spend?.transactionId);
    expect(traced.refund?.amount).toBe(spent.canonicalCost);
    expect([...store.docs.values()].filter((doc) => doc.type === 'refund')).toHaveLength(1);
    expect((await operations.get(owner, created.operationId)).status).toBe('failed');

    const success = await seeded();
    await success.ledger.accelerate({
      ownerUserId: success.owner,
      operationId: success.created.operationId,
      idempotencyKey: 'accel-ok-0001',
    });
    await success.operations.attachResult({
      ownerUserId: success.owner,
      operationId: success.created.operationId,
      resultId: 'result-id-1',
    });
    await expect(
      success.ledger.refundFailedAcceleration({
        ownerUserId: success.owner,
        operationId: success.created.operationId,
      }),
    ).rejects.toMatchObject({ code: 'conflict' });
    expect(await success.ledger.balanceOf(success.owner)).toBe(30);
  });

  it('keeps ledger truth after repository reconstruction and scopes keys to the owner', async () => {
    const setup = await seeded();
    await setup.ledger.accelerate({
      ownerUserId: setup.owner,
      operationId: setup.created.operationId,
      idempotencyKey: 'shared-key01',
    });
    const rebuilt = new GemLedger(setup.store, setup.clock, setup.costs);
    expect(await rebuilt.balanceOf(setup.owner)).toBe(30);
    const other = identityKeyFromSubject('user-b');
    await expect(
      rebuilt.accelerate({
        ownerUserId: other,
        operationId: setup.created.operationId,
        idempotencyKey: 'shared-key01',
      }),
    ).rejects.toMatchObject({ code: 'not_found' });
    await rebuilt.credit({
      ownerUserId: other,
      amount: 40,
      idempotencyKey: 'seed-user-b-01',
    });
    const own = await setup.operations.create({
      ownerUserId: other,
      readingType: 'palm',
      sourceRequestId: 'palm-src-0001',
    });
    const charged = await rebuilt.accelerate({
      ownerUserId: other,
      operationId: own.operationId,
      idempotencyKey: 'shared-key01',
    });
    expect(charged.outcome).toBe('accelerated');
    expect(charged.canonicalCost).toBe(15);
    expect(await rebuilt.balanceOf(setup.owner)).toBe(30);
    expect(await rebuilt.balanceOf(other)).toBe(25);
  });

  it('quotes the exact same cost accelerate() would charge, without debiting', async () => {
    const { ledger, owner, created, costs, store } = await seeded();
    const before = spendCount(store);
    const quote = await ledger.quoteAcceleration({
      ownerUserId: owner,
      operationId: created.operationId,
    });
    expect(quote).toEqual({
      cost: costs.cost('coffee'),
      balance: 40,
      priceToken: priceTokenFor(created.operationId, costs.cost('coffee')),
      payable: true,
    });
    // Read-only: repeated quoting never touches the ledger.
    expect(await ledger.quoteAcceleration({ ownerUserId: owner, operationId: created.operationId })).toEqual(quote);
    expect(spendCount(store)).toBe(before);
    expect(await ledger.balanceOf(owner)).toBe(40);

    // The quote must match what a real accelerate() charges for the SAME
    // operation -- proving it is not a separate, driftable number.
    const result = await ledger.accelerate({
      ownerUserId: owner,
      operationId: created.operationId,
      idempotencyKey: 'quote-then-accelerate-01',
    });
    expect(result.canonicalCost).toBe(quote!.cost);
    expect(result.balance).toBe(40 - quote!.cost);
  });

  it('quote reflects a server-side cost change; the client cannot set it', async () => {
    const owner = identityKeyFromSubject('user-cost-change');
    const store = new MemoryDocumentStore();
    const clock = new FixedClock(Date.parse('2026-09-08T00:00:00.000Z'));
    const repository = new FirestoreReadingOperationRepository(store);
    const operations = new ReadingOperationService(
      repository,
      clock,
      provisionalWaitPolicy({ coffee: 60_000, palm: 120_000, soulmate: 180_000 }),
    );
    const cheapLedger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 10 }));
    const created = await operations.create({
      ownerUserId: owner,
      readingType: 'coffee',
      sourceRequestId: 'coffee-cost-change',
    });
    const cheapQuote = await cheapLedger.quoteAcceleration({ ownerUserId: owner, operationId: created.operationId });
    expect(cheapQuote?.cost).toBe(10);

    // Same operation, same server, but the deployed cost policy changed --
    // the SAME operation must now quote the new authoritative price.
    const pricierLedger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 25 }));
    const pricierQuote = await pricierLedger.quoteAcceleration({ ownerUserId: owner, operationId: created.operationId });
    expect(pricierQuote?.cost).toBe(25);
  });

  it('a price change between quote and tap blocks the charge; a fresh tap then succeeds once; duplicates stay idempotent', async () => {
    const owner = identityKeyFromSubject('user-price-race');
    const store = new MemoryDocumentStore();
    const clock = new FixedClock(Date.parse('2026-09-08T00:00:00.000Z'));
    const repository = new FirestoreReadingOperationRepository(store);
    const operations = new ReadingOperationService(
      repository,
      clock,
      provisionalWaitPolicy({ coffee: 60_000, palm: 120_000, soulmate: 180_000 }),
    );
    const cheapLedger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 10 }));
    await cheapLedger.credit({ ownerUserId: owner, amount: 40, idempotencyKey: 'seed-price-race' });
    const created = await operations.create({
      ownerUserId: owner,
      readingType: 'coffee',
      sourceRequestId: 'coffee-price-race',
    });

    // quote 10 -> charge 10 succeeds (baseline, same ledger/policy throughout).
    const baselineTap = await cheapLedger.accelerate({
      ownerUserId: owner,
      operationId: created.operationId,
      idempotencyKey: 'price-race-baseline',
      expectedPriceToken: (await cheapLedger.quoteAcceleration({ ownerUserId: owner, operationId: created.operationId }))!.priceToken,
    });
    expect(baselineTap.outcome).toBe('accelerated');
    expect(baselineTap.canonicalCost).toBe(10);
    expect(spendCount(store)).toBe(1);

    // A second, independent operation for the price-changed race itself.
    const raced = await operations.create({
      ownerUserId: owner,
      readingType: 'coffee',
      sourceRequestId: 'coffee-price-race-2',
    });
    const quote = await cheapLedger.quoteAcceleration({ ownerUserId: owner, operationId: raced.operationId });
    expect(quote?.cost).toBe(10);
    const balanceAfterBaseline = await cheapLedger.balanceOf(owner);

    // The deployed policy changes to 15 after the user saw the quote but
    // before they tapped -- simulated here as a second ledger over the same
    // durable store, exactly like the earlier cost-change test.
    const pricierLedger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 15 }));

    const firstTap = await pricierLedger.accelerate({
      ownerUserId: owner,
      operationId: raced.operationId,
      idempotencyKey: 'price-race-tap',
      expectedPriceToken: quote!.priceToken,
    });
    expect(firstTap.outcome).toBe('price_changed');
    expect(firstTap.canonicalCost).toBe(15);
    expect(firstTap.idempotent).toBe(false);
    // Zero debit -- balance and spend count are untouched by the rejection.
    expect(await pricierLedger.balanceOf(owner)).toBe(balanceAfterBaseline);
    expect(spendCount(store)).toBe(1);
    expect((await operations.get(owner, raced.operationId)).status).toBe('waiting');

    // UI updates to 15 -- the caller now has the fresh cost/token with no
    // extra round trip, straight from the rejected response.
    expect(firstTap.priceToken).not.toBe(quote!.priceToken);

    // A second, explicit tap (same idempotencyKey -- the first tap never
    // wrote a key doc, so this is not a collision) with the FRESH token
    // charges 15 exactly once.
    const secondTap = await pricierLedger.accelerate({
      ownerUserId: owner,
      operationId: raced.operationId,
      idempotencyKey: 'price-race-tap',
      expectedPriceToken: firstTap.priceToken,
    });
    expect(secondTap.outcome).toBe('accelerated');
    expect(secondTap.idempotent).toBe(false);
    expect(secondTap.canonicalCost).toBe(15);
    expect(secondTap.balance).toBe(balanceAfterBaseline - 15);
    expect(spendCount(store)).toBe(2);

    // A duplicate tap (e.g. a retried request) with the same idempotencyKey
    // remains idempotent -- no new ledger entry, same balance.
    const duplicate = await pricierLedger.accelerate({
      ownerUserId: owner,
      operationId: raced.operationId,
      idempotencyKey: 'price-race-tap',
      expectedPriceToken: firstTap.priceToken,
    });
    expect(duplicate.outcome).toBe('accelerated');
    expect(duplicate.idempotent).toBe(true);
    expect(duplicate.balance).toBe(balanceAfterBaseline - 15);
    expect(spendCount(store)).toBe(2);
  });

  it('POST accelerate with a stale expectedPriceToken never charges, over HTTP', async () => {
    const setup = await seeded();
    const staleToken = priceTokenFor(setup.created.operationId, setup.costs.cost('coffee'));
    const pricier = new GemLedger(setup.store, setup.clock, provisionalGemCostPolicy({ coffee: 99 }));
    const app = await testApp(
      testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
      async () => { throw new Error('must not call AI'); },
      {
        appCheck: new StaticAppCheckVerifier('good-token'),
        readingOperationRepository: new FirestoreReadingOperationRepository(setup.store),
        readingClock: setup.clock,
        gemLedger: pricier,
      },
    );
    const headers = {
      ...authHeader(signHs256(SECRET, { sub: 'user-a' })),
      ...appCheckHeader('good-token'),
    };
    const res = await app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
      headers,
      payload: { idempotencyKey: 'http-price-race', expectedPriceToken: staleToken },
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().data.outcome).toBe('price_changed');
    expect(res.json().data.canonicalCost).toBe(99);
    expect(await pricier.balanceOf(setup.owner)).toBe(40);
    await app.close();
  });

  it('GET quote never accepts a client-supplied cost and cannot see another owner\'s operation', async () => {
    const setup = await seeded();
    const app = await testApp(
      testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
      async () => { throw new Error('must not call AI'); },
      {
        appCheck: new StaticAppCheckVerifier('good-token'),
        readingOperationRepository: new FirestoreReadingOperationRepository(setup.store),
        readingClock: setup.clock,
        gemLedger: setup.ledger,
      },
    );
    const headers = {
      ...authHeader(signHs256(SECRET, { sub: 'user-a' })),
      ...appCheckHeader('good-token'),
    };
    const quoted = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
      headers,
    });
    expect(quoted.statusCode).toBe(200);
    expect(quoted.json().data).toEqual({
      canonicalCost: setup.costs.cost('coffee'),
      balance: 40,
      priceToken: priceTokenFor(setup.created.operationId, setup.costs.cost('coffee')),
      payable: true,
    });
    // A GET carries no body at all -- there is no channel for a client to
    // propose its own amount, unlike the POST which explicitly rejects one.
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(40);

    const foreign = await app.inject({
      method: 'GET',
      url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
      headers: {
        ...authHeader(signHs256(SECRET, { sub: 'user-b' })),
        ...appCheckHeader('good-token'),
      },
    });
    expect(foreign.statusCode).toBe(404);
    await app.close();
  });

  it('never charges once the free wait is already over -- zero debit, no ledger write, operation left exactly as-is', async () => {
    const setup = await seeded();
    // Advance past coffee's 60s free wait -- the user has already waited
    // it out; Cloud Tasks/claim latency from here on is infrastructure
    // delay, not remaining wait time.
    setup.clock.ms = setup.created.readyAtMs;
    const result = await setup.ledger.accelerate({
      ownerUserId: setup.owner,
      operationId: setup.created.operationId,
      idempotencyKey: 'post-readyat-01',
    });
    expect(result.outcome).toBe('already_eligible');
    expect(result.balance).toBe(40);
    expect(result.idempotent).toBe(false);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(40);
    expect(spendCount(setup.store)).toBe(0);
    const op = await setup.operations.get(setup.owner, setup.created.operationId);
    expect(op.status).toBe('waiting');
    expect(op.gemDebitId).toBeNull();
    expect(op.acceleratedAtMs).toBeNull();
  });

  it('boundary race: readyAtMs === now still refuses to charge (>= is inclusive, never charges on the exact boundary)', async () => {
    const setup = await seeded();
    setup.clock.ms = setup.created.readyAtMs; // exactly equal, not past
    const result = await setup.ledger.accelerate({
      ownerUserId: setup.owner,
      operationId: setup.created.operationId,
      idempotencyKey: 'boundary-exact-01',
    });
    expect(result.outcome).toBe('already_eligible');
    expect(spendCount(setup.store)).toBe(0);
  });

  it('one tick before readyAt still charges normally -- the boundary fix never blocks a legitimate early acceleration', async () => {
    const setup = await seeded();
    setup.clock.ms = setup.created.readyAtMs - 1;
    const result = await setup.ledger.accelerate({
      ownerUserId: setup.owner,
      operationId: setup.created.operationId,
      idempotencyKey: 'boundary-before-01',
    });
    expect(result.outcome).toBe('accelerated');
    expect(result.balance).toBe(40 - setup.costs.cost('coffee'));
    expect(spendCount(setup.store)).toBe(1);
  });

  it('a duplicate post-readyAt tap (same idempotencyKey) never writes a key doc and never debits either time', async () => {
    const setup = await seeded();
    setup.clock.ms = setup.created.readyAtMs + 5_000;
    const first = await setup.ledger.accelerate({
      ownerUserId: setup.owner,
      operationId: setup.created.operationId,
      idempotencyKey: 'post-readyat-dup-01',
    });
    const second = await setup.ledger.accelerate({
      ownerUserId: setup.owner,
      operationId: setup.created.operationId,
      idempotencyKey: 'post-readyat-dup-01',
    });
    expect(first.outcome).toBe('already_eligible');
    expect(second.outcome).toBe('already_eligible');
    expect(spendCount(setup.store)).toBe(0);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(40);
  });

  it('an already-eligible operation still proceeds to durable processing for free -- accelerate() never blocks or duplicates the normal claim', async () => {
    const setup = await seeded();
    setup.clock.ms = setup.created.readyAtMs + 1_000;
    await setup.ledger.accelerate({
      ownerUserId: setup.owner,
      operationId: setup.created.operationId,
      idempotencyKey: 'post-readyat-claim-01',
    });
    // The normal (free) claim path is completely untouched by the rejected
    // acceleration attempt -- same operation, no second op created.
    const before = setup.operations.get(setup.owner, setup.created.operationId);
    expect((await before).operationId).toBe(setup.created.operationId);
  });

  it('a quote fetched after readyAt reports payable:false -- never an actionable paid quote once the wait is over', async () => {
    const setup = await seeded();
    setup.clock.ms = setup.created.readyAtMs;
    const quote = await setup.ledger.quoteAcceleration({
      ownerUserId: setup.owner,
      operationId: setup.created.operationId,
    });
    expect(quote?.payable).toBe(false);
    // The cost/priceToken are still reported (transparency), but the flag
    // is what a client must gate the paid CTA on -- and the real authority
    // (accelerate() itself) refuses to charge regardless of what any client
    // does with this flag.
    expect(quote?.cost).toBe(setup.costs.cost('coffee'));
  });

  it('rejects malformed keys, client amounts, premium spoof, and refund calls', async () => {
    const setup = await seeded();
    await expect(
      setup.ledger.accelerate({
        ownerUserId: setup.owner,
        operationId: setup.created.operationId,
        idempotencyKey: 'short',
      }),
    ).rejects.toMatchObject({ code: 'invalid' });
    const app = await testApp(
      testConfig({
        AI_JWT_SECRET: SECRET,
        AI_APP_CHECK_REQUIRED: 'true',
      }),
      async () => {
        throw new Error('must not call AI');
      },
      {
        appCheck: new StaticAppCheckVerifier('good-token'),
        readingOperationRepository: new FirestoreReadingOperationRepository(setup.store),
        readingClock: setup.clock,
        gemLedger: setup.ledger,
      },
    );
    const headers = {
      ...authHeader(signHs256(SECRET, { sub: 'user-a' })),
      ...appCheckHeader('good-token'),
    };
    const priced = await app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
      headers,
      payload: { idempotencyKey: 'accel-key-99', amount: 1, premium: true },
    });
    expect(priced.statusCode).toBe(400);
    const denied = await app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${setup.created.operationId}/refund`,
      headers,
      payload: { amount: 10 },
    });
    expect(denied.statusCode).toBe(404);
    const other = await app.inject({
      method: 'POST',
      url: `/v1/reading-operations/${setup.created.operationId}/accelerate`,
      headers: {
        ...authHeader(signHs256(SECRET, { sub: 'user-b' })),
        ...appCheckHeader('good-token'),
      },
      payload: { idempotencyKey: 'accel-key-77' },
    });
    expect(other.statusCode).toBe(404);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(40);
    await app.close();
  });
});

describe('purpose-specific server wallet routes', () => {
  async function walletApp() {
    const setup = world();
    const app = await testApp(
      testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
      async () => { throw new Error('must not call AI'); },
      {
        appCheck: new StaticAppCheckVerifier('good-token'),
        readingClock: setup.clock,
        gemLedger: setup.ledger,
      },
    );
    const headers = {
      ...authHeader(signHs256(SECRET, { sub: 'user-a' })),
      ...appCheckHeader('good-token'),
    };
    return { ...setup, app, headers, owner: identityKeyFromSubject('user-a') };
  }

  it('grants starter once across replay and concurrent requests', async () => {
    const setup = await walletApp();
    const request = () => setup.app.inject({
      method: 'POST', url: '/v1/gems/starter-grant', headers: setup.headers,
      payload: { idempotencyKey: 'starter-client-01' },
    });
    const [a, b] = await Promise.all([request(), request()]);
    expect(a.statusCode).toBe(200);
    expect(b.statusCode).toBe(200);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(20);
    expect((await request()).json().data.idempotent).toBe(true);
    await setup.app.close();
  });

  it('uses server day and grants daily reward once', async () => {
    const setup = await walletApp();
    const claim = (key: string) => setup.app.inject({
      method: 'POST', url: '/v1/gems/daily-reward', headers: setup.headers,
      payload: { idempotencyKey: key },
    });
    expect((await claim('daily-client-01')).json().data.serverDay).toBe('2026-09-08');
    expect((await claim('daily-client-02')).json().data.idempotent).toBe(true);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(50);
    await setup.app.close();
  });

  it('settles Tarot once at canonical cost and rejects monetary fields', async () => {
    const setup = await walletApp();
    await setup.ledger.credit({
      ownerUserId: setup.owner, amount: 40, idempotencyKey: 'seed-tarot-01',
    });
    const url = '/v1/gems/tarot/paid-tarot-session-001/settle';
    const first = await setup.app.inject({
      method: 'POST', url, headers: setup.headers,
      payload: { idempotencyKey: 'tarot-client-01' },
    });
    expect(first.json().data.canonicalCost).toBe(20);
    expect(first.json().data.balance).toBe(20);
    const replay = await setup.app.inject({
      method: 'POST', url, headers: setup.headers,
      payload: { idempotencyKey: 'tarot-client-02' },
    });
    expect(replay.json().data.balance).toBe(20);
    expect(replay.json().data.idempotent).toBe(true);
    for (const payload of [
      { idempotencyKey: 'tamper-key-01', amount: 999999 },
      { idempotencyKey: 'tamper-key-02', amount: -1 },
      { idempotencyKey: 'tamper-key-03', ownerUserId: 'other-user' },
      { idempotencyKey: 'short' },
    ]) {
      const denied = await setup.app.inject({ method: 'POST', url, headers: setup.headers, payload });
      expect(denied.statusCode).toBe(400);
    }
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(20);
    await setup.app.close();
  });

  it('requires both authentication and App Check for wallet commands', async () => {
    const setup = await walletApp();
    const noAuth = await setup.app.inject({
      method: 'POST', url: '/v1/gems/starter-grant',
      headers: appCheckHeader('good-token'),
      payload: { idempotencyKey: 'starter-client-02' },
    });
    expect(noAuth.statusCode).toBe(401);
    const noAppCheck = await setup.app.inject({
      method: 'POST', url: '/v1/gems/daily-reward',
      headers: authHeader(signHs256(SECRET, { sub: 'user-a' })),
      payload: { idempotencyKey: 'daily-client-03' },
    });
    expect(noAppCheck.statusCode).toBe(401);
    expect(await setup.ledger.balanceOf(setup.owner)).toBe(0);
    await setup.app.close();
  });
});

