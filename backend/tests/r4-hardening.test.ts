import { describe, expect, it } from 'vitest';
import { MemorySharedWindowStore } from '../src/rate-limit/shared-window-store.js';
import type { AccountDeletionRepository, DeletionReceipt } from '../src/account/account-deletion.js';
import { StaticAppCheckVerifier } from '../src/auth/app-check.js';
import { authHeader, appCheckHeader, signHs256, testApp, testConfig, chatBody } from './helpers.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import { FirestoreProviderStageRepository } from '../src/reading/provider-stage-repository.js';
import { FirestoreResponseReplayRepository, RESPONSE_REPLAY_TTL_MS } from '../src/middleware/response-replay-repository.js';
import { jsonResponse } from './helpers.js';

const SECRET = 'r4-hardening-secret';
const headers = {
  ...authHeader(signHs256(SECRET, { sub: 'r4-user' })),
  ...appCheckHeader('r4-app-check'),
};

class DeletionFake implements AccountDeletionRepository {
  calls: string[] = [];
  async deleteForIdentity(identity: string): Promise<DeletionReceipt> {
    this.calls.push(identity);
    return { receiptId: 'r4-receipt', status: 'accepted', completedAt: new Date(0).toISOString(), deletedDocuments: 9, deletedObjects: 3, anonymizedPurchaseBindings: 1 };
  }
}

describe('R4 architecture hardening', () => {
  it('account deletion derives identity from verified auth and returns an idempotent receipt', async () => {
    const repository = new DeletionFake();
    const app = await testApp(testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }), undefined, {
      appCheck: new StaticAppCheckVerifier('r4-app-check'), accountDeletionRepository: repository,
    });
    const first = await app.inject({ method: 'POST', url: '/v1/account/deletion', headers, payload: { uid: 'attacker-choice' } });
    expect(first.statusCode).toBe(202); expect(first.json().data.receiptId).toBe('r4-receipt');
    expect(repository.calls).toHaveLength(1); expect(repository.calls[0]).not.toContain('attacker-choice');
    await app.close();
  });

  it('two independent instances observe the same shared limit window', async () => {
    const shared = new MemorySharedWindowStore();
    const config = testConfig({ AI_JWT_SECRET: SECRET, AI_RATE_LIMIT_MAX: '1', AI_APP_CHECK_REQUIRED: 'true' });
    const options = { appCheck: new StaticAppCheckVerifier('r4-app-check'), sharedWindowStore: shared };
    const a = await testApp(config, undefined, options); const b = await testApp(config, undefined, options);
    expect((await a.inject({ method: 'POST', url: '/v1/ai/complete', headers, payload: chatBody })).statusCode).toBe(200);
    expect((await b.inject({ method: 'POST', url: '/v1/ai/complete', headers, payload: chatBody })).statusCode).toBe(429);
    await a.close(); await b.close();
  });

  for (const language of ['tr', 'en', 'ru'] as const) {
    it(`durably preserves ${language} across repository restart`, async () => {
      const store = new MemoryDocumentStore();
      const repository = new FirestoreReadingOperationRepository(store);
      const service = new ReadingOperationService(repository, { now: () => new Date('2026-09-13T00:00:00Z') }, provisionalWaitPolicy(), () => 'a'.repeat(32));
      await service.create({ ownerUserId: 'owner-r4', readingType: 'coffee', sourceRequestId: `request-${language}-r4`, language });
      const restarted = new ReadingOperationService(new FirestoreReadingOperationRepository(store), { now: () => new Date('2026-09-13T00:01:00Z') }, provisionalWaitPolicy());
      expect((await restarted.get('owner-r4', 'a'.repeat(32))).language).toBe(language);
    });
  }

  it('provider output checkpoint survives a repository restart and reaches persisted', async () => {
    const store = new MemoryDocumentStore(); const first = new FirestoreProviderStageRepository(store);
    await first.markInFlight('operation-r4', 'owner-r4');
    expect((await first.get('operation-r4')).state).toBe('in_flight');
    await first.markCompleted('operation-r4', 'owner-r4', { result: 'durable' });
    const restarted = new FirestoreProviderStageRepository(store);
    expect(await restarted.get('operation-r4')).toEqual({ state: 'provider_completed', output: { result: 'durable' } });
    await restarted.markPersisted('operation-r4');
    expect((await restarted.get('operation-r4')).state).toBe('persisted');
  });

  it('shared response replay coordinates two instances and survives restart', async () => {
    const store = new MemoryDocumentStore();
    const replay = new FirestoreResponseReplayRepository(store);
    let providerCalls = 0; let release!: () => void;
    const blocked = new Promise<void>(resolve => { release = resolve; });
    const fetchImpl = async () => { providerCalls++; await blocked; return jsonResponse({ choices: [{ message: { content: 'same safe response' } }] }); };
    const config = testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' });
    const options = { appCheck: new StaticAppCheckVerifier('r4-app-check'), responseReplayRepository: replay };
    const a = await testApp(config, fetchImpl, options); const b = await testApp(config, fetchImpl, options);
    const idemHeaders = { ...headers, 'idempotency-key': 'shared-r4b-key' };
    const firstPromise = a.inject({ method: 'POST', url: '/v1/ai/complete', headers: idemHeaders, payload: chatBody });
    await new Promise(resolve => setTimeout(resolve, 5));
    expect((await b.inject({ method: 'POST', url: '/v1/ai/complete', headers: idemHeaders, payload: chatBody })).statusCode).toBe(409);
    release(); const first = await firstPromise; expect(first.statusCode).toBe(200);
    const restarted = await testApp(config, fetchImpl, { ...options, responseReplayRepository: new FirestoreResponseReplayRepository(store) });
    const replayed = await restarted.inject({ method: 'POST', url: '/v1/ai/complete', headers: idemHeaders, payload: chatBody });
    expect(replayed.json()).toEqual(first.json()); expect(providerCalls).toBe(1);
    await a.close(); await b.close(); await restarted.close();
  });

  it('response replay expiry permits a new producer only after TTL', async () => {
    const store = new MemoryDocumentStore(); let now = 1000;
    const repo = new FirestoreResponseReplayRepository(store, () => now);
    const first = await repo.claim('owner', 'key'); expect(first.kind).toBe('producer');
    expect((await repo.claim('owner', 'key')).kind).toBe('in_progress');
    now += RESPONSE_REPLAY_TTL_MS + 1;
    expect((await repo.claim('owner', 'key')).kind).toBe('producer');
  });
});
