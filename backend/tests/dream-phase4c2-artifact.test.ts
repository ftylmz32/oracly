import { describe, expect, it } from 'vitest';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { loadClientReplays, withAnalysis } from '../scripts/dream-phase4c2/analyze.js';
import {
  FROZEN_EVIDENCE, PHASE4C2_ARTIFACT_PATH, validatePhase4c2Artifact, type Phase4c2Artifact,
} from '../scripts/dream-phase4c2/artifact.js';
import { buildPhase4c2Matrix, loadPhase4c2Requests } from '../scripts/dream-phase4c2/matrix.js';
import { jsonDrift } from '../scripts/dream-phase4c2a/drift.js';

const artifact = JSON.parse(readFileSync(PHASE4C2_ARTIFACT_PATH, 'utf8')) as Phase4c2Artifact;
const replays = loadClientReplays();
const attempts = buildPhase4c2Matrix(loadPhase4c2Requests());

describe('Phase 4C.2 model comparison artifact', () => {
  it('validates: 27 calls, no retry/repair/judge, pinned parameters, no secrets', () => {
    expect(validatePhase4c2Artifact(artifact)).toEqual([]);
    expect(artifact.attempts).toHaveLength(27);
    expect(artifact.budget).toEqual({ max: 27, used: 27, retries: 0, repairCalls: 0, judgeCalls: 0 });
    expect(artifact.productionSourceClean).toBe(true);
  });

  it('keeps the winner and scene-content verdicts pending independent review', () => {
    expect(artifact.modelWinner).toBe('PENDING_INDEPENDENT_REVIEW');
    for (const r of artifact.attempts) {
      expect(r.inventedConcreteSceneContent).toBe('PENDING_INDEPENDENT_REVIEW');
      expect(r.inventedConcreteSceneItems).toEqual([]);
    }
    expect(JSON.stringify(artifact.analysis)).not.toMatch(/"(score|rank|ranking|winner)"\s*:/i);
  });

  it('records the payload each case actually sent, identical across models', () => {
    for (const [i, r] of artifact.attempts.entries()) {
      const p = attempts[i].payload;
      expect(r.narrative).toBe(p.narrative);
      expect(r.symbolsSent).toEqual(p.symbols ?? []);
      expect(r.emotionsSent).toEqual(p.emotions ?? []);
      expect(r.history).toEqual(p.history ?? null);
      expect(r.memorySummarySent).toBe(typeof p.memorySummary === 'string' ? p.memorySummary : null);
    }
    const memory = artifact.attempts.filter((r) => r.caseId === 'ru-memory');
    expect(memory.every((r) => r.memorySource === 'retriever' && r.memorySummarySent)).toBe(true);
  });

  it('replays every backend PASS through the client, and only those', () => {
    const passes = artifact.attempts.filter((r) => r.backendFinal === 'PASS');
    expect(replays.map((r) => r.runId)).toEqual(passes.map((r) => r.attemptId));
    const byRun = new Map(replays.map((r) => [r.runId, r]));
    for (const r of passes) expect(r.clientResult).toBe(byRun.get(r.attemptId)!.clientResult);
    for (const r of artifact.attempts.filter((x) => x.backendFinal !== 'PASS')) expect(r.clientResult).toBe('NOT_DELIVERED');
  });

  // The 4C.2 artifact is frozen evidence; its mechanical observations use the
  // production gates. The only permitted drift is what the 4C.2a calibration
  // closed: TR korkutmuyor, RU не вызывает испуга, EN `without`, TR ilişkin.
  it('the analysis re-derives from the live attempts up to the named 4C.2a drift', () => {
    const { analysis: _a, ...live } = artifact;
    const now = JSON.parse(JSON.stringify(withAnalysis(live as Phase4c2Artifact, replays)));
    const mech = '$.analysis.perModel';
    expect(jsonDrift(artifact, now)).toEqual([
      { path: `${mech}.gpt-6-sol.mechanical.emotionContradictions.0`, frozen: 'tr-negated-fear::gpt-6-sol', now: 'ru-negated-fear::gpt-6-sol' },
      { path: `${mech}.gpt-6-sol.mechanical.emotionContradictions.1`, frozen: 'ru-negated-fear::gpt-6-sol', now: undefined },
      { path: `${mech}.gpt-6-sol.mechanical.emotionContradictions.2`, frozen: 'en-mixed-emotion::gpt-6-sol', now: undefined },
      { path: `${mech}.gpt-6-astra.mechanical.emotionContradictions.1`, frozen: 'ru-negated-fear::gpt-6-astra', now: undefined },
      { path: `${mech}.gpt-6-astra.mechanical.unsupportedDomain.0`, frozen: { runId: 'tr-domain-work::gpt-6-astra', domain: 'relationship' }, now: undefined },
      { path: '$.analysis.perAttempt.1.emotionContradiction.emotionalTheme', frozen: true, now: false },
      { path: '$.analysis.perAttempt.6.emotionContradiction.emotionalTheme', frozen: true, now: false },
      { path: '$.analysis.perAttempt.10.emotionContradiction.emotionalTheme', frozen: true, now: false },
      { path: '$.analysis.perAttempt.13.addressedDomain', frozen: 'relationship', now: null },
      { path: '$.analysis.perAttempt.13.unsupportedDomain', frozen: 'relationship', now: null },
      { path: '$.analysis.emotionFidelity.1.contradiction.emotionalTheme', frozen: true, now: false },
      { path: '$.analysis.emotionFidelity.6.contradiction.emotionalTheme', frozen: true, now: false },
      { path: '$.analysis.emotionFidelity.10.contradiction.emotionalTheme', frozen: true, now: false },
    ]);
  });

  it('every attempt reached the provider with one HTTP 200 and computable cost', () => {
    for (const r of artifact.attempts) {
      expect(r.providerCallOccurred).toBe(true);
      expect(r.httpStatus).toBe(200);
      expect(r.estimatedCostUsd).toBeGreaterThan(0);
    }
  });

  it('left the frozen 4C / 4C.1 evidence untouched', () => {
    const changed = execFileSync('git', ['diff', '--name-only', 'HEAD', '--', ...FROZEN_EVIDENCE], { encoding: 'utf8' });
    expect(changed.trim()).toBe('');
  });
});
