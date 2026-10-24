/**
 * Slice 6 — independent, fail-closed request guard for the controlled
 * real-provider acceptance run. Wraps the REAL fetch at the final outbound
 * HTTP boundary used by `OpenAiTransport`. Test infrastructure only.
 *
 * Enforced BEFORE any byte leaves the process:
 *   - only `POST {https://api.openai.com/v1}/chat/completions` (the official
 *     endpoint; photographs never go to any other host);
 *   - only Coffee V3 requests: the `coffee_v3_observation` observer and the
 *     JSON-mode writer — anything else is refused;
 *   - the observer request carries EXACTLY three images (two cup views + one
 *     saucer; never a fourth) and a writer request carries none;
 *   - at most 2 logical reading attempts (an attempt starts with its
 *     observer request) and 6 upstream requests in total;
 *   - per attempt: at most 1 observer and 2 writer requests; a writer
 *     request with no open attempt is refused;
 *   - an ambiguous outcome (network error / timeout / abort — the request
 *     may already be billed) SEALS the guard: no automatic retry, no further
 *     requests of any kind;
 *   - `seal()` at test end: no background / continuing requests afterwards.
 *
 * Records are metadata only (kind, model, image count, system-prompt sha256,
 * status, usage token counts, duration) — never the Authorization header,
 * never request or response content.
 */
import { createHash } from 'node:crypto';
import { extractMessageContent } from '../../src/ai/extract-message-content.js';

export const OFFICIAL_OPENAI_BASE_URL = 'https://api.openai.com/v1';

/** sha256 of the request's system message (string content), or null. */
export function systemPromptSha256(body: Record<string, unknown>): string | null {
  const first = Array.isArray(body.messages) ? (body.messages[0] as { role?: unknown; content?: unknown } | undefined) : undefined;
  return first?.role === 'system' && typeof first.content === 'string'
    ? createHash('sha256').update(first.content, 'utf8').digest('hex')
    : null;
}

/** The product contract: two genuine cup photos + one saucer photo, in ONE observer request. */
export const COFFEE_V3_LIVE_IMAGE_COUNT = 3;

export type LiveRequestKind = 'observer' | 'writer' | 'direct';

export type LiveRequestRecord = {
  index: number;
  attempt: number;
  kind: LiveRequestKind;
  model: string | null;
  imageCount: number;
  /** sha256 of the system prompt (proves which writer / observer contract ran; never the content). */
  systemPromptSha256: string | null;
  status: number | null;
  outcome: 'ok' | 'http_error' | 'ambiguous';
  usage: { promptTokens?: number; completionTokens?: number; totalTokens?: number } | null;
  durationMs: number;
};

/**
 * The text a writer request returned, exactly as the transport hands it to
 * the pipeline (same extraction, so `outputSha256` equals the pipeline's
 * rejection hash). Kept in memory for the LOCAL evidence file only (outside
 * the repository); never a header, key or image.
 */
export type LiveWriterOutput = { index: number; attempt: number; outputSha256: string; text: string };

export class LiveProviderBudgetError extends Error {
  constructor(readonly reason: string) {
    super(`live_provider_refused:${reason}`);
    this.name = 'LiveProviderBudgetError';
  }
}

type Fetch = (input: string | URL | Request, init?: RequestInit) => Promise<Response>;

export type LiveProviderGuard = {
  fetch: Fetch;
  records: () => LiveRequestRecord[];
  writerOutputs: () => LiveWriterOutput[];
  refusals: () => string[];
  attempts: () => number;
  seal: (why?: string) => void;
  sealed: () => string | null;
};

