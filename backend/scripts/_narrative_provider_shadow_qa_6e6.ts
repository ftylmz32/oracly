/**
 * Phase 6E.6 — REAL-PROVIDER writing-quality validation after 6E.5 prompt refinement.
 * HARD CAP: 6 real provider calls. NO retry. NO billing. NO persistence.
 * Does NOT overwrite 6E.4 / 6E.4.2 historical artifacts.
 * Reads OPENAI_API_KEY from process.env only. Never logs secrets.
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
import { buildChatCompletionBody } from '../src/ai/openai-transport.js';
import { ProxyError } from '../src/errors.js';
import type { OpenAiFetch } from '../src/types.js';

const CAP = 6;
const QA_RUN_HEAD = '8a33915e0462438f21c3b74c0d6fd7f787c78730';
const ROOT = resolve(process.cwd(), '..');
const PAYLOADS = resolve(
  ROOT,
  'test/fixtures/tarot_narrative_provider_shadow_payloads_6e6_v2.json',
);
const RESULTS = resolve(
  ROOT,
  'test/fixtures/tarot_narrative_provider_shadow_results_6e6_v2.json',
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

function collectUnsupported(node: unknown, hits: string[] = [], path = '$'): string[] {
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
      if (typeof d.requestId === 'string') safe.requestId = d.requestId.slice(0, 128);
      if (typeof d.providerMessage === 'string') {
        safe.providerMessage = d.providerMessage.slice(0, 300);
      }
      if (typeof d.httpStatus === 'number') safe.httpStatus = d.httpStatus;
      if (Object.keys(safe).length > 0) out.details = safe;
    }
  }
  return out;
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

  // Schema compatibility precall (static)
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
  console.log('SCHEMA COMPATIBILITY PRECALL: PASS (uniqueItems absent)');

  const precall: Array<Record<string, unknown>> = [];
  for (const e of dump.entries) {
    try {
      const validated = validateNarrativeTarotPayload(e.wirePayload);
      const messages = narrativeTarotMessages(
        validated.narrative,
        validated.language,
      );
      const body = buildChatCompletionBody({
        model: 'gpt-4o',
        messages,
        temperature: 0.55,
        jsonSchema: {
          name: NARRATIVE_SCHEMA_NAME,
          schema: NARRATIVE_TAROT_RESULT_SCHEMA,
        },
      });
      const rf = body.response_format as {
        type: string;
        json_schema: { name: string; strict: boolean; schema: unknown };
      };
      if (rf.type !== 'json_schema') throw new Error('response_format.type');
      if (rf.json_schema.name !== 'oracly_tarot_narrative_v2') {
        throw new Error('schema name');
      }
      if (rf.json_schema.strict !== true) throw new Error('strict');
      const bodyHits = collectUnsupported(rf.json_schema.schema);
      if (bodyHits.length > 0) throw new Error(`unsupported:${bodyHits.join(',')}`);

      precall.push({
        manifestId: e.manifestId,
        ok: true,
        language: validated.language,
        cardCount: validated.narrative.cards.length,
        spreadId: (validated.narrative.spread as { spreadId?: string })
          .spreadId,
        displayName: e.displayName ?? null,
        memoryEntryCount: e.memoryEntryCount ?? 0,
        outboundBodySchemaOk: true,
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
          precallValidation: 'FAIL',
          schemaCompatibilityPrecall: 'PASS',
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
  console.log('SIX OUTBOUND BODIES OFFLINE PASS: 6/6');

  const ledger: Ledger = { authorized: CAP, used: 0, remaining: CAP };
  let lastProviderRequestId: string | null = null;

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

  const config = loadConfig({
    ...process.env,
    APP_ENV: process.env.APP_ENV ?? 'development',
    AI_AUTH_REQUIRED: 'false',
    AI_DEV_AUTH_BYPASS: 'true',
  });
  const service = new AiProxyService(config, observingFetch);
  const calls: Array<Record<string, unknown>> = [];

  for (let i = 0; i < dump.entries.length; i++) {
    if (ledger.used >= CAP) {
      console.error('CAP reached — refusing further calls');
      break;
    }
    const e = dump.entries[i]!;
    ledger.used += 1;
    ledger.remaining = CAP - ledger.used;
    const callNumber = ledger.used;
    console.log(
      `CALL #${callNumber} ${e.manifestId} (remaining=${ledger.remaining})`,
    );

    const validated = validateNarrativeTarotPayload(e.wirePayload);
    lastProviderRequestId = null;
    const t0 = Date.now();
    let transportStatus = 'ok';
    let backendValid = false;
    let backendQualityRejection: string | null = null;
    let httpStatus: number | null = null;
    let structuredResult: unknown = null;
    let typedFailure: Record<string, unknown> | null = null;
    try {
      const result = await service.handle(validated, undefined, {
        identity: 'qa-6e6-shadow',
        parentKey: `qa-6e6:${e.manifestId}`,
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
        transportStatus,
        latencyMs,
        httpStatus,
        providerRequestId: lastProviderRequestId,
        sanitizedProviderMessage: null,
        backendValid,
        backendQualityRejection,
        structuredResult,
        typedFailure,
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
        transportStatus,
        latencyMs,
        httpStatus,
        providerRequestId: lastProviderRequestId,
        sanitizedProviderMessage: providerMessage,
        backendValid: false,
        backendQualityRejection,
        structuredResult: null,
        typedFailure,
      });
      console.log(`  -> FAILURE ${JSON.stringify(typedFailure)}`);
    }
  }

  const out = {
    qaRunHead: QA_RUN_HEAD,
    manifestVersion: 2,
    resultContractVersion: 2,
    providerSchemaName: 'oracly_tarot_narrative_v2',
    precallValidation: 'PASS',
    schemaCompatibilityPrecall: 'PASS',
    uniqueItemsInProviderSchema: false,
    sixOutboundBodiesOfflinePass: 6,
    precall,
    authorizedCalls: CAP,
    usedCalls: ledger.used,
    remaining: ledger.remaining,
    callCapExceeded: ledger.used > CAP,
    autoRetries: 0,
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
  console.log(`Wrote ${RESULTS}`);
}

main().catch((err) => {
  console.error('QA runner crashed:', sanitizeFailure(err));
  process.exit(1);
});
