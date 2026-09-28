/**
 * Dream Phase 4C — the production Dream provider configuration, read from
 * the Cloud Run deploy script's non-secret env block (the source of the
 * deployed `OPENAI_*` values) instead of any harness preference. The API
 * key is taken from the harness process env and is never returned,
 * printed or serialized by this module.
 *
 * Phase 4C.3: the Dream writer is server-owned (`OPENAI_DREAM_*`); the
 * description reports the request `AiProxyService.dream` actually sends.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { loadConfig, type AppConfig } from '../../src/config.js';
import { buildDreamCompleteOptions, dreamWriterQaMetadata } from '../../src/ai/dream-writer-model.js';
import { buildChatCompletionBody } from '../../src/ai/openai-transport.js';

const DEPLOY_SCRIPT = fileURLToPath(new URL('../deploy-cloud-run.sh', import.meta.url));
const KEYS = [
  'APP_ENV',
  'OPENAI_BASE_URL',
  'OPENAI_MODEL',
  'OPENAI_ALLOWED_MODELS',
  'OPENAI_DREAM_MODEL',
  'OPENAI_DREAM_REASONING_EFFORT',
  'OPENAI_TIMEOUT_SECONDS',
] as const;

/**
 * G2B0: the deploy script's env block moved from `--env-vars-file` (replace
 * semantics, one `echo "KEY: value"` line per key) to `--update-env-vars`
 * (merge semantics, so an update can never silently delete an existing key
 * the script doesn't list) — one `ENV_UPDATES+="@KEY=value"` fragment per
 * key, `@`-delimited because `OPENAI_ALLOWED_MODELS`'s own value contains
 * commas. [KEYS] only.
 */
export function deployedOpenAiEnv(script = readFileSync(DEPLOY_SCRIPT, 'utf8')): Record<string, string> {
  const env: Record<string, string> = {};
  for (const key of KEYS) {
    const match = script.match(new RegExp(`[@^]${key}=([^"@]+)`));
    if (!match) throw new Error(`deploy script has no ${key}`);
    env[key] = match[1].trim();
  }
  return env;
}

export function phase4cConfig(apiKey: string | undefined): AppConfig {
  return loadConfig({ ...deployedOpenAiEnv(), OPENAI_API_KEY: apiKey });
}

/** Non-secret description of what a Dream call will send (throws no_configuration when misbound). */
export function describeDreamConfig(config: AppConfig) {
  const options = buildDreamCompleteOptions(config, []);
  const body = buildChatCompletionBody(options);
  return {
    source: 'backend/scripts/deploy-cloud-run.sh env block + backend/src/config.ts loadConfig',
    deployedEnv: deployedOpenAiEnv(),
    appEnv: config.appEnv,
    endpoint: `${config.openaiBaseUrl}/chat/completions`,
    ...dreamWriterQaMetadata(config),
    allowedModels: config.openaiAllowedModels,
    resolvedModel: options.model,
    temperature: body.temperature ?? null,
    reasoningEffort: body.reasoning_effort ?? null,
    responseFormat: body.response_format ?? null,
    maxOutputTokens: null,
    timeoutMs: config.openaiTimeoutMs,
    transportRetries: 0,
  };
}
