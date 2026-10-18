import { describe, expect, it, vi } from 'vitest';
import { getCoffeeRuntime, LiveCoffeeService, MockCoffeeService, type CoffeeFlowPhase } from './service';
import type { CoffeeRecoveryRecord, CoffeeRecoveryStore } from './recovery';

const files = {
  'cup-primary': new File(['a'], 'a.jpg', { type: 'image/jpeg' }),
  'cup-secondary': new File(['b'], 'b.jpg', { type: 'image/jpeg' }),
  saucer: new File(['c'], 'c.jpg', { type: 'image/jpeg' }),
};

describe('MockCoffeeService', () => {
  it('runs preparation, upload, wait, processing and clearly demo-only ready states', async () => {
    const phases: CoffeeFlowPhase[] = [];
    const result = await new MockCoffeeService('success', 0).run({ files, intention: 'Genel olarak', onUpdate: (update) => phases.push(update.phase) });
    expect(phases).toEqual(['preparing', 'uploading', 'uploading', 'uploading', 'waiting', 'processing', 'delivering', 'ready']);
    expect(result).toMatchObject({ kind: 'demo', delivery: { resultId: 'demo_coffee_result', result: { coffeeResultContract: 'm2_public_v1' } } });
  });
  it('supports a retry after a simulated failure', async () => {
    const service = new MockCoffeeService('fail-once', 0);
    const onUpdate = vi.fn();
    await expect(service.run({ files, intention: 'Genel olarak', onUpdate })).rejects.toThrow('network');
    await expect(service.run({ files, intention: 'Genel olarak', onUpdate })).resolves.toMatchObject({ kind: 'demo' });
  });
  it('never enables the mock provider in production', () => {
    vi.stubEnv('NODE_ENV', 'production');
    vi.stubEnv('NEXT_PUBLIC_ORACLY_COFFEE_SERVICE', 'mock');
    expect(getCoffeeRuntime().mode).not.toBe('mock');
    vi.unstubAllEnvs();
  });
});

class MemoryRecovery implements CoffeeRecoveryStore {
  constructor(public value: CoffeeRecoveryRecord | null = null) {}
  load() { return this.value; }
  save(value: CoffeeRecoveryRecord) { this.value = value; }
  clear() { this.value = null; }
}

const ok = (data: unknown) => new Response(JSON.stringify({ success: true, data }), { status: 200, headers: { 'Content-Type': 'application/json' } });
const missing = () => new Response(JSON.stringify({ success: false, error: { code: 'invalid_request' } }), { status: 404, headers: { 'Content-Type': 'application/json' } });
const publicResult = (operationId = 'op-1') => ({ operationId, resultId: 'result-1', readingType: 'coffee', persistedAt: '2026-10-18T12:00:00.000Z', result: { coffeeResultContract: 'm2_public_v1', visualObservation: '', overall: 'Gerçek sözleşmeden gelen paragraf.', love: '', career: '', money: '', nearFuture: '', takeaway: '', symbols: [] } });

describe('LiveCoffeeService result delivery', () => {
  it('retries only the same result endpoint when a ready result is briefly unreadable', async () => {
    const calls: Array<{ url: string; method: string }> = [];
    let resultAttempts = 0;
    const fetchImpl = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = String(input); const method = init?.method ?? 'GET'; calls.push({ url, method });
      if (url.endsWith('/v1/web/coffee-orders/order-1234/reading-operation') && method === 'POST') return ok({ operationId: 'op-1' });
      if (url.endsWith('/staged-image')) return ok({});
      if (url.endsWith('/result')) return ++resultAttempts < 3 ? missing() : ok(publicResult());
      return ok({ operationId: 'op-1', status: 'ready', remainingMs: 0, resultReady: true, resultId: 'result-1' });
    });
    const service = new LiveCoffeeService('https://api.example.test', { fetchImpl: fetchImpl as typeof fetch, getTokens: async () => ({ authToken: 'auth', appCheckToken: 'app' }), recovery: new MemoryRecovery(), sleep: async () => {}, resultAttempts: 3 });
    await expect(service.run({ files, intention: 'Genel olarak', orderId: 'order-1234', onUpdate: vi.fn() })).resolves.toMatchObject({ kind: 'live', delivery: { resultId: 'result-1' } });
    expect(calls.filter((call) => call.url.endsWith('/v1/web/coffee-orders/order-1234/reading-operation') && call.method === 'POST')).toHaveLength(1);
    expect(calls.filter((call) => call.url.endsWith('/result'))).toHaveLength(3);
  });

  it('resumes the recorded operation without creating or uploading again', async () => {
    const recovery = new MemoryRecovery({ version: 1, sourceRequestId: 'web_coffee_v3_existing', operationId: 'op-1', stagedSlots: ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'], createdAtMs: Date.now() });
    const fetchImpl = vi.fn(async (input: RequestInfo | URL) => String(input).endsWith('/result') ? ok(publicResult()) : ok({ operationId: 'op-1', status: 'ready', remainingMs: 0, resultReady: true, resultId: 'result-1' }));
    const service = new LiveCoffeeService('https://api.example.test', { fetchImpl: fetchImpl as typeof fetch, getTokens: async () => ({ authToken: 'auth', appCheckToken: 'app' }), recovery, sleep: async () => {} });
    await service.run({ files, intention: 'Genel olarak', orderId: 'order-1234', onUpdate: vi.fn() });
    expect(fetchImpl).toHaveBeenCalledTimes(2);
    expect(recovery.value).toBeNull();
  });

  it('does not create another operation after repeated ownership-safe 404 responses', async () => {
    const recovery = new MemoryRecovery({ version: 1, sourceRequestId: 'web_coffee_v3_existing', operationId: 'op-1', stagedSlots: ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'], createdAtMs: Date.now() });
    const fetchImpl = vi.fn(async (input: RequestInfo | URL) => String(input).endsWith('/result') ? missing() : ok({ operationId: 'op-1', status: 'ready', remainingMs: 0, resultReady: true, resultId: 'result-1' }));
    const service = new LiveCoffeeService('https://api.example.test', { fetchImpl: fetchImpl as typeof fetch, getTokens: async () => ({ authToken: 'auth', appCheckToken: 'app' }), recovery, sleep: async () => {}, resultAttempts: 2 });
    await expect(service.run({ files, intention: 'Genel olarak', orderId: 'order-1234', onUpdate: vi.fn() })).rejects.toThrow('invalid_request');
    expect(fetchImpl.mock.calls.map(([input]) => String(input))).not.toContain('https://api.example.test/v1/reading-operations');
    expect(recovery.value?.operationId).toBe('op-1');
  });
});
