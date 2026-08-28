export type AppEnv = 'development' | 'staging' | 'production';

export type AuthMode =
  | 'bypass'
  | 'hs256'
  | 'jwks'
  | 'opaque'
  | 'fail_closed';

export type AppConfig = {
  host: string;
  port: number;
  appEnv: AppEnv;
  openaiApiKey: string | null;
  openaiModel: string;
  openaiAllowedModels: string[];
  openaiTimeoutMs: number;
  openaiVision: boolean;
  openaiBaseUrl: string;
  authRequired: boolean;
  devAuthBypass: boolean;
  authMode: AuthMode;
  jwtSecret: string | null;
  jwksUrl: string | null;
  jwtIssuer: string | null;
  jwtAudience: string | null;
  rateLimitMax: number;
  rateLimitWindowMs: number;
  expensiveRateMax: number;
  maxConcurrent: number;
  /** Process-wide AI requests per minute (all subjects). Single instance only. */
  globalAiRpm: number;
  /** Process-wide concurrent AI requests (all subjects). Single instance only. */
  globalAiConcurrency: number;
  firebaseProjectId: string | null;
  firebaseProjectNumber: string | null;
  /** When true, AI routes require a verified X-Firebase-AppCheck token. */
  appCheckRequired: boolean;
  /** Development-only: skip App Check verification when not locked. */
  appCheckBypass: boolean;
  minImageBytes: number;
  maxImageBytes: number;
  maxBodyBytes: number;
};

const DEFAULT_ALLOWED = ['gpt-4o', 'gpt-4o-mini'];

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const appEnv = parseEnv(env.APP_ENV ?? env.NODE_ENV);
  const locked = appEnv === 'production' || appEnv === 'staging';
  const allowed = parseList(env.OPENAI_ALLOWED_MODELS, DEFAULT_ALLOWED);
  const requestedModel = (env.OPENAI_MODEL ?? 'gpt-4o').trim() || 'gpt-4o';
  const openaiModel = allowed.includes(requestedModel)
    ? requestedModel
    : 'gpt-4o';
  const timeoutSec = clampInt(env.OPENAI_TIMEOUT_SECONDS, 45, 1, 90);
  const bypassRequested = parseBool(env.AI_DEV_AUTH_BYPASS, false);
  const authRequiredSetting = parseBool(env.AI_AUTH_REQUIRED, true);
  const jwtSecret = nonEmpty(env.AI_JWT_SECRET);
  const firebaseProjectId = nonEmpty(env.FIREBASE_PROJECT_ID);
  const firebaseJwks =
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
  const jwksUrl =
    parseJwksUrl(env.AI_JWKS_URL, locked) ??
    (firebaseProjectId ? firebaseJwks : null);
  const jwtIssuer =
    nonEmpty(env.AI_JWT_ISSUER) ??
    (firebaseProjectId
      ? `https://securetoken.google.com/${firebaseProjectId}`
      : null);
  const jwtAudience = nonEmpty(env.AI_JWT_AUDIENCE) ?? firebaseProjectId;
  const authRequired = locked ? true : authRequiredSetting && !bypassRequested;
  const devAuthBypass = locked ? false : bypassRequested;
  const defaultHost = locked ? '0.0.0.0' : '127.0.0.1';
  const appCheckBypassRequested = parseBool(
    env.AI_APP_CHECK_BYPASS ?? env.ORACLY_APP_CHECK_BYPASS,
    false,
  );
  // Never honor App Check bypass in production/staging.
  const appCheckBypass = locked ? false : appCheckBypassRequested;
  // Production/staging always require App Check (no silent disable).
  // Development: off unless AI_APP_CHECK_REQUIRED / ORACLY_APP_CHECK_REQUIRED=true.
  const appCheckRequired = locked
    ? true
    : appCheckBypass
      ? false
      : parseBool(
          env.AI_APP_CHECK_REQUIRED ?? env.ORACLY_APP_CHECK_REQUIRED,
          false,
        );

  return {
    host: (env.HOST ?? defaultHost).trim() || defaultHost,
    port: clampInt(env.PORT, 8787, 1, 65535),
    appEnv,
    openaiApiKey: nonEmpty(env.OPENAI_API_KEY),
    openaiModel,
    openaiAllowedModels: allowed.includes('gpt-4o') ? allowed : ['gpt-4o', ...allowed],
    openaiTimeoutMs: timeoutSec * 1000,
    openaiVision: parseBool(env.OPENAI_VISION, true),
    openaiBaseUrl: (
      env.OPENAI_BASE_URL ?? 'https://api.openai.com/v1'
    ).replace(/\/$/, ''),
    authRequired,
    devAuthBypass,
    authMode: resolveAuthMode({
      locked,
      bypass: devAuthBypass,
      authRequired,
      jwtSecret,
      jwksUrl,
    }),
    jwtSecret,
    jwksUrl,
    jwtIssuer,
    jwtAudience,
    rateLimitMax: clampInt(env.AI_RATE_LIMIT_MAX, 20, 1, 1000),
    rateLimitWindowMs: clampInt(env.AI_RATE_LIMIT_WINDOW_MS, 900_000, 1000, 86_400_000),
    expensiveRateMax: clampInt(env.AI_EXPENSIVE_RATE_MAX, 10, 1, 100),
    maxConcurrent: clampInt(env.AI_MAX_CONCURRENT, 2, 1, 20),
    globalAiRpm: clampInt(
      env.AI_GLOBAL_RPM ?? env.ORACLY_GLOBAL_AI_RPM,
      60,
      1,
      10_000,
    ),
    globalAiConcurrency: clampInt(
      env.AI_GLOBAL_CONCURRENCY ?? env.ORACLY_GLOBAL_AI_CONCURRENCY,
      8,
      1,
      200,
    ),
    firebaseProjectId,
    firebaseProjectNumber: nonEmpty(env.FIREBASE_PROJECT_NUMBER),
    appCheckRequired,
    appCheckBypass,
    minImageBytes: clampInt(env.AI_MIN_IMAGE_BYTES, 8 * 1024, 1024, 1024 * 1024),
    maxImageBytes: clampInt(
      env.AI_MAX_IMAGE_BYTES,
      12 * 1024 * 1024,
      8 * 1024,
      20 * 1024 * 1024,
    ),
    maxBodyBytes: clampInt(
      env.AI_MAX_BODY_BYTES,
      14 * 1024 * 1024,
      64 * 1024,
      24 * 1024 * 1024,
    ),
  };
}

