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
 *   - at most 2 logical reading attempts (an attempt starts with its
 *     observer request) and 6 upstream requests in total;
 *   - per attempt: at most 1 observer and 2 writer requests; a writer
 *     request with no open attempt is refused;
 *   - an ambiguous outcome (network error / timeout / abort — the request
 *     may already be billed) SEALS the guard: no automatic retry, no further
 *     requests of any kind;
 *   - `seal()` at test end: no background / continuing requests afterwards.
 *
 * Records are metadata only (kind, model, image count, status, usage token
 * counts, duration) — never the Authorization header, never request or
 * response content.
 */

export const OFFICIAL_OPENAI_BASE_URL = 'https://api.openai.com/v1';

export type LiveRequestKind = 'observer' | 'writer';

export type LiveRequestRecord = {
  index: number;
  attempt: number;
  kind: LiveRequestKind;
  model: string | null;
  imageCount: number;
  status: number | null;
  outcome: 'ok' | 'http_error' | 'ambiguous';
  usage: { promptTokens?: number; completionTokens?: number; totalTokens?: number } | null;
  durationMs: number;
};

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
}): LiveProviderGuard {
  const maxTotal = input.maxTotal ?? 6;
  const maxAttempts = input.maxAttempts ?? 2;
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
    if (format?.json_schema?.name === 'coffee_v3_observation') kind = 'observer';
    else if (format?.type === 'json_object') kind = 'writer';
    else return refuse('request_kind_not_allowed');

    if (kind === 'observer') {
      if (attempt >= maxAttempts) refuse('attempt_budget_exhausted');
      attempt += 1;
      observerInAttempt = 0;
      writerInAttempt = 0;
      if (observerInAttempt >= maxObserver) refuse('observer_budget_exhausted');
      observerInAttempt += 1;
    } else {
      if (attempt === 0 || observerInAttempt === 0) refuse('writer_without_attempt');
      if (writerInAttempt >= maxWriter) refuse('writer_budget_exhausted');
      writerInAttempt += 1;
    }

    const imageCount = (Array.isArray(body.messages) ? body.messages : [])
      .flatMap((m) => {
        const content = (m as { content?: unknown }).content;
        return Array.isArray(content) ? content : [];
      })
      .filter((part) => (part as { type?: unknown }).type === 'image_url').length;
    const record: LiveRequestRecord = {
      index: records.length + 1,
      attempt,
      kind,
      model: typeof body.model === 'string' ? body.model : null,
      imageCount,
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
        const usage = ((await response.clone().json()) as { usage?: Record<string, number> }).usage;
        if (usage) {
          record.usage = {
            promptTokens: usage.prompt_tokens,
            completionTokens: usage.completion_tokens,
            totalTokens: usage.total_tokens,
          };
        }
      } catch {
        // Usage is optional evidence; the transport still reads the body.
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
    refusals: () => [...refusals],
    attempts: () => attempt,
    seal: (why = 'test_finished') => {
      sealedReason ??= why;
    },
    sealed: () => sealedReason,
  };
}
