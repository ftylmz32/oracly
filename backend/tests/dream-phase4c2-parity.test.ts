import { describe, expect, it } from 'vitest';
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { dreamMessages } from '../src/ai/prompts.js';
import { AiProxyService } from '../src/ai/service.js';
import { runPhase4c2, validated } from '../scripts/dream-phase4c2/harness.js';
import {
  FROZEN_EVIDENCE, PHASE4C2_ARTIFACT_PATH, PHASE4C2_SCHEMA, validatePhase4c2Artifact, type Phase4c2Artifact,
} from '../scripts/dream-phase4c2/artifact.js';
import { candidate, estimateCostUsd } from '../scripts/dream-phase4c2/candidates.js';
import { buildPhase4c2Matrix, loadPhase4c2Requests } from '../scripts/dream-phase4c2/matrix.js';
import { loadConfig } from '../src/config.js';
import { deployedOpenAiEnv } from '../scripts/dream-phase4c/production-config.js';
import { completion, FAKE_KEY, fakeConfig, fakeFetch, frozenRaw } from './dream-phase4c2-support.js';

const attempts = buildPhase4c2Matrix(loadPhase4c2Requests());
const trFear = attempts.filter((a) => a.caseId === 'tr-negated-fear');

async function production(raw: string, config = fakeConfig()) {
  const fake = fakeFetch((body) => completion(String(body.model), raw));
  const service = new AiProxyService(config, fake.fetch);
  const request = validated(trFear[0]);
  const outcome = await service.handle(request, 'gpt-4o').then(() => 'PASS', (e: { code?: string }) => e.code);
  return { body: fake.sent[0].body, outcome };
}

/** Pre-4C.3 Dream body: no dedicated writer, generic gpt-4o (development only). */
const genericDevConfig = () =>
  loadConfig({ ...deployedOpenAiEnv(), APP_ENV: 'development', OPENAI_DREAM_MODEL: '', OPENAI_DREAM_REASONING_EFFORT: '', OPENAI_API_KEY: FAKE_KEY });

async function adapterBody(model: string) {
  const fake = fakeFetch((body) => completion(String(body.model), frozenRaw('tr-negated-fear')));
  await runPhase4c2({ attempts: trFear.filter((a) => a.candidate === model), config: fakeConfig(), fetch: fake.fetch });
  return JSON.stringify(fake.sent[0].body);
}

describe('Phase 4C.2 adapter mirrors AiProxyService.dream', () => {
  it('the Astra candidate sends the 4C.3 production body byte for byte', async () => {
    const prod = await production(frozenRaw('tr-negated-fear'));
    expect(await adapterBody('gpt-6-astra')).toBe(JSON.stringify(prod.body));
  });

  it('the gpt-4o candidate sends the pre-4C.3 generic body byte for byte', async () => {
    const prod = await production(frozenRaw('tr-negated-fear'), genericDevConfig());
    expect(prod.body.model).toBe('gpt-4o');
    expect(await adapterBody('gpt-4o')).toBe(JSON.stringify(prod.body));
  });

  it.each([
    ['tr-negated-fear', 'PASS', 'PASS', null],
    ['tr-negated-fear#r2', 'invalid_response', 'REJECT', 'invented_image'],
  ])('%s: production %s ⇔ harness %s for every model', async (runId, prodOutcome, final, failure) => {
    expect((await production(frozenRaw(runId))).outcome).toBe(prodOutcome);
    const fake = fakeFetch((body) => completion(String(body.model), frozenRaw(runId)));
    const { records } = await runPhase4c2({ attempts: trFear, config: fakeConfig(), fetch: fake.fetch });
    for (const r of records) {
      expect(r).toMatchObject({ backendFinal: final, firstFailure: failure, productionAgreement: true, parseSuccess: true });
      expect(r.clientResult).toBe(final === 'PASS' ? 'PENDING_CLIENT_REPLAY' : 'NOT_DELIVERED');
    }
  });

  it('every prompt language mentions JSON (required by JSON mode)', () => {
    for (const a of attempts) {
      const request = validated(a);
      expect(JSON.stringify(dreamMessages(request.payload, request.language))).toContain('JSON');
    }
  });

  it('ru-memory sends the retrieved memory summary exactly', async () => {
    const memory = attempts.filter((a) => a.caseId === 'ru-memory');
    const fake = fakeFetch((body) => completion(String(body.model), '{}'));
    const { records } = await runPhase4c2({ attempts: memory, config: fakeConfig(), fetch: fake.fetch });
    for (const r of records) expect(r.memorySummarySent).toBe(memory[0].payload.memorySummary);
    expect(JSON.stringify(fake.sent[0].body.messages)).toContain(String(memory[0].payload.memorySummary));
  });
});

