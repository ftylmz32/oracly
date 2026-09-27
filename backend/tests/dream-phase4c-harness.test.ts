// Dream Phase 4C — the live harness proven against a fake transport before
// any real provider call: hard cap, no retries, raw capture, no secret
// capture, stage recording, repeat grouping, artifact schema.
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { readEnvFileValue } from '../scripts/dream-phase4c/env-file.js';
import { validateAiBody } from '../src/ai/validate-request.js';
import type { OpenAiFetch } from '../src/types.js';
import { PHASE4C_SCHEMA, validatePhase4cArtifact, type Phase4cArtifact } from '../scripts/dream-phase4c/artifact.js';
import { Phase4cBudgetExceeded } from '../scripts/dream-phase4c/budget-fetch.js';
import { runPhase4c } from '../scripts/dream-phase4c/harness.js';
import { buildPhase4cMatrix, loadPhase4cInputs, type Phase4cRun } from '../scripts/dream-phase4c/matrix.js';
import { deployedOpenAiEnv, describeDreamConfig, phase4cConfig } from '../scripts/dream-phase4c/production-config.js';
import { golden, goldenPayload, type DreamGolden } from './dream-phase4b-support.js';
import { jsonResponse } from './helpers.js';

const SECRET = 'sk-phase4c-SECRET-never-stored-0000';
const config = phase4cConfig(SECRET);
const en = golden('en-rich-negated-fear');

function fake(content: string | null, status = 200) {
  const headers: unknown[] = [];
  let calls = 0;
  const fetch: OpenAiFetch = async (_url, init) => {
    calls++;
    headers.push(init?.headers);
    return status === 200
      ? jsonResponse({ model: 'fake-model', usage: { total_tokens: 9 }, choices: [{ finish_reason: 'stop', message: { content } }] })
      : jsonResponse({ error: { message: 'boom' } }, status);
  };
  return { fetch, calls: () => calls, headers };
}

const runFor = (g: DreamGolden, runId = g.id, payload = goldenPayload(g)): Phase4cRun => ({
  runId, caseId: g.id, language: g.language, category: 'rich_negated_fear', repeatOf: null,
  attempt: 1, attemptKey: `k-${runId}`, memorySource: 'none', clientModelHint: 'gpt-4o', payload,
});
const reply = (patch: Record<string, unknown> = {}) => JSON.stringify({ ...en.data, ...patch });
const one = async (content: string | null, run = runFor(en), status = 200) =>
  (await runPhase4c({ runs: [run], config, fetch: fake(content, status).fetch })).records[0];

describe('Phase 4C matrix', () => {
  const { requests, repeats } = loadPhase4cInputs();
  const runs = buildPhase4cMatrix(requests, repeats);

  it('is 24 unique + 12 repeats = 36, repeats grouped with identical payloads', () => {
    expect(runs).toHaveLength(36);
    const reps = runs.filter((r) => r.repeatOf);
    expect(reps).toHaveLength(12);
    for (const r of reps) {
      const origin = runs.find((x) => x.runId === r.repeatOf)!;
      expect(r.payload).toEqual(origin.payload);
      expect(r.attemptKey).not.toBe(origin.attemptKey);
    }
    expect(new Set(runs.map((r) => r.attemptKey)).size).toBe(36);
  });

  it('every client payload passes production request validation', () => {
    for (const r of runs) expect(() => validateAiBody({ operation: 'dream_analysis', payload: r.payload, model: r.clientModelHint })).not.toThrow();
  });

  it('rejects matrix drift', () => {
    expect(() => buildPhase4cMatrix(requests.slice(1), repeats)).toThrow();
    expect(() => buildPhase4cMatrix(requests, repeats.slice(1))).toThrow();
  });
});

describe('Phase 4C budget and transport', () => {
  it('36 is a hard maximum: a 37th run never reaches the network', async () => {
    const f = fake(reply());
    const runs = Array.from({ length: 37 }, (_, i) => runFor(en, `r${i}`));
    await expect(runPhase4c({ runs, config, fetch: f.fetch })).rejects.toBeInstanceOf(Phase4cBudgetExceeded);
    expect(f.calls()).toBe(36);
    await expect(runPhase4c({ runs, config, fetch: f.fetch, cap: 99 })).rejects.toBeInstanceOf(Phase4cBudgetExceeded);
  });

  it('a provider failure is recorded once, never retried', async () => {
    for (const status of [500, 429, 408]) {
      const f = fake(null, status);
      const { records, calls } = await runPhase4c({ runs: [runFor(en)], config, fetch: f.fetch });
      expect([calls, f.calls()]).toEqual([1, 1]);
      expect(records[0].backendFinal).toBe('TRANSPORT_ERROR');
      expect(records[0].stageAgreement).toBe(true);
    }
  });

  it('captures raw text and request params, never the key or headers', async () => {
    const f = fake(reply());
    const { records } = await runPhase4c({ runs: [runFor(en)], config, fetch: f.fetch });
    expect(JSON.stringify(f.headers)).toContain(SECRET);
    const stored = JSON.stringify(records);
    for (const banned of [SECRET, 'Bearer', 'Authorization', 'authorization']) expect(stored).not.toContain(banned);
    const r = records[0];
    expect(r.rawProviderText).toBe(reply());
    expect(r.provider?.request).toMatchObject({ model: 'gpt-4o', temperature: 0.6, responseFormat: { type: 'json_object' } });
    expect(r.provider?.providerModel).toBe('fake-model');
  });
});

