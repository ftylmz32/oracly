/**
 * Dream Phase 4C.2 — the three candidate models on the frozen 4C.1 writer,
 * and their documented Standard-tier text pricing (per 1M tokens, OpenAI
 * model pages, read 2026-09-28). Only the model and its reasoning control
 * vary; prompt, JSON mode, gates and transport are production.
 */
import type { OpenAiCompleteOptions } from '../../src/ai/openai-transport.js';

export type CandidateId = 'gpt-4o' | 'gpt-6-sol' | 'gpt-6-astra';

export type Candidate = {
  id: CandidateId;
  model: string;
  /** Undefined → production default body (temperature 0.6, no reasoning). */
  reasoningEffort?: 'medium';
  pricing: {
    source: string;
    input: number;
    cachedInput: number;
    output: number;
    /** GPT-5.6 and later bill cache writes at 1.25× input. */
    cacheWriteMultiplier: number | null;
  };
};

export const CANDIDATES: readonly Candidate[] = [
  {
    id: 'gpt-4o',
    model: 'gpt-4o',
    pricing: {
      source: 'https://developers.openai.com/api/docs/models/gpt-4o',
      input: 2.5,
      cachedInput: 1.25,
      output: 10,
      cacheWriteMultiplier: null,
    },
  },
  {
    id: 'gpt-6-sol',
    model: 'gpt-6-sol',
    reasoningEffort: 'medium',
    pricing: {
      source: 'https://developers.openai.com/api/docs/models/gpt-6-sol',
      input: 2,
      cachedInput: 0.2,
      output: 10,
      cacheWriteMultiplier: 1.25,
    },
  },
  {
    id: 'gpt-6-astra',
    model: 'gpt-6-astra',
    reasoningEffort: 'medium',
    pricing: {
      source: 'https://developers.openai.com/api/docs/models/gpt-6-astra',
      input: 10,
      cachedInput: 1,
      output: 50,
      cacheWriteMultiplier: 1.25,
    },
  },
];

export const candidate = (id: CandidateId): Candidate => CANDIDATES.find((c) => c.id === id)!;

/** The production Dream call (`AiProxyService.dream`), model/effort swapped. */
export function completeOptions(c: Candidate, messages: OpenAiCompleteOptions['messages']): OpenAiCompleteOptions {
  return {
    model: c.model,
    jsonMode: true,
    messages,
    ...(c.reasoningEffort ? { reasoningEffort: c.reasoningEffort } : {}),
  };
}

type Usage = {
  prompt_tokens?: unknown;
  completion_tokens?: unknown;
  prompt_tokens_details?: { cached_tokens?: unknown; cache_write_tokens?: unknown } | null;
};

const LONG_CONTEXT = 272_000;
const MIN_CACHEABLE = 1024;
const STANDARD_TIERS = new Set(['default', 'standard']);
const num = (v: unknown) => (typeof v === 'number' && Number.isFinite(v) ? v : null);

/**
 * Deterministic cost from reported usage and documented pricing, or null
 * with the reason it is not calculable. Reasoning tokens are billed inside
 * `completion_tokens`. Never estimates a field the provider did not report.
 */
export function estimateCostUsd(
  c: Candidate,
  usage: Usage | null,
  serviceTier: string | null,
): { usd: number | null; reason: string | null } {
  if (!usage) return { usd: null, reason: 'usage_not_reported' };
  if (serviceTier !== null && !STANDARD_TIERS.has(serviceTier)) return { usd: null, reason: `service_tier_${serviceTier}` };
  const prompt = num(usage.prompt_tokens);
  const completion = num(usage.completion_tokens);
  if (prompt === null || completion === null) return { usd: null, reason: 'token_counts_not_reported' };
  if (prompt > LONG_CONTEXT) return { usd: null, reason: 'long_context_pricing' };
  const cached = num(usage.prompt_tokens_details?.cached_tokens);
  if (cached === null) return { usd: null, reason: 'cached_tokens_not_reported' };
  let written = 0;
  if (c.pricing.cacheWriteMultiplier !== null) {
    const reported = num(usage.prompt_tokens_details?.cache_write_tokens);
    if (reported === null && prompt >= MIN_CACHEABLE) return { usd: null, reason: 'cache_write_tokens_not_reported' };
    written = reported ?? 0;
  }
  const p = c.pricing;
  const input = (prompt - cached - written) * p.input + cached * p.cachedInput + written * p.input * (p.cacheWriteMultiplier ?? 0);
  return { usd: Math.round(((input + completion * p.output) / 1e6) * 1e6) / 1e6, reason: null };
}
