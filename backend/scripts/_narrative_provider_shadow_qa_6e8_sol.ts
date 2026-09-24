/**
 * Phase 6E.8 — Explicit gpt-5.6-sol Narrative writer quality run.
 * HARD CAP: 6 real Chat Completions. Call #1 = compatibility canary + quality.
 * NO retry. NO billing. NO persistence. Does NOT overwrite 6E.6 artifacts.
 * QA-only Sol env overrides — does not mutate committed production .env.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { loadConfig } from '../src/config.js';
import { AiProxyService } from '../src/ai/service.js';
import { validateNarrativeTarotPayload } from '../src/ai/narrative-tarot-contract.js';
import { narrativeTarotMessages } from '../src/ai/narrative-tarot-prompts.js';
import {
  NARRATIVE_LIMITS,
  NARRATIVE_SCHEMA_NAME,
} from '../src/ai/narrative-tarot-limits.js';
import { NARRATIVE_TAROT_RESULT_SCHEMA } from '../src/ai/narrative-tarot-result-schema.js';
import {
  buildNarrativeTarotCompleteOptions,
  narrativeModelQaMetadata,
} from '../src/ai/narrative-tarot-model.js';
import { buildChatCompletionBody } from '../src/ai/openai-transport.js';
import { ProxyError } from '../src/errors.js';
import type { OpenAiFetch } from '../src/types.js';

const CAP = 6;
const QA_RUN_HEAD = 'c342ab8f8813423cb162888f5089e6fabbf955a6';
const SOL_MODEL = 'gpt-5.6-sol';
const ROOT = resolve(process.cwd(), '..');
const PAYLOADS = resolve(
  ROOT,
  'test/fixtures/tarot_narrative_provider_shadow_payloads_6e8_sol_v2.json',
);
const RESULTS = resolve(
  ROOT,
  'test/fixtures/tarot_narrative_provider_shadow_results_6e8_sol_v2.json',
);

const UNSUPPORTED = new Set([
  'uniqueItems',
  'contains',
  'minContains',
  'maxContains',
  'unevaluatedItems',
  'allOf',
  'not',
  'dependentRequired',
  'dependentSchemas',
  'if',
  'then',
  'else',
]);

const COMPAT_BLOCKER_CODES = new Set([
  'invalid_request',
  'no_configuration',
]);

type Ledger = { authorized: number; used: number; remaining: number };

function assertHead(): void {
  const arg = process.argv.find((a) => a.startsWith('--qa-head='));
  const head = arg?.slice('--qa-head='.length) ?? '';
  if (head !== QA_RUN_HEAD) {
    console.error(
      `HEAD LOCK FAIL: expected ${QA_RUN_HEAD} got ${head || '(missing)'}`,
    );
    process.exit(2);
  }
}

function collectUnsupported(
  node: unknown,
  hits: string[] = [],
  path = '$',
): string[] {
  if (Array.isArray(node)) {
    node.forEach((item, i) => collectUnsupported(item, hits, `${path}[${i}]`));
    return hits;
  }
  if (node && typeof node === 'object') {
    for (const [k, v] of Object.entries(node as Record<string, unknown>)) {
      if (UNSUPPORTED.has(k)) hits.push(`${path}.${k}`);
      collectUnsupported(v, hits, `${path}.${k}`);
    }
  }
  return hits;
}

function sanitizeFailure(err: unknown): Record<string, unknown> {
  const msg = err instanceof Error ? err.message : String(err);
  const redacted = msg
    .replace(/Bearer\s+\S+/gi, 'Bearer [REDACTED]')
    .replace(/sk-[A-Za-z0-9_-]+/g, '[REDACTED_KEY]');
  const out: Record<string, unknown> = {
    type: err instanceof Error ? err.constructor.name : 'unknown',
    message: redacted.slice(0, 400),
  };
  if (err instanceof ProxyError) {
    out.code = err.code;
    out.httpStatus = err.httpStatus;
    const d = err.details;
    if (d && typeof d === 'object') {
      const safe: Record<string, unknown> = {};
      if (typeof d.requestId === 'string') {
        safe.requestId = d.requestId.slice(0, 128);
      }
      if (typeof d.providerMessage === 'string') {
        safe.providerMessage = d.providerMessage.slice(0, 300);
      }
      if (typeof d.httpStatus === 'number') safe.httpStatus = d.httpStatus;
      if (Object.keys(safe).length > 0) out.details = safe;
    }
  }
  return out;
}

function solQaEnv(): NodeJS.ProcessEnv {
  const existing = (process.env.OPENAI_ALLOWED_MODELS ?? '').trim();
  const allowed = existing
    ? existing.includes(SOL_MODEL)
      ? existing
      : `${existing},${SOL_MODEL}`
    : `gpt-4o,gpt-4o-mini,${SOL_MODEL}`;
  return {
    ...process.env,
    APP_ENV: process.env.APP_ENV ?? 'development',
    AI_AUTH_REQUIRED: 'false',
    AI_DEV_AUTH_BYPASS: 'true',
    OPENAI_ALLOWED_MODELS: allowed,
    OPENAI_TAROT_NARRATIVE_MODEL: SOL_MODEL,
    OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'none',
  };
}

function isCompatBlocker(err: unknown, failure: Record<string, unknown>): boolean {
  const msg = String(failure.message ?? '').toLowerCase();
  const provider = String(
    (failure.details as { providerMessage?: string } | undefined)
      ?.providerMessage ?? '',
  ).toLowerCase();
  const blob = `${msg} ${provider}`;
  if (
    /model_not_found|does not exist|unsupported model|invalid model|reasoning_effort|response_format|json_schema|invalid_json_schema|unknown parameter|not supported/.test(
      blob,
    )
  ) {
    return true;
  }
  if (err instanceof ProxyError && COMPAT_BLOCKER_CODES.has(err.code)) {
    return true;
  }
  return false;
}

function isTransient5xx(failure: Record<string, unknown>): boolean {
  const http =
    typeof failure.httpStatus === 'number'
      ? failure.httpStatus
      : typeof (failure.details as { httpStatus?: number } | undefined)
            ?.httpStatus === 'number'
        ? (failure.details as { httpStatus: number }).httpStatus
        : null;
  return http != null && http >= 500 && http < 600;
}

async function discoverModel(
  apiKey: string,
  baseUrl: string,
): Promise<{ attempted: boolean; available: boolean | null }> {
  try {
    const res = await fetch(`${baseUrl.replace(/\/$/, '')}/models/${SOL_MODEL}`, {
      headers: { Authorization: `Bearer ${apiKey}` },
    });
    if (res.status === 200) return { attempted: true, available: true };
    if (res.status === 404) return { attempted: true, available: false };
    return { attempted: true, available: null };
  } catch {
    return { attempted: true, available: null };
  }
}

async function main() {
  assertHead();
  if (!process.env.OPENAI_API_KEY) {
    console.error('OPENAI_API_KEY missing — STOP. used=0');
    process.exit(3);
  }

  const dump = JSON.parse(readFileSync(PAYLOADS, 'utf8')) as {
    qaRunHead: string;
    resultContractVersion: number;
    providerSchemaName: string;
    entries: Array<{
      manifestId: string;
      languageCode: string;
      resolvedSpreadId: string;
      cardCount: number;
      displayName?: string;
      memoryEntryCount?: number;
      memorySummariesForQa?: unknown[];
      wirePayload: Record<string, unknown>;
    }>;
  };
  if (dump.qaRunHead !== QA_RUN_HEAD) {
    console.error('payload dump HEAD mismatch');
    process.exit(2);
  }
  if (dump.resultContractVersion !== 2) {
    console.error('Result Contract must be 2');
    process.exit(4);
  }
  if (dump.providerSchemaName !== 'oracly_tarot_narrative_v2') {
    console.error('provider schema mismatch');
    process.exit(4);
  }
  if (dump.entries.length !== 6) {
    console.error(`expected 6 entries, got ${dump.entries.length}`);
    process.exit(4);
  }

  const qaEnv = solQaEnv();
  const config = loadConfig(qaEnv);
  const modelMeta = narrativeModelQaMetadata(config);
  console.log('MODEL METADATA', JSON.stringify(modelMeta));
  if (
    modelMeta.configuredNarrativeModel !== SOL_MODEL ||
    modelMeta.resolvedNarrativeModel !== SOL_MODEL ||
    modelMeta.narrativeReasoningEffort !== 'none'
  ) {
    console.error('MODEL METADATA LOCK FAIL', modelMeta);
    process.exit(7);
  }

  const schemaHits = collectUnsupported(NARRATIVE_TAROT_RESULT_SCHEMA);
  if (schemaHits.length > 0) {
    console.error('SCHEMA COMPAT FAIL', schemaHits);
    process.exit(6);
  }
  const mem =
    NARRATIVE_TAROT_RESULT_SCHEMA.properties.memoryInsights.items.properties
      .memoryIndices;
  if ('uniqueItems' in mem) {
    console.error('uniqueItems still present in provider schema');
    process.exit(6);
  }
  if (mem.maxItems !== NARRATIVE_LIMITS.maxMemoryEntries) {
    console.error('memoryIndices.maxItems mismatch');
    process.exit(6);
  }

  // Exact outbound body precheck (case #1 messages)
  const sampleValidated = validateNarrativeTarotPayload(dump.entries[0]!.wirePayload);
  const sampleOpts = buildNarrativeTarotCompleteOptions(
    config,
    config.openaiModel,
    narrativeTarotMessages(sampleValidated.narrative, sampleValidated.language),
  );
  const sampleBody = buildChatCompletionBody(sampleOpts);
  if (sampleBody.model !== SOL_MODEL) {
    console.error('outbound model mismatch', sampleBody.model);
    process.exit(7);
  }
  if (sampleBody.reasoning_effort !== 'none') {
    console.error('outbound reasoning_effort mismatch', sampleBody.reasoning_effort);
    process.exit(7);
  }
  if ('temperature' in sampleBody) {
    console.error('temperature must be ABSENT for Sol Narrative body');
    process.exit(7);
  }
  const rf = sampleBody.response_format as {
    type: string;
    json_schema: { name: string; strict: boolean; schema: unknown };
  };
  if (rf.type !== 'json_schema') throw new Error('response_format.type');
  if (rf.json_schema.name !== NARRATIVE_SCHEMA_NAME) {
    throw new Error('schema name');
  }
  if (rf.json_schema.strict !== true) throw new Error('strict');
  const bodyHits = collectUnsupported(rf.json_schema.schema);
  if (bodyHits.length > 0) {
    console.error('unsupported in outbound schema', bodyHits);
    process.exit(6);
  }
  console.log('OUTBOUND BODY PRECHECK: PASS');
  console.log('SCHEMA COMPATIBILITY PRECALL: PASS (uniqueItems absent)');

  const discovery = await discoverModel(
    process.env.OPENAI_API_KEY!,
    config.openaiBaseUrl,
  );
  console.log(
    `MODEL DISCOVERY attempted=${discovery.attempted} available=${discovery.available}`,
  );

  const precall: Array<Record<string, unknown>> = [];
  for (const e of dump.entries) {
    try {
      const validated = validateNarrativeTarotPayload(e.wirePayload);
      const messages = narrativeTarotMessages(
        validated.narrative,
        validated.language,
      );
      const opts = buildNarrativeTarotCompleteOptions(
        config,
        config.openaiModel,
        messages,
      );
      const body = buildChatCompletionBody(opts);
      if (body.model !== SOL_MODEL) throw new Error('model');
      if (body.reasoning_effort !== 'none') throw new Error('reasoning');
      if ('temperature' in body) throw new Error('temperature_present');
      const brf = body.response_format as {
        type: string;
        json_schema: { name: string; strict: boolean; schema: unknown };
      };
      if (brf.type !== 'json_schema') throw new Error('response_format.type');
      if (brf.json_schema.name !== 'oracly_tarot_narrative_v2') {
        throw new Error('schema name');
      }
      if (brf.json_schema.strict !== true) throw new Error('strict');
      const hits = collectUnsupported(brf.json_schema.schema);
      if (hits.length > 0) throw new Error(`unsupported:${hits.join(',')}`);

      precall.push({
        manifestId: e.manifestId,
        ok: true,
        language: validated.language,
        cardCount: validated.narrative.cards.length,
        spreadId: (validated.narrative.spread as { spreadId?: string }).spreadId,
        displayName: e.displayName ?? null,
        memoryEntryCount: e.memoryEntryCount ?? 0,
        outboundBodySchemaOk: true,
        resolvedProviderModel: SOL_MODEL,
        narrativeReasoningEffort: 'none',
      });
    } catch (err) {
      precall.push({
        manifestId: e.manifestId,
        ok: false,
        failure: sanitizeFailure(err),
      });
    }
  }
  const precallFail = precall.filter((p) => !p.ok);
  if (precallFail.length > 0) {
    writeFileSync(
      RESULTS,
      JSON.stringify(
        {
          qaRunHead: QA_RUN_HEAD,
          manifestVersion: 2,
          resultContractVersion: 2,
          providerSchemaName: 'oracly_tarot_narrative_v2',
          modelMetadata: modelMeta,
          modelDiscovery: discovery,
          precallValidation: 'FAIL',
          schemaCompatibilityPrecall: 'PASS',
          outboundBodyPrecall: 'FAIL',
          precall,
          authorizedCalls: CAP,
          usedCalls: 0,
          remaining: CAP,
          calls: [],
        },
        null,
        2,
      ),
    );
    console.error('PRECALL VALIDATION FAIL — real provider calls: 0');
    console.error(JSON.stringify(precallFail, null, 2));
    process.exit(5);
  }
  console.log('PRECALL VALIDATION: PASS (6/6)');

  const ledger: Ledger = { authorized: CAP, used: 0, remaining: CAP };
  let lastProviderRequestId: string | null = null;
  let stopReason: string | null = null;

  const observingFetch: OpenAiFetch = async (url, init) => {
    const res = await fetch(url, init);
    lastProviderRequestId =
      res.headers.get('x-request-id') ??
      res.headers.get('request-id') ??
      null;
    try {
      const clone = res.clone();
      const body = (await clone.json()) as { id?: string };
      if (typeof body.id === 'string' && body.id.length > 0) {
        lastProviderRequestId = body.id.slice(0, 128);
      }
    } catch {
      /* ignore */
    }
    return res;
  };

  const service = new AiProxyService(config, observingFetch);
  const calls: Array<Record<string, unknown>> = [];

  for (let i = 0; i < dump.entries.length; i++) {
    if (stopReason) break;
    if (ledger.used >= CAP) {
      console.error('CAP reached — refusing further calls');
      break;
    }
    const e = dump.entries[i]!;
    ledger.used += 1;
    ledger.remaining = CAP - ledger.used;
    const callNumber = ledger.used;
    console.log(
      `CALL #${callNumber} ${e.manifestId} (remaining=${ledger.remaining}) model=${SOL_MODEL}`,
    );

    // Experiment invalid if resolver drifts mid-run.
    const liveMeta = narrativeModelQaMetadata(config);
    if (liveMeta.resolvedNarrativeModel !== SOL_MODEL) {
      stopReason = 'resolved_model_drift';
      console.error('RESOLVED MODEL DRIFT — STOP');
      break;
    }

    const validated = validateNarrativeTarotPayload(e.wirePayload);
    lastProviderRequestId = null;
    const t0 = Date.now();
    let transportStatus = 'ok';
    let backendValid = false;
    let backendQualityRejection: string | null = null;
    let httpStatus: number | null = null;
    let structuredResult: unknown = null;
    let typedFailure: Record<string, unknown> | null = null;
    let canaryCompatPass: boolean | null = callNumber === 1 ? null : null;

    try {
      const result = await service.handle(validated, undefined, {
        identity: 'qa-6e8-sol-shadow',
        parentKey: `qa-6e8-sol:${e.manifestId}`,
      });
      const latencyMs = Date.now() - t0;
      if (
        result &&
        typeof result === 'object' &&
        'summary' in result &&
        'cardReadings' in result &&
        'contractVersion' in result
      ) {
        const cv = (result as { contractVersion?: unknown }).contractVersion;
        if (cv !== 2) {
          transportStatus = 'wrong_contract_version';
          typedFailure = { type: 'wrong_contract_version', contractVersion: cv };
        } else {
          backendValid = true;
          structuredResult = result;
          if (callNumber === 1) {
            canaryCompatPass = true;
            console.log(
              'CALL #1 COMPATIBILITY CANARY: PASS — CHAT COMPLETIONS + GPT-5.6-SOL + STRICT STRUCTURED OUTPUTS + REASONING_EFFORT NONE ACCEPTED',
            );
          }
        }
      } else {
        transportStatus = 'unexpected_shape';
        typedFailure = {
          type: 'unexpected_shape',
          keys: Object.keys(result ?? {}),
        };
      }
      calls.push({
        manifestId: e.manifestId,
        callNumber,
        languageCode: e.languageCode,
        spreadId: e.resolvedSpreadId,
        cardCount: e.cardCount,
        displayName: e.displayName ?? null,
        memoryEntryCount: e.memoryEntryCount ?? 0,
        memorySummariesForQa: e.memorySummariesForQa ?? [],
        resolvedProviderModel: SOL_MODEL,
        narrativeReasoningEffort: 'none',
        transportStatus,
        latencyMs,
        httpStatus,
        providerRequestId: lastProviderRequestId,
        sanitizedProviderMessage: null,
        backendValid,
        backendQualityRejection,
        structuredResult,
        typedFailure,
        canaryCompatPass,
      });
      console.log(
        `  -> transport=${transportStatus} backendValid=${backendValid} latencyMs=${latencyMs} id=${lastProviderRequestId ?? 'n/a'}`,
      );
    } catch (err) {
      const latencyMs = Date.now() - t0;
      const failure = sanitizeFailure(err);
      httpStatus =
        typeof failure.httpStatus === 'number'
          ? failure.httpStatus
          : typeof (failure.details as { httpStatus?: number } | undefined)
                ?.httpStatus === 'number'
            ? (failure.details as { httpStatus: number }).httpStatus
            : null;
      const providerMessage =
        typeof (failure.details as { providerMessage?: string } | undefined)
          ?.providerMessage === 'string'
          ? (failure.details as { providerMessage: string }).providerMessage
          : null;
      if (err instanceof ProxyError && err.code === 'invalid_response') {
        transportStatus = 'provider_responded_invalid_response';
        backendQualityRejection = 'invalid_response';
      } else if (err instanceof ProxyError && err.code === 'invalid_request') {
        transportStatus = 'invalid_request';
      } else {
        transportStatus = 'failure';
      }
      typedFailure = failure;
      calls.push({
        manifestId: e.manifestId,
        callNumber,
        languageCode: e.languageCode,
        spreadId: e.resolvedSpreadId,
        cardCount: e.cardCount,
        displayName: e.displayName ?? null,
        memoryEntryCount: e.memoryEntryCount ?? 0,
        memorySummariesForQa: e.memorySummariesForQa ?? [],
        resolvedProviderModel: SOL_MODEL,
        narrativeReasoningEffort: 'none',
        transportStatus,
        latencyMs,
        httpStatus,
        providerRequestId: lastProviderRequestId,
        sanitizedProviderMessage: providerMessage,
        backendValid: false,
        backendQualityRejection,
        structuredResult: null,
        typedFailure,
        canaryCompatPass: callNumber === 1 ? false : null,
      });
      console.log(`  -> FAILURE ${JSON.stringify(typedFailure)}`);

      if (callNumber === 1) {
        if (isCompatBlocker(err, failure)) {
          stopReason = 'compatibility_blocker';
          console.error(
            'CALL #1 COMPATIBILITY CANARY FAIL — STOP. calls #2-#6 NOT executed.',
          );
        } else if (isTransient5xx(failure)) {
          stopReason = 'transient_5xx';
          console.error(
            'CALL #1 TRANSIENT 5XX — STOP. calls #2-#6 NOT executed.',
          );
        } else {
          // Non-compat quality rejection on #1 still allows continuing? Spec says
          // STOP only for compat/config or 5xx. invalid_response (prose quality)
          // is a quality sample failure — record and continue per "If SUCCESS" vs
          // compat failure. For invalid_response from quality guard, continue.
          if (backendQualityRejection === 'invalid_response') {
            console.log(
              'CALL #1 quality rejection (not compat) — continue experiment',
            );
          } else {
            stopReason = 'call1_unexpected_failure';
            console.error('CALL #1 unexpected failure — STOP');
          }
        }
      }
    }
  }

  const out = {
    qaRunHead: QA_RUN_HEAD,
    manifestVersion: 2,
    resultContractVersion: 2,
    providerSchemaName: 'oracly_tarot_narrative_v2',
    modelMetadata: modelMeta,
    modelDiscovery: discovery,
    precallValidation: 'PASS',
    schemaCompatibilityPrecall: 'PASS',
    outboundBodyPrecall: 'PASS',
    uniqueItemsInProviderSchema: false,
    sixOutboundBodiesOfflinePass: 6,
    precall,
    authorizedCalls: CAP,
    usedCalls: ledger.used,
    remaining: ledger.remaining,
    callCapExceeded: ledger.used > CAP,
    autoRetries: 0,
    stopReason,
    call1CompatibilityCanary:
      calls[0]?.canaryCompatPass === true
        ? 'PASS'
        : calls[0]?.canaryCompatPass === false
          ? 'FAIL'
          : 'n/a',
    billingTouched: false,
    persistenceWrites: 0,
    paidUserDualCalls: 0,
    gemDebits: 0,
    historyWrites: 0,
    journalWrites: 0,
    liveCacheWrites: 0,
    productionCodeModifiedDuringRun: false,
    calls,
  };
  writeFileSync(RESULTS, JSON.stringify(out, null, 2));
  console.log(`DONE used=${ledger.used} remaining=${ledger.remaining}`);
  console.log(`stopReason=${stopReason ?? 'none'}`);
  console.log(`Wrote ${RESULTS}`);
}

main().catch((err) => {
  console.error('QA runner crashed:', sanitizeFailure(err));
  process.exit(1);
});
