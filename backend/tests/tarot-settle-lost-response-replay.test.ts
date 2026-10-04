// WAVE 1.5 — Tarot settle whose success response never reached the client:
// replaying the SAME operation at zero balance must return the original
// settlement (idempotent, no second debit), while a different reading or a
// different owner is still subject to the insufficient-gems check.
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import { ErrorCode } from '../src/errors.js';
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
  now(): Date {
    return new Date(Date.parse('2026-10-04T00:00:00.000Z'));
  }
}

function spendCount(store: MemoryDocumentStore): number {
  return [...store.docs.values()].filter((doc) => doc.type === 'spend').length;
}

async function walletApp() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock();
  const ledger = new GemLedger(
    store,
    clock,
    provisionalGemCostPolicy({ coffee: 10, palm: 15, soulmate: 20 }),
  );
  const app = await testApp(
    testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
    async () => { throw new Error('must not call AI'); },
    { appCheck: new StaticAppCheckVerifier('good-token'), readingClock: clock, gemLedger: ledger },
  );
  const headersFor = (sub: string) => ({
    ...authHeader(signHs256(SECRET, { sub })),
    ...appCheckHeader('good-token'),
  });
  return { store, ledger, app, headersFor };
}

describe('tarot settle — lost response replay at zero balance', () => {
  it('same operation replays the settlement idempotently with one debit', async () => {
    const setup = await walletApp();
    const owner = identityKeyFromSubject('user-a');
    // Exactly one reading's worth of gems.
    await setup.ledger.credit({ ownerUserId: owner, amount: 20, idempotencyKey: 'seed-wave15-a' });
    const settle = (op: string, sub = 'user-a') => setup.app.inject({
      method: 'POST',
      url: `/v1/gems/tarot/${op}/settle`,
      headers: setup.headersFor(sub),
      payload: { idempotencyKey: 'tarot-settle-request-v1' },
    });

    const first = await settle('tarot_wave15-session-a');
    expect(first.statusCode).toBe(200);
    expect(first.json().data.balance).toBe(0);
    // ... the client never receives `first`.

    const replay = await settle('tarot_wave15-session-a');
    expect(replay.statusCode).toBe(200);
    expect(replay.json().data.settled).toBe(true);
    expect(replay.json().data.idempotent).toBe(true);
    expect(replay.json().data.balance).toBe(0);
    expect(spendCount(setup.store)).toBe(1);
    expect(await setup.ledger.balanceOf(owner)).toBe(0);

    // Guard: a DIFFERENT reading at zero balance is still refused.
    const other = await settle('tarot_wave15-session-b');
    expect(other.statusCode).toBe(409);
    expect(other.json().error.code).toBe(ErrorCode.insufficientGems);
    // Guard: another owner cannot ride on user-a's settlement identity.
    const otherOwner = await settle('tarot_wave15-session-a', 'user-b');
    expect(otherOwner.statusCode).toBe(409);
    expect(otherOwner.json().error.code).toBe(ErrorCode.insufficientGems);
    expect(spendCount(setup.store)).toBe(1);
    await setup.app.close();
  });
});
