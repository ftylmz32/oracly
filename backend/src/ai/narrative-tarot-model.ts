/**
 * Phase 6F — Frozen Narrative V2 writer contract (gpt-5.6-sol / reasoning none).
 * Locked envs (production|staging) fail closed before provider if mismatched.
 * Development retains 6E.7 generic fallback when dedicated is unset.
 */
import type { AppConfig } from '../config.js';
import { ErrorCode, ProxyError } from '../errors.js';
import type { OpenAiCompleteOptions } from './openai-transport.js';
import type { OpenAiMessage } from '../types.js';
import {
  NARRATIVE_SCHEMA_NAME,
} from './narrative-tarot-limits.js';
import { NARRATIVE_TAROT_RESULT_SCHEMA } from './narrative-tarot-result-schema.js';

/** Frozen writer validated by Phase 6E.8 — do not silently substitute. */
export const FROZEN_NARRATIVE_WRITER_MODEL = 'gpt-5.6-sol';
export const FROZEN_NARRATIVE_REASONING_EFFORT = 'none' as const;

/** Narrow GPT-5.6 family check — keep model-capability logic in one place. */
export function isGpt56Family(model: string): boolean {
  const m = model.trim().toLowerCase();
  return m.startsWith('gpt-5.6');
}

export function supportsReasoningEffort(model: string): boolean {
  return isGpt56Family(model);
}

export function isLockedAppEnv(config: AppConfig): boolean {
  return config.appEnv === 'production' || config.appEnv === 'staging';
}

/**
 * Locked envs: Narrative V2 requires exact frozen Sol + none + allowlist.
 * Throws [ProxyError] no_configuration — no provider call.
 */
export function assertFrozenNarrativeWriter(config: AppConfig): void {
  if (!isLockedAppEnv(config)) return;
  const dedicated = config.openaiTarotNarrativeModel;
  const effort = config.openaiTarotNarrativeReasoningEffort;
  const allowlisted = config.openaiAllowedModels.includes(
    FROZEN_NARRATIVE_WRITER_MODEL,
  );
  if (
    dedicated !== FROZEN_NARRATIVE_WRITER_MODEL ||
    effort !== FROZEN_NARRATIVE_REASONING_EFFORT ||
    !allowlisted
  ) {
    throw new ProxyError(ErrorCode.noConfiguration);
  }
}

/**
 * Dedicated Narrative writer when configured + allowlisted; else the already-
 * resolved generic model (OPENAI_MODEL / hint). Never invents a third model.
 * Locked envs must call [assertFrozenNarrativeWriter] before this.
 */
export function resolveNarrativeTarotModel(
  config: AppConfig,
  genericModel: string,
): string {
  const dedicated = config.openaiTarotNarrativeModel;
  if (
    dedicated &&
    config.openaiAllowedModels.includes(dedicated)
  ) {
    return dedicated;
  }
  return genericModel;
}

/** Safe QA metadata — no secrets, no env dump. */
export function narrativeModelQaMetadata(config: AppConfig): {
  configuredGenericModel: string;
  configuredNarrativeModel: string | null;
  resolvedNarrativeModel: string;
  narrativeReasoningEffort: AppConfig['openaiTarotNarrativeReasoningEffort'];
  frozenNarrativeWriterModel: string;
  frozenNarrativeReasoningEffort: typeof FROZEN_NARRATIVE_REASONING_EFFORT;
} {
  return {
    configuredGenericModel: config.openaiModel,
    configuredNarrativeModel: config.openaiTarotNarrativeModel,
    resolvedNarrativeModel: resolveNarrativeTarotModel(
      config,
      config.openaiModel,
    ),
    narrativeReasoningEffort: config.openaiTarotNarrativeReasoningEffort,
    frozenNarrativeWriterModel: FROZEN_NARRATIVE_WRITER_MODEL,
    frozenNarrativeReasoningEffort: FROZEN_NARRATIVE_REASONING_EFFORT,
  };
}

/** Build Narrative V2 chat-completion options (no network). */
export function buildNarrativeTarotCompleteOptions(
  config: AppConfig,
  genericModel: string,
  messages: OpenAiMessage[],
): OpenAiCompleteOptions {
  assertFrozenNarrativeWriter(config);
  const model = resolveNarrativeTarotModel(config, genericModel);
  const jsonSchema = {
    name: NARRATIVE_SCHEMA_NAME,
    schema: NARRATIVE_TAROT_RESULT_SCHEMA,
  };
  if (supportsReasoningEffort(model)) {
    return {
      model,
      messages,
      reasoningEffort: config.openaiTarotNarrativeReasoningEffort,
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
