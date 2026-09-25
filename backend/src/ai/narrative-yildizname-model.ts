/**
 * Phase 5 — Frozen Yıldızname writer contract (gpt-5.6-sol / reasoning none).
 * Locked envs (production|staging) fail closed before provider if mismatched.
 * Development retains generic fallback when dedicated is unset.
 */
import type { AppConfig } from '../config.js';
import { ErrorCode, ProxyError } from '../errors.js';
import type { OpenAiCompleteOptions } from './openai-transport.js';
import type { OpenAiMessage } from '../types.js';
import {
  isGpt56Family,
  isLockedAppEnv,
  supportsReasoningEffort,
} from './narrative-tarot-model.js';
import { YILDIZNAME_SCHEMA_NAME } from './narrative-yildizname-limits.js';
import { YILDIZNAME_NARRATIVE_RESULT_SCHEMA } from './narrative-yildizname-result-schema.js';

/** Frozen writer — do not silently substitute. */
export const FROZEN_YILDIZNAME_WRITER_MODEL = 'gpt-5.6-sol';
export const FROZEN_YILDIZNAME_REASONING_EFFORT = 'none' as const;

export { isLockedAppEnv, isGpt56Family, supportsReasoningEffort };

/**
 * Locked envs: Yıldızname requires exact frozen Sol + none + allowlist.
 * Throws [ProxyError] no_configuration — no provider call.
 */
export function assertFrozenYildiznameWriter(config: AppConfig): void {
  if (!isLockedAppEnv(config)) return;
  const dedicated = config.openaiYildiznameNarrativeModel;
  const effort = config.openaiYildiznameNarrativeReasoningEffort;
  const allowlisted = config.openaiAllowedModels.includes(
    FROZEN_YILDIZNAME_WRITER_MODEL,
  );
  if (
    dedicated !== FROZEN_YILDIZNAME_WRITER_MODEL ||
    effort !== FROZEN_YILDIZNAME_REASONING_EFFORT ||
    !allowlisted
  ) {
    throw new ProxyError(ErrorCode.noConfiguration);
  }
}

/**
 * Dedicated Yıldızname writer when configured + allowlisted; else the already-
 * resolved generic model. Never invents a third model.
 * Locked envs must call [assertFrozenYildiznameWriter] before this.
 */
export function resolveYildiznameNarrativeModel(
  config: AppConfig,
  genericModel: string,
): string {
  const dedicated = config.openaiYildiznameNarrativeModel;
  if (dedicated && config.openaiAllowedModels.includes(dedicated)) {
    return dedicated;
  }
  return genericModel;
}

/** Build Yıldızname natal narrative chat-completion options (no network). */
export function buildYildiznameNarrativeCompleteOptions(
  config: AppConfig,
  genericModel: string,
  messages: OpenAiMessage[],
): OpenAiCompleteOptions {
  assertFrozenYildiznameWriter(config);
  const model = resolveYildiznameNarrativeModel(config, genericModel);
  const jsonSchema = {
    name: YILDIZNAME_SCHEMA_NAME,
    schema: YILDIZNAME_NARRATIVE_RESULT_SCHEMA,
  };
  if (supportsReasoningEffort(model)) {
    return {
      model,
      messages,
      reasoningEffort: config.openaiYildiznameNarrativeReasoningEffort,
      jsonSchema,
    };
  }
  return {
    model,
    messages,
    temperature: 0.55,
    jsonSchema,
  };
}
