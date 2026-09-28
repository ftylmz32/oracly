/**
 * Dream Phase 4C.2 — `AiProxyService.dream`, step for step, with the
 * candidate model and reasoning control handed to the production
 * `OpenAiTransport`. Everything else is the production code: input gate,
 * sensitive-memory drop, `dreamMessages`, JSON mode, `parseDreamData`, raw
 * output safety and `acceptDreamData`. The production model allowlist is
 * bypassed here only; production selection is unchanged.
 */
import type { AppLanguage } from '../../src/ai/app-language.js';
import { acceptDreamData } from '../../src/ai/dream-acceptance.js';
import type { DreamHistoryItem } from '../../src/ai/dream-history.js';
import {
  assertDreamInputSafe,
  dreamOutputFields,
  dreamOutputViolation,
  isSensitiveDreamMemory,
} from '../../src/ai/dream-safety.js';
import type { OpenAiTransport } from '../../src/ai/openai-transport.js';
import { parseDreamData, type DreamData } from '../../src/ai/parse-provider.js';
import { dreamMessages } from '../../src/ai/prompts.js';
import { sanitizeText, stringList } from '../../src/ai/sanitize.js';
import { ErrorCode, fail } from '../../src/errors.js';
import { completeOptions, type Candidate } from './candidates.js';

export type DreamCandidateRequest = {
  payload: Record<string, unknown>;
  language: AppLanguage;
};

/** The memory summary actually placed in the prompt (null when dropped). */
export function memorySent(payload: Record<string, unknown>): string | null {
  const memory = sanitizeText(payload.memorySummary, 220);
  return memory && !isSensitiveDreamMemory(memory) ? memory : null;
}

export async function runDreamCandidate(
  transport: OpenAiTransport,
  candidate: Candidate,
  request: DreamCandidateRequest,
): Promise<DreamData> {
  assertDreamInputSafe(request.payload);
  const memory = sanitizeText(request.payload.memorySummary, 220);
  const payload = isSensitiveDreamMemory(memory)
    ? { ...request.payload, memorySummary: undefined }
    : request.payload;
  const raw = await transport.complete(completeOptions(candidate, dreamMessages(payload, request.language)));
  const data = parseDreamData(raw);
  if (dreamOutputViolation(dreamOutputFields(data)) !== null) {
    fail(ErrorCode.invalidResponse, 200, { stage: 'dream_output_safety' });
  }
  const accepted = acceptDreamData(data, {
    narrative: sanitizeText(request.payload.narrative),
    symbols: stringList(request.payload.symbols),
    emotions: stringList(request.payload.emotions),
    language: request.language,
    history: request.payload.history as DreamHistoryItem[] | undefined,
    memorySummary: sanitizeText(payload.memorySummary, 220) || undefined,
  });
  if (!accepted.data) fail(ErrorCode.invalidResponse);
  return accepted.data;
}
