/**
 * Dream Phase 4C.3 — the frozen, server-owned Dream writer.
 *
 * `dream_analysis` never follows the client model hint, the generic
 * `OPENAI_MODEL` or `OPENAI_ALLOWED_MODELS`. Locked envs require exactly the
 * 4C.2 winner (Astra + medium) and fail closed with `no_configuration` before
 * any provider call; there is no runtime fallback to another writer. A
 * rollback is an explicit config/code release to a separately validated
 * writer. See docs/product/dream/DREAM_PHASE4C3_PRODUCTION_BINDING.md.
 */
import type { AppConfig } from '../config.js';
import { ErrorCode, ProxyError } from '../errors.js';
import { isLockedAppEnv } from './narrative-tarot-model.js';
import type { OpenAiCompleteOptions } from './openai-transport.js';

export const FROZEN_DREAM_WRITER_MODEL = 'gpt-6-astra';
export const FROZEN_DREAM_REASONING_EFFORT = 'medium';

/** Locked envs: exact frozen writer + reasoning, or no_configuration. */
export function assertFrozenDreamWriter(config: AppConfig): void {
  if (!isLockedAppEnv(config)) return;
  if (
    config.openaiDreamModel !== FROZEN_DREAM_WRITER_MODEL ||
    config.openaiDreamReasoningEffort !== FROZEN_DREAM_REASONING_EFFORT
  ) {
    throw new ProxyError(ErrorCode.noConfiguration);
  }
}

/** The Dream writer model; development may use the generic model when unset. */
export function resolveDreamWriterModel(config: AppConfig): string {
  assertFrozenDreamWriter(config);
  return config.openaiDreamModel ?? config.openaiModel;
}

function dreamReasoningEffort(config: AppConfig, model: string) {
  if (model === FROZEN_DREAM_WRITER_MODEL) return FROZEN_DREAM_REASONING_EFFORT;
  return config.openaiDreamModel ? config.openaiDreamReasoningEffort : null;
}

/**
 * Chat Completions options for one Dream call. With a reasoning effort the
 * transport omits temperature; no sampling or logprob fields are ever set.
 */
export function buildDreamCompleteOptions(
  config: AppConfig,
  messages: OpenAiCompleteOptions['messages'],
): OpenAiCompleteOptions {
  const model = resolveDreamWriterModel(config);
  const reasoningEffort = dreamReasoningEffort(config, model);
  return { model, messages, jsonMode: true, ...(reasoningEffort ? { reasoningEffort } : {}) };
}

/** Non-secret QA metadata for the Dream writer binding. */
export function dreamWriterQaMetadata(config: AppConfig) {
  return {
    configuredGenericModel: config.openaiModel,
    configuredDreamModel: config.openaiDreamModel,
    configuredDreamReasoningEffort: config.openaiDreamReasoningEffort,
    frozenDreamModel: FROZEN_DREAM_WRITER_MODEL,
    frozenDreamReasoningEffort: FROZEN_DREAM_REASONING_EFFORT,
    locked: isLockedAppEnv(config),
  };
}