describe('Phase 4C.2 cost', () => {
  const usage = { prompt_tokens: 3000, completion_tokens: 700, prompt_tokens_details: { cached_tokens: 1024, cache_write_tokens: 0 } };
  it('is deterministic from documented pricing', () => {
    expect(estimateCostUsd(candidate('gpt-4o'), usage, 'default').usd).toBe(0.01322);
    expect(estimateCostUsd(candidate('gpt-6-sol'), usage, 'default').usd).toBe(0.011157);
    expect(estimateCostUsd(candidate('gpt-6-astra'), { ...usage, prompt_tokens_details: { cached_tokens: 0, cache_write_tokens: 2048 } }, null).usd).toBe(0.07012);
  });
  it('is null, never guessed, when a billing input is missing', () => {
    const noWrite = { ...usage, prompt_tokens_details: { cached_tokens: 0 } };
    expect(estimateCostUsd(candidate('gpt-6-sol'), noWrite, 'default')).toEqual({ usd: null, reason: 'cache_write_tokens_not_reported' });
    expect(estimateCostUsd(candidate('gpt-4o'), { prompt_tokens: 10, completion_tokens: 5 }, 'default').reason).toBe('cached_tokens_not_reported');
    expect(estimateCostUsd(candidate('gpt-4o'), usage, 'priority').reason).toBe('service_tier_priority');
    expect(estimateCostUsd(candidate('gpt-4o'), null, null).reason).toBe('usage_not_reported');
  });
});

describe('Phase 4C.2 artifact safety', () => {
  it('a fake-run artifact validates and never carries the key', async () => {
    const fake = fakeFetch((body) => completion(String(body.model), frozenRaw('tr-negated-fear')));
    const { records, calls } = await runPhase4c2({ attempts, config: fakeConfig(), fetch: fake.fetch });
    expect(fake.sent[0].headers.Authorization).toBe(`Bearer ${FAKE_KEY}`);
    const artifact: Phase4c2Artifact = {
      schema: PHASE4C2_SCHEMA,
      capturedAt: 'fake',
      startHead: 'fake',
      productionSourceClean: true,
      modelWinner: 'PENDING_INDEPENDENT_REVIEW',
      compatibility: {},
      config: {},
      budget: { max: 27, used: calls, retries: 0, repairCalls: 0, judgeCalls: 0 },
      attempts: records,
    };
    const text = JSON.stringify(artifact);
    expect(text).not.toContain(FAKE_KEY);
    expect(text).not.toMatch(/authorization|bearer/i);
    expect(validatePhase4c2Artifact(artifact)).toEqual([]);
    expect(validatePhase4c2Artifact({ ...artifact, config: { leaked: `Bearer ${FAKE_KEY}` } })).toContain('secret-shaped content');
    expect(records.every((r) => r.inventedConcreteSceneContent === 'PENDING_INDEPENDENT_REVIEW')).toBe(true);
  });

  it('writes a new file only; frozen 4C/4C.1 evidence is a different path', () => {
    expect(FROZEN_EVIDENCE).not.toContain(PHASE4C2_ARTIFACT_PATH);
    for (const p of FROZEN_EVIDENCE) expect(existsSync(p)).toBe(true);
  });

  it('the live runner refuses without explicit opt-in (no call)', () => {
    const env = { ...process.env, PHASE4C2_LIVE: '', OPENAI_API_KEY: FAKE_KEY };
    const run = spawnSync('npx tsx scripts/dream-phase4c2/run-live.ts', { env, encoding: 'utf8', shell: true });
    expect(run.status).toBe(2);
    expect(run.stderr).toContain('REAL PROVIDER CALLS: 0');
    expect(`${run.stdout}${run.stderr}`).not.toContain(FAKE_KEY);
  }, 60_000);
});
