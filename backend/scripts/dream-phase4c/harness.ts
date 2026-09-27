/**
 * Dream Phase 4C — runs the matrix through the production Dream path:
 * `validateAiBody` → `AiProxyService.handle` → real `OpenAiTransport` →
 * `dreamMessages` / `parseDreamData` / `dreamOutputViolation` /
 * `dreamAcceptanceFailure`. One call per run, no retries, hard cap.
 */
import type { AppLanguage } from '../../src/ai/app-language.js';
import { DREAM_WRITER_REVISION } from '../../src/ai/dream-request-identity.js';
import { AiProxyService } from '../../src/ai/service.js';
import { validateAiBody, type ValidatedRequest } from '../../src/ai/validate-request.js';
import { resolveModel, type AppConfig } from '../../src/config.js';
import { ErrorCode, ProxyError } from '../../src/errors.js';
import type { OpenAiFetch } from '../../src/types.js';
import { budgetFetch, Phase4cBudgetExceeded, type ProviderCapture } from './budget-fetch.js';
import { PHASE4C_MAX_CALLS, type Phase4cRun } from './matrix.js';
import { classifyDreamOutput, type StageReport } from './stages.js';

export type Phase4cRecord = Omit<Phase4cRun, 'payload'> & {
  narrative: string;
  symbols: unknown;
  emotions: unknown;
  memorySummary: string | null;
  history: unknown;
  resolvedModel: string;
  writerRevision: string;
  providerCallOccurred: boolean;
  latencyMs: number | null;
  provider: Omit<ProviderCapture, 'rawText'> | null;
  rawProviderText: string | null;
  stages: StageReport | null;
  backendFinal: 'PASS' | 'REJECT' | 'TRANSPORT_ERROR' | 'SAFETY_ROUTED';
  errorCode: string | null;
  stageAgreement: boolean;
};

export async function runPhase4c(options: {
  runs: Phase4cRun[];
  config: AppConfig;
  fetch: OpenAiFetch;
  cap?: number;
  onRecord?: (record: Phase4cRecord, callsSoFar: number) => void;
}): Promise<{ records: Phase4cRecord[]; calls: number }> {
  const cap = Math.min(options.cap ?? PHASE4C_MAX_CALLS, PHASE4C_MAX_CALLS);
  const budget = budgetFetch(options.fetch, cap);
  const service = new AiProxyService(options.config, budget.fetch);
  const records: Phase4cRecord[] = [];
  for (const run of options.runs) {
    if (budget.calls() >= cap) throw new Phase4cBudgetExceeded(`hard cap ${cap} reached`);
    records.push(await runOne(run, options.config, service, budget));
    options.onRecord?.(records[records.length - 1], budget.calls());
  }
  return { records, calls: budget.calls() };
}

async function runOne(
  run: Phase4cRun,
  config: AppConfig,
  service: AiProxyService,
  budget: ReturnType<typeof budgetFetch>,
): Promise<Phase4cRecord> {
  const validated = validateAiBody({
    operation: 'dream_analysis',
    payload: run.payload,
    model: run.clientModelHint,
  }) as Extract<ValidatedRequest, { operation: 'dream_analysis' }>;
  const before = budget.calls();
  let backendFinal: Phase4cRecord['backendFinal'] = 'PASS';
  let errorCode: string | null = null;
  try {
    await service.handle(validated, run.clientModelHint);
  } catch (error) {
    if (error instanceof Phase4cBudgetExceeded) throw error;
    errorCode = error instanceof ProxyError ? error.code : 'unexpected';
    backendFinal = 'TRANSPORT_ERROR';
  }
  const called = budget.calls() > before;
  const capture = called ? budget.take() : null;
  const raw = capture?.rawText ?? null;
  const payload = validated.payload;
  const stages = raw === null ? null : classifyDreamOutput(raw, payload, validated.language as AppLanguage);
  if (!called && errorCode) backendFinal = 'SAFETY_ROUTED';
  if (called && errorCode === ErrorCode.invalidResponse && raw !== null) backendFinal = 'REJECT';
  const agreement =
    stages === null ? backendFinal !== 'PASS' : stages.final === backendFinal || backendFinal === 'TRANSPORT_ERROR';
  const { payload: _omit, ...meta } = run;
  const { rawText: _raw, ...provider } = capture ?? { rawText: null };
  return {
    ...meta,
    narrative: String(payload.narrative),
    symbols: payload.symbols ?? [],
    emotions: payload.emotions ?? [],
    memorySummary: typeof payload.memorySummary === 'string' ? payload.memorySummary : null,
    history: payload.history ?? null,
    resolvedModel: resolveModel(config, run.clientModelHint),
    writerRevision: DREAM_WRITER_REVISION,
    providerCallOccurred: called,
    latencyMs: capture?.latencyMs ?? null,
    provider: capture ? (provider as Omit<ProviderCapture, 'rawText'>) : null,
    rawProviderText: raw,
    stages,
    backendFinal,
    errorCode,
    stageAgreement: agreement,
  };
}
