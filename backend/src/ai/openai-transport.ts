import type { AppConfig } from '../config.js';
import { ErrorCode, ProxyError } from '../errors.js';
import type { OpenAiFetch, OpenAiMessage } from '../types.js';
import { assertGeneratedImageBytes } from './image.js';
import { extractMessageContent } from './extract-message-content.js';

export type OpenAiCompleteOptions = {
  messages: OpenAiMessage[];
  model: string;
  jsonMode?: boolean;
  /** Prefer over jsonMode when the model supports strict JSON Schema. */
  jsonSchema?: { name: string; schema: Record<string, unknown> | object };
  temperature?: number;
  /** gpt-5.6 family — omit when unsupported by the model. */
  reasoningEffort?: 'none' | 'low' | 'medium' | 'high' | 'xhigh' | 'max';
};

/** Pure chat-completions body builder (no network). Phase 6E.4.1. */
export function buildChatCompletionBody(
  options: OpenAiCompleteOptions,
): Record<string, unknown> {
  return {
    model: options.model,
    messages: options.messages,
    ...(options.temperature !== undefined
      ? { temperature: options.temperature }
      : options.reasoningEffort
        ? {}
        : { temperature: 0.6 }),
    ...(options.reasoningEffort
      ? { reasoning_effort: options.reasoningEffort }
      : {}),
    ...(options.jsonSchema
      ? {
          response_format: {
            type: 'json_schema',
            json_schema: {
              name: options.jsonSchema.name,
              strict: true,
              schema: options.jsonSchema.schema,
            },
          },
        }
      : options.jsonMode
        ? { response_format: { type: 'json_object' } }
        : {}),
  };
}

export class OpenAiTransport {
  constructor(
    private readonly config: AppConfig,
    private readonly fetchImpl: OpenAiFetch = fetch,
  ) {}

  async complete(options: OpenAiCompleteOptions): Promise<string> {
    if (!this.config.openaiApiKey) {
      throw new ProxyError(ErrorCode.noConfiguration);
    }
    const controller = new AbortController();
    const timer = setTimeout(
      () => controller.abort(),
      this.config.openaiTimeoutMs,
    );
    try {
      const response = await this.fetchImpl(
        `${this.config.openaiBaseUrl}/chat/completions`,
        {
          method: 'POST',
          signal: controller.signal,
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.config.openaiApiKey}`,
          },
          body: JSON.stringify(buildChatCompletionBody(options)),
        },
      );
      if (response.status === 401 || response.status === 403) {
        throw new ProxyError(ErrorCode.noConfiguration);
      }
      if (response.status === 429) {
        throw new ProxyError(ErrorCode.rateLimited, 429, await rateLimitDetails(response));
      }
      if (response.status === 408) {
        throw new ProxyError(ErrorCode.providerTimeout, 408);
      }
      if (!response.ok) {
        throw await mapHttpFailure(response);
      }
      const body = (await response.json()) as {
        choices?: Array<{ message?: { content?: unknown } }>;
      };
      const content = extractMessageContent(
        body.choices?.[0]?.message?.content,
      );
      if (!content) {
        throw new ProxyError(ErrorCode.invalidResponse);
      }
      return content;
    } catch (error) {
      throw mapTransportError(error);
    } finally {
      clearTimeout(timer);
    }
  }

  async generateImage(
    prompt: string,
    options?: { size?: string; quality?: 'low' | 'medium' | 'high' },
  ): Promise<{ imageBase64: string; mimeType: string }> {
    if (!this.config.openaiApiKey) {
      throw new ProxyError(ErrorCode.noConfiguration);
    }
    const model = this.config.openaiImageModel.trim();
    if (!model) {
      throw new ProxyError(ErrorCode.noConfiguration);
    }
    const controller = new AbortController();
    const timer = setTimeout(
      () => controller.abort(),
      this.config.openaiImageTimeoutMs,
    );
    try {
      // GPT Image models return data[0].b64_json by default.
      // Do NOT send response_format — official gpt-image-* reject it (HTTP 400).
      const response = await this.fetchImpl(
        `${this.config.openaiBaseUrl}/images/generations`,
        {
          method: 'POST',
          signal: controller.signal,
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.config.openaiApiKey}`,
          },
          body: JSON.stringify({
            model,
            prompt,
            n: 1,
            size: options?.size ?? this.config.openaiImageSize,
            quality: options?.quality ?? this.config.openaiImageQuality,
          }),
        },
      );
      if (response.status === 401 || response.status === 403) {
        throw new ProxyError(ErrorCode.noConfiguration);
      }
      if (response.status === 429) {
        throw new ProxyError(ErrorCode.rateLimited, 429, await rateLimitDetails(response));
      }
      if (response.status === 408) {
        throw new ProxyError(ErrorCode.providerTimeout, 408);
      }
      if (!response.ok) {
        throw await mapHttpFailure(response);
      }
      const body = (await response.json()) as {
        data?: Array<{ b64_json?: unknown }>;
      };
      const imageBase64 =
        typeof body.data?.[0]?.b64_json === 'string'
          ? body.data[0].b64_json.trim()
          : '';
      if (!imageBase64) {
        throw new ProxyError(ErrorCode.invalidResponse);
      }
      const checked = assertGeneratedImageBytes(imageBase64, this.config);
      return { imageBase64, mimeType: checked.mimeType };
    } catch (error) {
      throw mapTransportError(error);
    } finally {
      clearTimeout(timer);
    }
  }
}

