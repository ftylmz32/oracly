/**
 * Dream Phase 4C.2 — offline analysis of the captured comparison (no
 * provider call). Joins the Flutter client replay onto each backend PASS
 * and writes unranked, mechanical observations. The winner stays pending.
 *
 *   npx tsx scripts/dream-phase4c2/analyze.ts
 */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { FIELDS } from '../dream-phase4c/observe-text.js';
import {
  PHASE4C2_ARTIFACT_PATH, PHASE4C2_CLIENT_REPLAY_PATH, validatePhase4c2Artifact, type Phase4c2Artifact,
} from './artifact.js';
import { PHASE4C2_CASES } from './matrix.js';
import { observeAttempt, perModel } from './observe.js';
import { PENDING_REVIEW, type Phase4c2Record } from './record.js';

type Replay = { runId: string; clientResult: string; clientGap?: string | null; requiredAiSections?: number; fromAi?: boolean; fields?: Record<string, { source: string | null; layer: string | null; rewrite: string }> };

const EMOTION_CASES = ['tr-negated-fear', 'en-negated-fear', 'ru-negated-fear', 'en-mixed-emotion'];
const HISTORY_CASES = ['en-history', 'tr-history'];

export function loadClientReplays(path = PHASE4C2_CLIENT_REPLAY_PATH): Replay[] {
  return existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')).replays : [];
}

function joinClient(r: Phase4c2Record, replay: Replay | undefined): Phase4c2Record {
  if (r.backendFinal !== 'PASS') return r;
  if (!replay) return { ...r, clientResult: 'PENDING_CLIENT_REPLAY', clientFailureReason: null };
  const layers = Object.entries(replay.fields ?? {}).filter(([, f]) => f.layer).map(([k, f]) => `${k}: ${f.layer}`);
  return {
    ...r,
    clientResult: replay.clientResult,
    clientFailureReason: replay.clientResult === 'PASS' ? null : [replay.clientGap, ...layers].filter(Boolean).join('; '),
  };
}

function sideBySide(records: Phase4c2Record[], replays: Map<string, Replay>) {
  return PHASE4C2_CASES.map((caseId) => ({
    caseId,
    note: 'Unranked; listed in live call order.',
    attempts: records.filter((r) => r.caseId === caseId).map((r) => ({
      candidateModel: r.candidateModel,
      fields: r.parsed ? Object.fromEntries(FIELDS.map((f) => [f, r.parsed![f]])) : null,
      rawSymbols: r.rawSymbols,
      filteredSymbols: r.filteredSymbols,
      backendFinal: r.backendFinal,
      firstFailure: r.firstFailure,
      clientResult: r.clientResult,
      clientProvenance: replays.get(r.attemptId)?.fields
        ? Object.fromEntries(Object.entries(replays.get(r.attemptId)!.fields!).map(([k, f]) => [k, f.source]))
        : null,
      latencyMs: r.latencyMs,
      tokens: { input: r.usage.inputTokens, output: r.usage.outputTokens, reasoning: r.usage.reasoningTokens },
      estimatedCostUsd: r.estimatedCostUsd,
    })),
  }));
}

export function computeAnalysis(records: Phase4c2Record[], replays: Replay[]) {
  const byRun = new Map(replays.map((r) => [r.runId, r]));
  const obs = new Map(records.map((r) => [r.attemptId, observeAttempt(r)]));
  const parsedObs = (id: string) => obs.get(id) as Extract<ReturnType<typeof observeAttempt>, { parsed: true }> | undefined;
  const passes = records.filter((r) => r.backendFinal === 'PASS');
  return {
    method: {
      note: 'Mechanical string facts only; no score, no ranking, no judge model.',
      modelWinner: PENDING_REVIEW,
      inventedConcreteSceneContent: `${PENDING_REVIEW}: the gates judge prose, so an invented scene item without a catalogue anchor can pass (Phase 4C.1b limit).`,
    },
    infrastructure: {
      providerCalls: records.length,
      nonHttp200: records.filter((r) => r.httpStatus !== 200).map((r) => ({ attemptId: r.attemptId, httpClass: r.httpClass })),
      modelsWithoutAnyResponse: [...new Set(records.map((r) => r.candidateModel))].filter(
        (m) => !records.some((r) => r.candidateModel === m && r.httpStatus === 200),
      ),
    },
    clientParity: {
      backendPass: passes.length,
      replayed: passes.filter((r) => byRun.has(r.attemptId)).length,
      backendPassClientFail: passes.filter((r) => r.clientResult !== 'PASS').map((r) => ({ attemptId: r.attemptId, reason: r.clientFailureReason })),
    },
    perModel: perModel(records),
    sideBySide: sideBySide(records, byRun),
    perAttempt: [...obs.values()],
    emotionFidelity: records.filter((r) => EMOTION_CASES.includes(r.caseId)).map((r) => ({
      attemptId: r.attemptId,
      statedEmotions: r.emotionsSent,
      emotionalTheme: r.parsed?.emotionalTheme ?? null,
      contradiction: parsedObs(r.attemptId)?.emotionContradiction ?? null,
      phase4BIndependent: r.diagnostic?.phase4B ?? null,
      backendFinal: r.backendFinal,
      firstFailure: r.firstFailure,
    })),
    history: records.filter((r) => HISTORY_CASES.includes(r.caseId)).map((r) => ({
      attemptId: r.attemptId,
      historySupplied: r.history,
      historyClaims: parsedObs(r.attemptId)?.historyClaims ?? null,
      claimFlags: parsedObs(r.attemptId)?.historyClaimFlags ?? null,
      phase4AIndependent: r.diagnostic?.phase4A ?? null,
      backendFinal: r.backendFinal,
    })),
    memory: records.filter((r) => r.caseId === 'ru-memory').map((r) => ({
      attemptId: r.attemptId,
      memorySource: r.memorySource,
      memorySummarySent: r.memorySummarySent,
      use: parsedObs(r.attemptId)?.memory ?? null,
      backendFinal: r.backendFinal,
    })),
  };
}

export function withAnalysis(artifact: Phase4c2Artifact, replays: Replay[]): Phase4c2Artifact {
  const byRun = new Map(replays.map((r) => [r.runId, r]));
  const attempts = artifact.attempts.map((r) => joinClient(r, byRun.get(r.attemptId)));
  return { ...artifact, attempts, analysis: computeAnalysis(attempts, replays) };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const artifact = JSON.parse(readFileSync(PHASE4C2_ARTIFACT_PATH, 'utf8')) as Phase4c2Artifact;
  if (artifact.analysis) throw new Error('the 4C.2 artifact is already analyzed');
  const next = withAnalysis(artifact, loadClientReplays());
  const errors = validatePhase4c2Artifact(next);
  if (errors.length) throw new Error(`schema: ${errors.join('; ')}`);
  writeFileSync(PHASE4C2_ARTIFACT_PATH, `${JSON.stringify(next, null, 2)}\n`);
  console.log(`analyzed attempts=${next.attempts.length} replays=${loadClientReplays().length}`);
}
