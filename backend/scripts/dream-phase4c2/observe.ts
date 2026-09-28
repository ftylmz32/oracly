/**
 * Dream Phase 4C.2 — mechanical observations per attempt and per model,
 * reusing the Phase 4C measures. String facts only: no score, no ranking,
 * no semantic verdict (that stays with the independent review).
 */
import type { Phase4cRecord } from '../dream-phase4c/harness.js';
import { boilerplate } from '../dream-phase4c/observe-corpus.js';
import { observeReading } from '../dream-phase4c/observe-reading.js';
import { FIELDS, round } from '../dream-phase4c/observe-text.js';
import { CANDIDATES } from './candidates.js';
import type { Phase4c2Record } from './record.js';

/** The Phase 4C record shape the shared observers read. */
export function asPhase4c(r: Phase4c2Record): Phase4cRecord {
  return {
    runId: r.attemptId,
    caseId: r.caseId,
    language: r.language,
    category: r.category,
    memorySource: r.memorySource,
    narrative: r.narrative,
    symbols: r.symbolsSent,
    emotions: r.emotionsSent,
    memorySummary: r.memorySummarySent,
    history: r.history,
    errorCode: r.errorCode,
    stages: r.parsed
      ? { parseSuccess: true, parsed: r.parsed, outputSafety: r.outputSafety, phase2: r.phase2, phase4A: r.phase4A, phase4B: r.phase4B }
      : null,
  } as unknown as Phase4cRecord;
}

/** Why the production parser refused a body: JSON validity + short fields. */
export function parseFailureDetail(r: Phase4c2Record) {
  if (r.firstFailure !== 'parse_failed' || r.rawProviderText === null) return null;
  try {
    const json = JSON.parse(r.rawProviderText) as Record<string, unknown>;
    const short = FIELDS.filter((f) => typeof json[f] !== 'string' || (json[f] as string).trim().length < 8);
    return { validJson: true, fieldsUnderParserMinimum: short, values: Object.fromEntries(short.map((f) => [f, json[f] ?? null])) };
  } catch {
    return { validJson: false, fieldsUnderParserMinimum: [], values: {} };
  }
}

export function observeAttempt(r: Phase4c2Record) {
  const o = observeReading(asPhase4c(r));
  return { ...o, runId: r.attemptId, candidateModel: r.candidateModel, firstFailure: r.firstFailure, parseFailure: parseFailureDetail(r) };
}

export function latency(values: number[]) {
  if (!values.length) return null;
  const s = [...values].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return {
    n: s.length,
    medianMs: s.length % 2 ? s[mid] : round((s[mid - 1] + s[mid]) / 2),
    meanMs: round(s.reduce((a, b) => a + b, 0) / s.length),
    p90Ms: s[Math.ceil(0.9 * s.length) - 1],
    minMs: s[0],
    maxMs: s[s.length - 1],
  };
}

const sum = (xs: Array<number | null>) => xs.reduce<number>((a, b) => a + (b ?? 0), 0);
const count = (keys: string[]) => keys.reduce<Record<string, number>>((m, k) => ({ ...m, [k]: (m[k] ?? 0) + 1 }), {});

export function perModel(records: Phase4c2Record[]) {
  return Object.fromEntries(
    CANDIDATES.map(({ id }) => {
      const rs = records.filter((r) => r.candidateModel === id);
      const ok = rs.filter((r) => r.httpStatus === 200);
      const passes = rs.filter((r) => r.backendFinal === 'PASS');
      const clientPasses = passes.filter((r) => r.clientResult === 'PASS');
      const costs = rs.map((r) => r.estimatedCostUsd);
      const costKnown = costs.every((c) => c !== null);
      const total = costKnown ? Math.round(sum(costs) * 1e6) / 1e6 : null;
      const per = (n: number) => (costKnown && n ? Math.round((sum(costs) / n) * 1e6) / 1e6 : null);
      const obs = rs.map(observeAttempt).filter((o) => o.parsed) as Array<Extract<ReturnType<typeof observeAttempt>, { parsed: true }>>;
      const legacy = rs.map(asPhase4c);
      return [
        id,
        {
          outcomes: {
            attempts: rs.length,
            http: count(rs.map((r) => r.httpClass)),
            backendFinal: count(rs.map((r) => r.backendFinal)),
            firstFailure: count(rs.map((r) => r.firstFailure ?? 'PASS')),
            clientResult: count(passes.map((r) => r.clientResult ?? 'MISSING')),
          },
          cost: {
            attempts: rs.length,
            providerSuccesses: ok.length,
            backendPasses: passes.length,
            clientPasses: clientPasses.length,
            tokens: {
              input: sum(rs.map((r) => r.usage.inputTokens)),
              output: sum(rs.map((r) => r.usage.outputTokens)),
              reasoning: sum(rs.map((r) => r.usage.reasoningTokens)),
              cached: sum(rs.map((r) => r.usage.cachedTokens)),
              cacheWrite: sum(rs.map((r) => r.usage.cacheWriteTokens)),
            },
            totalUsd: total,
            perAttemptUsd: per(rs.length),
            perBackendPassUsd: per(passes.length),
            perClientPassUsd: per(clientPasses.length),
            note: 'Descriptive only; never a ranking input.',
          },
          latency: latency(rs.map((r) => r.latencyMs)),
          mechanical: {
            questionCount: count(obs.map((o) => String(o.questionCount))),
            emotionContradictions: obs.filter((o) => o.emotionContradiction.summary || o.emotionContradiction.emotionalTheme).map((o) => o.runId),
            unsupportedDomain: obs.filter((o) => o.unsupportedDomain).map((o) => ({ runId: o.runId, domain: o.unsupportedDomain })),
            historyClaimsWithoutHistory: obs.filter((o) => !o.historySupplied && o.historyClaims.length).map((o) => o.runId),
            duplicatePhrasesAcrossFields: obs.filter((o) => o.duplicatePhrasesAcrossFields.length).map((o) => ({ runId: o.runId, phrases: o.duplicatePhrasesAcrossFields })),
            roleSimilarity: obs.map((o) => ({ runId: o.runId, ...o.roleSimilarity })),
            wellnessHits: obs.filter((o) => o.reflectionWellnessHits > 0).map((o) => ({ runId: o.runId, hits: o.reflectionWellnessHits })),
          },
          boilerplate: {
            allLanguages: boilerplate(legacy.map((r) => ({ ...r, language: 'all' })), 'all'),
            ...Object.fromEntries(['tr', 'en', 'ru'].map((l) => [l, boilerplate(legacy, l)])),
          },
        },
      ];
    }),
  );
}
