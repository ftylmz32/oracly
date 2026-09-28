/**
 * Dream Phase 4C.2 — what the current official OpenAI documentation says
 * about the three candidates on Chat Completions (read 2026-09-28), and
 * the assumptions the comparison rests on.
 */
export const COMPATIBILITY = {
  checkedAt: '2026-09-28',
  endpoint: 'POST /v1/chat/completions for all three candidates (no Responses API migration)',
  sources: [
    'https://developers.openai.com/api/docs/guides/latest-model',
    'https://developers.openai.com/api/docs/models/gpt-6-sol',
    'https://developers.openai.com/api/docs/models/gpt-6-astra',
    'https://developers.openai.com/api/docs/models/gpt-4o',
    'https://developers.openai.com/api/docs/guides/structured-outputs',
    'https://developers.openai.com/api/docs/guides/prompt-caching',
  ],
  documented: [
    'gpt-4o, gpt-6-sol and gpt-6-astra each list v1/chat/completions as a supported endpoint.',
    'Chat Completions takes `reasoning_effort` (Responses uses `reasoning.effort`).',
    'GPT-6 Astra does not support reasoning effort `none`; Sol does. Medium is supported by both.',
    'When reasoning effort is not `none`: remove temperature, top_p and top_logprobs; on Chat Completions also remove logprobs.',
    'Tool calling on GPT-6 requires Responses (Sol: Chat Completions only with effort none). This writer uses no tools.',
    'JSON mode is enabled on Chat Completions with response_format {"type":"json_object"}; the prompt must mention JSON (the Dream system prompt does).',
    'GPT-5.6 and later bill cache writes at 1.25x input and cache reads at 0.1x input; usage reports cached_tokens and cache_write_tokens.',
  ],
  assumptions: [
    'JSON mode is listed for gpt-4o and "compatible GPT-5 models"; GPT-6 keeps the GPT-5.6 API capabilities, so json_object is assumed accepted. A 400 is recorded as PARAMETER_ERROR, never retried or changed.',
    'reasoning_tokens are billed inside completion_tokens at the output rate.',
    'Pricing is the Standard processing tier (no service_tier sent). A non-standard tier in the response makes cost null.',
    'A GPT-6 response that does not report cache_write_tokens for a cacheable (>=1024-token) prompt has cost null, never a guess.',
    'The production transport timeout (OPENAI_TIMEOUT_SECONDS from the deploy script) applies to every candidate; a timeout is an infrastructure outcome.',
  ],
};