/** SM-RL2 §1/§2 — bounded, sanitized 429 evidence captured on the
 * ProxyError.details for a rate-limit rejection, used by the Soulmate
 * durable worker's bounded-retry decision (soulmate-provider-failure.ts)
 * and its `provider_rate_limited` observability log. Generic to this
 * shared transport (Coffee/Palm/Soulmate all flow through here) — never
 * affects `ProxyError.code`, which every existing caller already
 * switches on, so this is purely additive metadata. Deliberately never
 * captures the API key, Authorization header, request payload, or an
 * unbounded raw response body — only a small set of structured fields
 * useful for diagnosing WHY a request was rate-limited (see SM-PR1). A
 * body-parse failure still leaves the 429/rate_limited classification
 * intact — the caller already decided that from the HTTP status alone. */
const MAX_PROVIDER_MESSAGE_LENGTH = 300;
const MAX_RATE_LIMIT_HEADER_VALUE_LENGTH = 64;
const MAX_RATE_LIMIT_HEADERS = 12;

async function rateLimitDetails(response: Response): Promise<Record<string, unknown>> {
  const details: Record<string, unknown> = { httpStatus: 429 };

  const retryAfterMs = parseRetryAfterMs(response.headers.get('retry-after'));
  if (retryAfterMs != null) details.retryAfterMs = retryAfterMs;

  const requestId = response.headers.get('x-request-id') ?? response.headers.get('request-id');
  if (requestId) details.requestId = requestId.slice(0, 128);

  const rateLimit = collectRateLimitHeaders(response.headers);
  if (rateLimit) details.rateLimit = rateLimit;

  const providerMessage = await readProviderMessage(response);
  if (providerMessage) details.providerMessage = providerMessage;

  return details;
}

function parseRetryAfterMs(raw: string | null): number | undefined {
  if (!raw) return undefined;
  const seconds = Number(raw);
  if (Number.isFinite(seconds) && seconds >= 0) {
    return Math.round(seconds * 1000);
  }
  const dateMs = Date.parse(raw);
  if (Number.isFinite(dateMs)) {
    const deltaMs = dateMs - Date.now();
    if (deltaMs > 0) return deltaMs;
  }
  return undefined;
}

/** Bounded count and per-value length — never an unbounded header dump. */
function collectRateLimitHeaders(headers: Headers): Record<string, string> | undefined {
  const out: Record<string, string> = {};
  let count = 0;
  for (const [name, value] of headers.entries()) {
    if (!/^x-ratelimit-(limit|remaining|reset)-/i.test(name)) continue;
    if (count >= MAX_RATE_LIMIT_HEADERS) break;
    out[name.toLowerCase()] = value.slice(0, MAX_RATE_LIMIT_HEADER_VALUE_LENGTH);
    count += 1;
  }
  return count > 0 ? out : undefined;
}

