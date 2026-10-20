/**
 * Daily astrology writer options. Shares the frozen Yıldızname writer
 * (gpt-5.6-sol / reasoning none): locked envs fail closed before the provider
 * when that writer is not configured, so no new production env is needed.
 */
import type { AppConfig } from '../config.js';
import type { OpenAiMessage } from '../types.js';
import type { OpenAiCompleteOptions } from './openai-transport.js';
import {
  assertFrozenYildiznameWriter,
  resolveYildiznameNarrativeModel,
  supportsReasoningEffort,
} from './narrative-yildizname-model.js';
import { ASTROLOGY_DAILY_SCHEMA_NAME } from './astrology-daily-limits.js';
import { ASTROLOGY_DAILY_RESULT_SCHEMA } from './astrology-daily-result.js';

export function buildAstrologyDailyCompleteOptions(
  config: AppConfig,
  genericModel: string,
  messages: OpenAiMessage[],
): OpenAiCompleteOptions {
  assertFrozenYildiznameWriter(config);
  const model = resolveYildiznameNarrativeModel(config, genericModel);
  const jsonSchema = {
    name: ASTROLOGY_DAILY_SCHEMA_NAME,
    schema: ASTROLOGY_DAILY_RESULT_SCHEMA as unknown as Record<string, unknown>,
  };
  if (supportsReasoningEffort(model)) {
    return {
      model,
      messages,
      reasoningEffort: config.openaiYildiznameNarrativeReasoningEffort,
      jsonSchema,
    };
  }
  return { model, messages, temperature: 0.6, jsonSchema };
}