export function resolveModel(config: AppConfig, hint: unknown): string {
  if (typeof hint === 'string') {
    const trimmed = hint.trim();
    if (config.openaiAllowedModels.includes(trimmed)) return trimmed;
  }
  return config.openaiModel;
}

function parseEnv(value: string | undefined): AppEnv {
  const v = (value ?? '').toLowerCase().trim();
  if (v === 'production' || v === 'prod') return 'production';
  if (v === 'staging' || v === 'stage') return 'staging';
  return 'development';
}

function parseBool(value: string | undefined, fallback: boolean): boolean {
  if (value == null || value.trim() === '') return fallback;
  const v = value.trim().toLowerCase();
  if (['1', 'true', 'yes', 'on'].includes(v)) return true;
  if (['0', 'false', 'no', 'off'].includes(v)) return false;
  return fallback;
}

function parseList(value: string | undefined, fallback: string[]): string[] {
  if (!value?.trim()) return [...fallback];
  const items = value
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  return items.length > 0 ? items : [...fallback];
}

function clampInt(
  value: string | undefined,
  fallback: number,
  min: number,
  max: number,
): number {
  const n = Number.parseInt(value ?? '', 10);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, n));
}

function nonEmpty(value: string | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}

export function resolveAuthMode(input: {
  locked: boolean;
  bypass: boolean;
  authRequired: boolean;
  jwtSecret: string | null;
  jwksUrl: string | null;
}): AuthMode {
  if (!input.locked && input.bypass) return 'bypass';
  if (input.jwksUrl) return 'jwks';
  if (input.jwtSecret) return 'hs256';
  if (input.locked) return 'fail_closed';
  if (!input.authRequired) return 'bypass';
  return 'opaque';
}

function parseJwksUrl(value: string | undefined, locked: boolean): string | null {
  const raw = nonEmpty(value);
  if (!raw) return null;
  try {
    const parsed = new URL(raw);
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') return null;
    if (locked && parsed.protocol !== 'https:') return null;
    return parsed.toString();
  } catch {
    return null;
  }
}