/** Only `error.type` / `error.code` / `error.message` — never the raw body,
 * never headers/payload, bounded to a short sanitized string. Defensively
 * redacts anything that looks like a bearer token or an OpenAI secret key
 * even though the provider is not expected to echo one back — this must
 * hold regardless of what the provider's body ever contains. */
async function readProviderMessage(response: Response): Promise<string | undefined> {
  try {
    const body = (await response.json()) as {
      error?: { type?: unknown; code?: unknown; message?: unknown };
    };
    return formatProviderMessage(body.error);
  } catch {
    return undefined;
  }
}

function formatProviderMessage(
  error: { type?: unknown; code?: unknown; message?: unknown } | undefined,
): string | undefined {
  if (!error) return undefined;
  const parts = [error.type, error.code, error.message].filter(
    (value): value is string => typeof value === 'string' && value.length > 0,
  );
  if (parts.length === 0) return undefined;
  return redactSecrets(parts.join(' | ')).slice(0, MAX_PROVIDER_MESSAGE_LENGTH);
}

function redactSecrets(text: string): string {
  return text
    .replace(/Bearer\s+\S+/gi, '[redacted]')
    .replace(/sk-[a-zA-Z0-9_-]{8,}/g, '[redacted]');
}

function mapTransportError(error: unknown): ProxyError {
  if (error instanceof ProxyError) return error;
  if (error instanceof Error && error.name === 'AbortError') {
    return new ProxyError(ErrorCode.providerTimeout, 408);
  }
  if (error instanceof TypeError) {
    return new ProxyError(ErrorCode.network);
  }
  return new ProxyError(ErrorCode.providerError);
}

function isStructuredSchemaFailure(
  code: string,
  type: string,
  message: string,
): boolean {
  if (code.includes('invalid_json_schema')) return true;
  if (message.includes('invalid_json_schema')) return true;
  if (message.includes('invalid schema')) return true;
  if (message.includes('unsupported schema')) return true;
  if (message.includes('response_format schema')) return true;
  if (message.includes('schema') && message.includes('not permitted')) return true;
  if (type.includes('invalid_request') && message.includes('schema')) return true;
  return false;
}

/** Map provider HTTP failures without leaking raw messages to clients. */
async function mapHttpFailure(response: Response): Promise<ProxyError> {
  const details: Record<string, unknown> = { httpStatus: response.status };
  const requestId =
    response.headers.get('x-request-id') ?? response.headers.get('request-id');
  if (requestId) details.requestId = requestId.slice(0, 128);

  let code = '';
  let type = '';
  let message = '';
  try {
    const body = (await response.json()) as {
      error?: { code?: unknown; message?: unknown; type?: unknown };
    };
    code = String(body.error?.code ?? '').toLowerCase();
    type = String(body.error?.type ?? '').toLowerCase();
    message = String(body.error?.message ?? '').toLowerCase();
    const providerMessage = formatProviderMessage(body.error);
    if (providerMessage) details.providerMessage = providerMessage;
  } catch {
    /* body unreadable — still return status + requestId */
  }

  if (
    code.includes('moderation') ||
    type.includes('moderation') ||
    message.includes('moderation') ||
    message.includes('safety system') ||
    message.includes('content policy')
  ) {
    return new ProxyError(ErrorCode.moderationBlocked, response.status, details);
  }
  if (isStructuredSchemaFailure(code, type, message)) {
    return new ProxyError(ErrorCode.invalidRequest, response.status, details);
  }
  if (
    response.status === 400 &&
    (message.includes('unknown parameter') ||
      message.includes('unsupported') ||
      message.includes('model') ||
      code.includes('invalid'))
  ) {
    // User-correctable / config errors — never auto-retry upstream.
    return new ProxyError(ErrorCode.invalidRequest, response.status, details);
  }
  return new ProxyError(ErrorCode.providerError, response.status, details);
}
