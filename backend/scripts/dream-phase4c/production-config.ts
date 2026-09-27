/**
 * Dream Phase 4C — the production Dream provider configuration, read from
 * the Cloud Run deploy script's non-secret env block (the source of the
 * deployed `OPENAI_*` values) instead of any harness preference. The API
 * key is taken from the harness process env and is never returned,
 * printed or serialized by this module.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { loadConfig, type AppConfig } from '../../src/config.js';
import { buildChatCompletionBody } from '../../src/ai/openai-transport.js';

const DEPLOY_SCRIPT = fileURLToPath(new URL('../deploy-cloud-run.sh', import.meta.url));
const KEYS = [
  'APP_ENV',
  'OPENAI_BASE_URL',
  'OPENAI_MODEL',
  'OPENAI_ALLOWED_MODELS',
  'OPENAI_TIMEOUT_SECONDS',
] as const;

/** `echo "KEY: value"` lines of the deploy env file, for [KEYS] only. */
export function deployedOpenAiEnv(script = readFileSync(DEPLOY_SCRIPT, 'utf8')): Record<string, string> {
  const env: Record<string, string> = {};
  for (const key of KEYS) {
    const match = script.match(new RegExp(`echo "${key}: (.+)"\\s*$`, 'm'));
    if (!match) throw new Error(`deploy script has no ${key}`);
    env[key] = match[1].replace(/^\\"|\\"$/g, '').trim();
  }
  return env;
}

export function phase4cConfig(apiKey: string | undefined): AppConfig {
  return loadConfig({ ...deployedOpenAiEnv(), OPENAI_API_KEY: apiKey });
}

/** Non-secret description of what a Dream call will send. */
export function describeDreamConfig(config: AppConfig, resolvedModel: string) {
  const body = buildChatCompletionBody({ model: resolvedModel, messages: [], jsonMode: true });
  return {
    source: 'backend/scripts/deploy-cloud-run.sh env block + backend/src/config.ts loadConfig',
    deployedEnv: deployedOpenAiEnv(),
    appEnv: config.appEnv,
    endpoint: `${config.openaiBaseUrl}/chat/completions`,
    configuredModel: config.openaiModel,
    allowedModels: config.openaiAllowedModels,
    resolvedModel,
    temperature: body.temperature ?? null,
    reasoningEffort: body.reasoning_effort ?? null,
    responseFormat: body.response_format ?? null,
    maxOutputTokens: null,
    timeoutMs: config.openaiTimeoutMs,
    transportRetries: 0,
  };
}
