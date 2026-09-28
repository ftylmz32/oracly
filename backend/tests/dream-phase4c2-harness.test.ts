import { describe, expect, it } from 'vitest';
import { Phase4cBudgetExceeded } from '../scripts/dream-phase4c/budget-fetch.js';
import { runPhase4c2 } from '../scripts/dream-phase4c2/harness.js';
import {
  buildPhase4c2Matrix, loadPhase4c2Requests, PHASE4C2_CASES, PHASE4C2_MAX_CALLS, rotation,
} from '../scripts/dream-phase4c2/matrix.js';
import { completion, fakeConfig, fakeFetch, frozenRaw, httpError } from './dream-phase4c2-support.js';

const attempts = buildPhase4c2Matrix(loadPhase4c2Requests());
const passBody = frozenRaw('tr-negated-fear');

describe('Phase 4C.2 matrix', () => {
  it('is 9 cases × 3 candidates in the fixed case order', () => {
    expect(attempts).toHaveLength(27);
    expect(PHASE4C2_MAX_CALLS).toBe(27);
    expect([...new Set(attempts.map((a) => a.caseId))]).toEqual([...PHASE4C2_CASES]);
    for (const id of PHASE4C2_CASES) {
      expect(attempts.filter((a) => a.caseId === id).map((a) => a.candidate).sort()).toEqual(['gpt-4o', 'gpt-6-astra', 'gpt-6-sol']);
    }
    expect(attempts.map((a) => a.order)).toEqual(Array.from({ length: 27 }, (_, i) => i + 1));
  });

  it('rotates the candidate order per case', () => {
    const order = (i: number) => attempts.filter((a) => a.caseIndex === i).map((a) => a.candidate);
    expect(order(0)).toEqual(['gpt-4o', 'gpt-6-sol', 'gpt-6-astra']);
    expect(order(1)).toEqual(['gpt-6-sol', 'gpt-6-astra', 'gpt-4o']);
    expect(order(2)).toEqual(['gpt-6-astra', 'gpt-4o', 'gpt-6-sol']);
    expect(order(3)).toEqual(order(0));
    expect(order(8)).toEqual(rotation(2));
  });

  it('carries one semantic payload per case across all models', () => {
    for (const id of PHASE4C2_CASES) {
      const payloads = attempts.filter((a) => a.caseId === id).map((a) => JSON.stringify(a.payload));
      expect(new Set(payloads).size).toBe(1);
    }
    const memory = attempts.find((a) => a.caseId === 'ru-memory')!;
    expect(memory.memorySource).toBe('retriever');
    expect(typeof memory.payload.memorySummary).toBe('string');
  });
});

describe('Phase 4C.2 fake-transport run', () => {
  it('makes exactly 27 calls with the pinned per-model bodies and identical prompts', async () => {
    const fake = fakeFetch((body) => completion(String(body.model), passBody));
    const { records, calls } = await runPhase4c2({ attempts, config: fakeConfig(), fetch: fake.fetch });
    expect(calls).toBe(27);
    expect(fake.sent).toHaveLength(27);
    for (const [i, s] of fake.sent.entries()) {
      const a = attempts[i];
      expect(s.url).toBe('https://api.openai.com/v1/chat/completions');
      expect(s.body.model).toBe(a.candidate);
      expect(s.body.response_format).toEqual({ type: 'json_object' });
      for (const k of ['top_p', 'logprobs', 'top_logprobs']) expect(s.body).not.toHaveProperty(k);
      if (a.candidate === 'gpt-4o') {
        expect(s.body.temperature).toBe(0.6);
        expect(s.body).not.toHaveProperty('reasoning_effort');
      } else {
        expect(s.body.reasoning_effort).toBe('medium');
        expect(s.body).not.toHaveProperty('temperature');
      }
    }
    for (const id of PHASE4C2_CASES) {
      const prompts = fake.sent.filter((_, i) => attempts[i].caseId === id).map((s) => JSON.stringify(s.body.messages));
      expect(new Set(prompts).size).toBe(1);
    }
    expect(records.map((r) => r.attemptId)).toEqual(attempts.map((a) => a.attemptId));
    expect(records.every((r) => r.writerRevision === '4c1' && r.providerCallOccurred)).toBe(true);
  });

  it('refuses a 28th call before the network', async () => {
    const fake = fakeFetch((body) => completion(String(body.model), passBody));
    const extra = [...attempts, { ...attempts[0], attemptId: 'extra', order: 28 }];
    await expect(runPhase4c2({ attempts: extra, config: fakeConfig(), fetch: fake.fetch })).rejects.toBeInstanceOf(
      Phase4cBudgetExceeded,
    );
    expect(fake.sent).toHaveLength(27);
  });

  it.each([
    [400, 'Unsupported parameter: reasoning_effort', 'PARAMETER_ERROR', '400'],
    [403, 'no access', 'TRANSPORT_ERROR', '403'],
    [404, 'The model does not exist', 'TRANSPORT_ERROR', '404'],
    [429, 'rate limited', 'TRANSPORT_ERROR', '429'],
    [503, 'overloaded', 'TRANSPORT_ERROR', '5xx'],
  ])('HTTP %i is one recorded infrastructure call — no retry, no substitution', async (status, msg, final, cls) => {
    const fake = fakeFetch(() => httpError(status, msg));
    const { records, calls } = await runPhase4c2({ attempts: attempts.slice(0, 3), config: fakeConfig(), fetch: fake.fetch });
    expect(calls).toBe(3);
    expect(fake.sent.map((s) => s.body.model)).toEqual(['gpt-4o', 'gpt-6-sol', 'gpt-6-astra']);
    for (const r of records) {
      expect(r).toMatchObject({ backendFinal: final, httpClass: cls, httpStatus: status, providerCallOccurred: true });
      expect(r.clientResult).toBe('NOT_DELIVERED');
      expect(r.estimatedCostUsd).toBeNull();
    }
  });

  it('records a timeout once and moves on', async () => {
    const abort = Object.assign(new Error('aborted'), { name: 'AbortError' });
    const fake = fakeFetch((body, n) => (n === 1 ? Promise.reject(abort) : completion(String(body.model), passBody)));
    const { records, calls } = await runPhase4c2({ attempts: attempts.slice(0, 3), config: fakeConfig(), fetch: fake.fetch });
    expect(calls).toBe(3);
    expect(records[0]).toMatchObject({ backendFinal: 'TRANSPORT_ERROR', httpClass: 'timeout', httpStatus: null });
    expect(records[1].backendFinal).toBe('PASS');
  });

  it('an empty 200 body is a model reject, not a retry', async () => {
    const fake = fakeFetch((body) => completion(String(body.model), null));
    const { records, calls } = await runPhase4c2({ attempts: attempts.slice(0, 1), config: fakeConfig(), fetch: fake.fetch });
    expect(calls).toBe(1);
    expect(records[0]).toMatchObject({ backendFinal: 'REJECT', firstFailure: 'empty_provider_content' });
  });
});
