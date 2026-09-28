import { describe, expect, it } from 'vitest';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { loadClientReplays, withAnalysis } from '../scripts/dream-phase4c2/analyze.js';
import {
  FROZEN_EVIDENCE, PHASE4C2_ARTIFACT_PATH, validatePhase4c2Artifact, type Phase4c2Artifact,
} from '../scripts/dream-phase4c2/artifact.js';
import { buildPhase4c2Matrix, loadPhase4c2Requests } from '../scripts/dream-phase4c2/matrix.js';

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

  it('the analysis is deterministic from the live attempts and the client replay', () => {
    const { analysis: _a, ...live } = artifact;
    expect(JSON.stringify(withAnalysis(live as Phase4c2Artifact, replays))).toBe(JSON.stringify(artifact));
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
