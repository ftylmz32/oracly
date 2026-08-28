import type { FastifyBaseLogger } from 'fastify';

export type SafeLog = {
  requestId: string;
  operation?: string;
  model?: string;
  latencyMs?: number;
  status?: number;
  errorCode?: string;
  providerResponsePresent?: boolean;
  providerTextLength?: number;
  imagePayloadPresent?: boolean;
  parsedOk?: boolean;
};

const SECRETISH = /sk-[a-zA-Z0-9_-]{8,}|Bearer\s+\S+/i;

export function createRequestId(): string {
  return crypto.randomUUID();
}

export function logSafe(
  logger: FastifyBaseLogger,
  level: 'info' | 'warn' | 'error',
  message: string,
  fields: SafeLog,
): void {
  const sanitized: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(fields)) {
    if (value == null) continue;
    if (typeof value === 'string' && SECRETISH.test(value)) continue;
    sanitized[key] = value;
  }
  logger[level](sanitized, message);
}

export function assertNotSensitive(text: string): void {
  if (SECRETISH.test(text)) {
    throw new Error('sensitive value leaked into log/response path');
  }
}