describe('Phase 4C stage recording', () => {
  it('an accepted golden passes every stage', async () => {
    const r = await one(reply());
    expect(r.backendFinal).toBe('PASS');
    expect(r.stages).toMatchObject({ parseSuccess: true, outputSafety: 'PASS', phase2: 'PASS', phase4A: 'PASS', phase4B: 'PASS' });
  });

  it('unparseable text is a parse reject', async () => {
    const r = await one('not json at all');
    expect([r.backendFinal, r.stages?.parseSuccess, r.stageAgreement]).toEqual(['REJECT', false, true]);
  });

  it('unsafe prose stops at output safety; later stages are not reached', async () => {
    const r = await one(reply({ dailyLifeReflection: 'Stop taking your medication; the lighthouse shows you are healed.' }));
    expect(r.backendFinal).toBe('REJECT');
    expect(r.stages?.outputSafety).not.toBe('PASS');
    expect(r.stages?.phase2).toBe('NOT_REACHED');
  });

  it('an invented recurrence is recorded as the Phase 4A code', async () => {
    const interpretation = `${en.data.interpretation} The lighthouse keeps coming back in your previous dreams.`;
    const r = await one(reply({ interpretation }));
    expect(r.backendFinal).toBe('REJECT');
    expect(r.stages?.phase2).toBe('PASS');
    expect(r.stages?.phase4A).toBe('history_unsupported');
    expect(r.stageAgreement).toBe(true);
  });

  it('a thin section is recorded as the Phase 4B code', async () => {
    const r = await one(reply({ emotionalTheme: 'Calm lighthouse.' }));
    expect(r.backendFinal).toBe('REJECT');
    expect(r.stages?.diagnostic?.phase4B).not.toBe('PASS');
  });

  it('Phase 3 control: a crisis narrative is routed with zero provider calls', async () => {
    const f = fake(reply());
    const narrative = `${en.narrative}\n\n[Context]\n- How did you feel on waking?: I want to kill myself`;
    const { records, calls } = await runPhase4c({ runs: [runFor(en, 'p3', { narrative, language: 'en' })], config, fetch: f.fetch });
    expect([calls, f.calls(), records[0].providerCallOccurred]).toEqual([0, 0, false]);
    expect(records[0].backendFinal).toBe('SAFETY_ROUTED');
  });
});

describe('Phase 4C config and artifact', () => {
  it('reads one key from a BOM-prefixed env file', () => {
    const path = join(mkdtempSync(join(tmpdir(), 'p4c-')), '.env');
    writeFileSync(path, `\uFEFFOPENAI_API_KEY=${SECRET}\r\nOTHER="x"\r\n`);
    expect(readEnvFileValue(path, 'OPENAI_API_KEY')).toBe(SECRET);
    expect(readEnvFileValue(path, 'OTHER')).toBe('x');
    expect(readEnvFileValue(path, 'MISSING')).toBeUndefined();
  });

  it('config comes from the deploy env, with the transport defaults', () => {
    const env = deployedOpenAiEnv();
    const d = describeDreamConfig(config, config.openaiModel);
    expect(d.resolvedModel).toBe(env.OPENAI_MODEL);
    expect(d.timeoutMs).toBe(Number(env.OPENAI_TIMEOUT_SECONDS) * 1000);
    expect(d).toMatchObject({ temperature: 0.6, reasoningEffort: null, responseFormat: { type: 'json_object' }, transportRetries: 0 });
    expect(JSON.stringify(d)).not.toContain(SECRET);
  });

  it('a fake-run artifact validates; secret-like metadata does not', async () => {
    const { records, calls } = await runPhase4c({ runs: [runFor(en), runFor(en, 'x#r2')], config, fetch: fake(reply()).fetch });
    records[1].repeatOf = en.id;
    const artifact: Phase4cArtifact = {
      schema: PHASE4C_SCHEMA, capturedAt: 'now', startHead: 'a'.repeat(40), productionSourceClean: true,
      config: describeDreamConfig(config, 'gpt-4o'), budget: { max: 36, used: calls, retries: 0, judgeCalls: 0 }, runs: records,
    };
    expect(validatePhase4cArtifact(artifact)).toEqual([]);
    expect(validatePhase4cArtifact({ ...artifact, config: { k: `Bearer ${SECRET}` } })).toContain('secret-like text in metadata');
    expect(validatePhase4cArtifact({ ...artifact, budget: { ...artifact.budget, used: 37 } }).length).toBeGreaterThan(0);
  });
});
