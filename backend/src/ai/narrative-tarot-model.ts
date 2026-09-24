/**
 * Phase 6E.7 — Narrative Tarot V2 writer model resolution (isolated from
 * Coffee/Palm/OR/Dream/legacy Tarot routing).
 */
import type { AppConfig } from '../config.js';
import type { OpenAiCompleteOptions } from './openai-transport.js';
import type { OpenAiMessage } from '../types.js';
import {
  NARRATIVE_SCHEMA_NAME,
} from './narrative-tarot-limits.js';
import { NARRATIVE_TAROT_RESULT_SCHEMA } from './narrative-tarot-result-schema.js';

/** Narrow GPT-5.6 family check — keep model-capability logic in one place. */
export function isGpt56Family(model: string): boolean {
  const m = model.trim().toLowerCase();
  return m.startsWith('gpt-5.6');
}

export function supportsReasoningEffort(model: string): boolean {
  return isGpt56Family(model);
}

/**
 * Dedicated Narrative writer when configured + allowlisted; else the already-
 * resolved generic model (OPENAI_MODEL / hint). Never invents a third model.
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
} {
  return {
    configuredGenericModel: config.openaiModel,
    configuredNarrativeModel: config.openaiTarotNarrativeModel,
    resolvedNarrativeModel: resolveNarrativeTarotModel(
      config,
      config.openaiModel,
    ),
    narrativeReasoningEffort: config.openaiTarotNarrativeReasoningEffort,
  };
}

/** Build Narrative V2 chat-completion options (no network). */
export function buildNarrativeTarotCompleteOptions(
  config: AppConfig,
  genericModel: string,
  messages: OpenAiMessage[],
): OpenAiCompleteOptions {
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