export function createLiveProviderGuard(input: {
  realFetch: Fetch;
  baseUrl: string;
  maxTotal?: number;
  maxAttempts?: number;
  maxObserverPerAttempt?: number;
  maxWriterPerAttempt?: number;
  /**
   * Writer-only replay of a recorded real observation: every observer request
   * is refused before anything is sent (no image ever leaves), exactly one
   * attempt, at most two writer requests in total.
   */
  writerOnly?: boolean;
  /** V3D: one operation, at most two three-image direct samples. */
  directOnly?: boolean;
}): LiveProviderGuard {
  const writerOnly = input.writerOnly === true;
  const directOnly = input.directOnly === true;
  if (writerOnly && directOnly) throw new LiveProviderBudgetError('incompatible_modes');
  const maxTotal = writerOnly || directOnly ? Math.min(input.maxTotal ?? 2, 2) : input.maxTotal ?? 6;
  const maxAttempts = writerOnly || directOnly ? 1 : input.maxAttempts ?? 2;
  const maxObserver = input.maxObserverPerAttempt ?? 1;
  const maxWriter = input.maxWriterPerAttempt ?? 2;
  if (input.baseUrl !== OFFICIAL_OPENAI_BASE_URL) {
    throw new LiveProviderBudgetError('non_official_base_url');
  }
  if (maxTotal > 6 || maxAttempts > 2 || maxObserver > 1 || maxWriter > 2) {
    throw new LiveProviderBudgetError('limits_above_authorization');
  }
  const endpoint = `${OFFICIAL_OPENAI_BASE_URL}/chat/completions`;
  const records: LiveRequestRecord[] = [];
  const writerOutputs: LiveWriterOutput[] = [];
  const refusals: string[] = [];
  let attempt = 0;
  let observerInAttempt = 0;
  let writerInAttempt = 0;
  let sealedReason: string | null = null;
  let inFlight = false;

  const refuse = (reason: string): never => {
    refusals.push(reason);
    throw new LiveProviderBudgetError(reason);
  };

  const guarded: Fetch = async (url, init) => {
    if (sealedReason) refuse(`sealed:${sealedReason}`);
    const href = typeof url === 'string' ? url : url instanceof URL ? url.href : url.url;
    if (href !== endpoint) refuse('endpoint_not_allowed');
    if ((init?.method ?? 'GET').toUpperCase() !== 'POST') refuse('method_not_allowed');
    if (inFlight) refuse('parallel_request');
    if (records.length >= maxTotal) refuse('total_budget_exhausted');

    let body: Record<string, unknown>;
    try {
      body = JSON.parse(String(init?.body ?? '')) as Record<string, unknown>;
    } catch {
      return refuse('unparseable_body');
    }
    const format = body.response_format as { type?: string; json_schema?: { name?: string } } | undefined;
    let kind: LiveRequestKind;
    if (directOnly && !format) kind = 'direct';
    else if (format?.json_schema?.name === 'coffee_v3_observation') kind = 'observer';
    else if (format?.type === 'json_object') kind = 'writer';
    else return refuse('request_kind_not_allowed');
    if (writerOnly && kind === 'observer') refuse('observer_not_allowed_writer_only');
    if (directOnly && kind !== 'direct') refuse('non_direct_request');

    const imageCount = (Array.isArray(body.messages) ? body.messages : [])
      .flatMap((m) => {
        const content = (m as { content?: unknown }).content;
        return Array.isArray(content) ? content : [];
      })
      .filter((part) => (part as { type?: unknown }).type === 'image_url').length;
    if (kind === 'observer' && imageCount !== COFFEE_V3_LIVE_IMAGE_COUNT) refuse('observer_image_count');
    if (kind === 'writer' && imageCount !== 0) refuse('writer_with_images');
    if (kind === 'direct' && imageCount !== COFFEE_V3_LIVE_IMAGE_COUNT) refuse('direct_image_count');

    if (kind === 'direct') {
      if (attempt === 0) attempt = 1;
      if (writerInAttempt >= maxWriter) refuse('direct_budget_exhausted');
      writerInAttempt += 1;
    } else if (kind === 'observer') {
      if (attempt >= maxAttempts) refuse('attempt_budget_exhausted');
      attempt += 1;
      observerInAttempt = 0;
      writerInAttempt = 0;
      if (observerInAttempt >= maxObserver) refuse('observer_budget_exhausted');
      observerInAttempt += 1;
    } else {
      // Writer-only: the first writer request opens the single attempt (the observation is replayed).
      if (writerOnly && attempt === 0) {
        attempt = 1;
        writerInAttempt = 0;
      } else if (attempt === 0 || (!writerOnly && observerInAttempt === 0)) refuse('writer_without_attempt');
      if (writerInAttempt >= maxWriter) refuse('writer_budget_exhausted');
      writerInAttempt += 1;
    }

    const record: LiveRequestRecord = {
      index: records.length + 1,
      attempt,
      kind,
      model: typeof body.model === 'string' ? body.model : null,
      imageCount,
      systemPromptSha256: systemPromptSha256(body),
      status: null,
      outcome: 'ambiguous',
      usage: null,
      durationMs: 0,
    };
    records.push(record); // counted BEFORE sending: a sent request is spent
    const started = Date.now();
    inFlight = true;
    try {
      const response = await input.realFetch(href, init);
      record.status = response.status;
      record.outcome = response.ok ? 'ok' : 'http_error';
      try {
        const json = (await response.clone().json()) as {
          usage?: Record<string, number>;
          choices?: Array<{ message?: { content?: unknown } }>;
        };
        const usage = json.usage;
        if (usage) {
          record.usage = {
            promptTokens: usage.prompt_tokens,
            completionTokens: usage.completion_tokens,
            totalTokens: usage.total_tokens,
          };
        }
        const text = (kind === 'writer' || kind === 'direct') && response.ok ? extractMessageContent(json.choices?.[0]?.message?.content) : '';
        if (text) {
          writerOutputs.push({
            index: record.index,
            attempt: record.attempt,
            outputSha256: createHash('sha256').update(text, 'utf8').digest('hex'),
            text,
          });
        }
      } catch {
        // Usage / text are optional evidence; the transport still reads the body.
      }
      return response;
    } catch (error) {
      // Possibly billed; never retried automatically. Stop everything.
      record.outcome = 'ambiguous';
      sealedReason = 'ambiguous_upstream_outcome';
      throw error;
    } finally {
      record.durationMs = Date.now() - started;
      inFlight = false;
    }
  };

  return {
    fetch: guarded,
    records: () => records.map((r) => ({ ...r, usage: r.usage ? { ...r.usage } : null })),
    writerOutputs: () => writerOutputs.map((o) => ({ ...o })),
    refusals: () => [...refusals],
    attempts: () => attempt,
    seal: (why = 'test_finished') => {
      sealedReason ??= why;
    },
    sealed: () => sealedReason,
  };
}
