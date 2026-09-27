/**
 * Dream Phase 4C — a counting, capturing wrapper around the fetch the real
 * `OpenAiTransport` uses. It never retries, never reads or stores request
 * headers, and refuses any call past the hard cap before it reaches the
 * network. Only the non-secret request parameters and the provider's
 * message content are captured.
 */
import { createHash } from 'node:crypto';
import type { OpenAiFetch } from '../../src/types.js';

export type ProviderCapture = {
  endpoint: string;
  status: number | null;
  latencyMs: number;
  request: {
    model: unknown;
    temperature: unknown;
    reasoningEffort: unknown;
    responseFormat: unknown;
    maxTokens: unknown;
    messageCount: number;
    promptChars: number;
    promptSha256: string;
  };
  providerModel: string | null;
  usage: Record<string, unknown> | null;
  finishReason: string | null;
  rawText: string | null;
  networkError: string | null;
};

export class Phase4cBudgetExceeded extends Error {}

export type BudgetFetch = {
  fetch: OpenAiFetch;
  calls: () => number;
  /** The capture of the most recent call, cleared on read. */
  take: () => ProviderCapture | null;
};

function requestSummary(body: Record<string, unknown>): ProviderCapture['request'] {
  const messages = Array.isArray(body.messages) ? body.messages : [];
  const prompt = JSON.stringify(messages);
  return {
    model: body.model ?? null,
    temperature: body.temperature ?? null,
    reasoningEffort: body.reasoning_effort ?? null,
    responseFormat: body.response_format ?? null,
    maxTokens: body.max_tokens ?? body.max_completion_tokens ?? null,
    messageCount: messages.length,
    promptChars: prompt.length,
    promptSha256: createHash('sha256').update(prompt).digest('hex'),
  };
}

async function responseSummary(res: Response) {
  try {
    const body = (await res.clone().json()) as {
      model?: unknown;
      usage?: Record<string, unknown>;
      choices?: Array<{ finish_reason?: unknown; message?: { content?: unknown } }>;
    };
    const choice = body.choices?.[0];
    const content = choice?.message?.content;
    return {
      providerModel: typeof body.model === 'string' ? body.model : null,
      usage: body.usage ?? null,
      finishReason: typeof choice?.finish_reason === 'string' ? choice.finish_reason : null,
      rawText: typeof content === 'string' ? content : null,
    };
  } catch {
    return { providerModel: null, usage: null, finishReason: null, rawText: null };
  }
}

export function budgetFetch(inner: OpenAiFetch, cap: number): BudgetFetch {
  let calls = 0;
  let last: ProviderCapture | null = null;
  const wrapped: OpenAiFetch = async (input, init) => {
    if (calls >= cap) throw new Phase4cBudgetExceeded(`hard cap ${cap} reached`);
    calls++;
    const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url;
    const request = requestSummary(JSON.parse(String(init?.body ?? '{}')));
    const started = performance.now();
    const base = { endpoint: url.split('?')[0], request };
    try {
      const res = await inner(input, init);
      last = {
        ...base,
        status: res.status,
        latencyMs: Math.round(performance.now() - started),
        ...(await responseSummary(res)),
        networkError: null,
      };
      return res;
    } catch (error) {
      last = {
        ...base,
        status: null,
        latencyMs: Math.round(performance.now() - started),
        providerModel: null,
        usage: null,
        finishReason: null,
        rawText: null,
        networkError: error instanceof Error ? error.name : 'unknown',
      };
      throw error;
    }
  };
  return {
    fetch: wrapped,
    calls: () => calls,
    take: () => {
      const capture = last;
      last = null;
      return capture;
    },
  };
}
