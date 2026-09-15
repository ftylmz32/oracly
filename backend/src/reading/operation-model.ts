import { Timestamp } from '@google-cloud/firestore';

export const READING_TYPES = ['coffee', 'palm', 'soulmate'] as const;
export type ReadingType = (typeof READING_TYPES)[number];
export const READING_LANGUAGES = ['tr', 'en', 'ru'] as const;
export type ReadingLanguage = (typeof READING_LANGUAGES)[number];
/** Pre-R4 records did not persist locale and historically ran in Turkish. */
export const LEGACY_READING_LANGUAGE: ReadingLanguage = 'tr';

export const OPERATION_STATUSES = [
  'waiting',
  'processing',
  'ready',
  'failed',
] as const;
export type ReadingOperationStatus = (typeof OPERATION_STATUSES)[number];

export const FAILURE_CODES = ['unavailable', 'invalid', 'cancelled'] as const;
export type FailureCode = (typeof FAILURE_CODES)[number];

export const SCHEMA_VERSION = 1;

/**
 * SMD1 — additive, optional execution-mode marker. Absent (undefined) on
 * every operation created by a pre-SMD1 client (including all historical
 * Soulmate records): those remain 100% on the legacy client-driven path,
 * completely unaffected by this field's existence. Only a client that
 * explicitly sends `executionMode: 'durable'` at creation time opts an
 * operation into server-authoritative processing. This is the single
 * switch that keeps SMD1 additive rather than a breaking reinterpretation
 * of existing/legacy Soulmate operations.
 */
export const EXECUTION_MODES = ['durable'] as const;
export type ExecutionMode = (typeof EXECUTION_MODES)[number];

export function isExecutionMode(value: unknown): value is ExecutionMode {
  return (
    typeof value === 'string' &&
    (EXECUTION_MODES as readonly string[]).includes(value)
  );
}

const SOURCE_REQUEST_ID = /^[A-Za-z0-9._:-]{8,64}$/;
const RESULT_ID = /^[A-Za-z0-9._:-]{8,80}$/;
const OPERATION_ID = /^[a-f0-9]{32}$/;

export type ReadingOperationRecord = {
  schemaVersion: typeof SCHEMA_VERSION;
  operationId: string;
  ownerUserId: string;
  readingType: ReadingType;
  language: ReadingLanguage;
  status: ReadingOperationStatus;
  createdAtMs: number;
  readyAtMs: number;
  updatedAtMs: number;
  sourceRequestId: string;
  resultId: string | null;
  failureCode: FailureCode | null;
  acceleratedAtMs: number | null;
  gemDebitId: string | null;
  executionStartedAtMs: number | null;
  /** SMD1 — undefined/null means legacy (client-driven). */
  executionMode: ExecutionMode | null;
};

export type PublicOperationStatus = {
  operationId: string;
  readingType: ReadingType;
  status: ReadingOperationStatus;
  /** SMD1 — true only for a server-authoritative durable operation. */
  durable: boolean;
  createdAt: string;
  readyAt: string;
  serverNow: string;
  waitFinished: boolean;
  remainingMs: number;
  resultReady: boolean;
  resultId: string | null;
  accelerated: boolean;
};

export function isReadingType(value: unknown): value is ReadingType {
  return (
    typeof value === 'string' &&
    (READING_TYPES as readonly string[]).includes(value)
  );
}

export function isReadingLanguage(value: unknown): value is ReadingLanguage {
  return typeof value === 'string' &&
    (READING_LANGUAGES as readonly string[]).includes(value);
}

export function isFailureCode(value: unknown): value is FailureCode {
  return (
    typeof value === 'string' &&
    (FAILURE_CODES as readonly string[]).includes(value)
  );
}

export function isOperationId(value: unknown): value is string {
  return typeof value === 'string' && OPERATION_ID.test(value);
}

export function parseSourceRequestId(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return SOURCE_REQUEST_ID.test(trimmed) ? trimmed : null;
}

export function parseResultId(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return RESULT_ID.test(trimmed) ? trimmed : null;
}

export function toStoredDocument(
  record: ReadingOperationRecord,
): Record<string, unknown> {
  const retentionMs = record.status === 'failed' ? 7 * 86_400_000 : record.status === 'ready' ? 30 * 86_400_000 : null;
  return {
    schemaVersion: record.schemaVersion,
    operationId: record.operationId,
    ownerUserId: record.ownerUserId,
    readingType: record.readingType,
    language: record.language,
    status: record.status,
    createdAtMs: record.createdAtMs,
    readyAtMs: record.readyAtMs,
    updatedAtMs: record.updatedAtMs,
    sourceRequestId: record.sourceRequestId,
    resultId: record.resultId,
    failureCode: record.failureCode,
    acceleratedAtMs: record.acceleratedAtMs,
    gemDebitId: record.gemDebitId,
    executionStartedAtMs: record.executionStartedAtMs,
    executionMode: record.executionMode,
    ...(retentionMs == null ? {} : { expiresAt: Timestamp.fromMillis(record.updatedAtMs + retentionMs) }),
  };
}

export function parseStoredRecord(
  data: Record<string, unknown> | undefined,
): ReadingOperationRecord | null {
  if (!data) return null;
  if (data.schemaVersion !== SCHEMA_VERSION) return null;
  if (!isOperationId(data.operationId)) return null;
  if (typeof data.ownerUserId !== 'string' || data.ownerUserId.length < 4) {
    return null;
  }
  if (!isReadingType(data.readingType)) return null;
  const language = data.language == null
    ? LEGACY_READING_LANGUAGE
    : isReadingLanguage(data.language) ? data.language : null;
  if (!language) return null;
  if (!isStatus(data.status)) return null;
  if (!isEpoch(data.createdAtMs) || !isEpoch(data.readyAtMs) || !isEpoch(data.updatedAtMs)) {
    return null;
  }
  if (typeof data.sourceRequestId !== 'string') return null;
  if (!isNullableString(data.resultId)) return null;
  if (data.failureCode != null && !isFailureCode(data.failureCode)) return null;
  const acceleratedAtMs = data.acceleratedAtMs ?? null;
  if (acceleratedAtMs != null && !isEpoch(acceleratedAtMs)) return null;
  if (!isNullableString(data.gemDebitId)) return null;
  if (!isNullableString(data.resultId)) return null;
  return {
    schemaVersion: SCHEMA_VERSION,
    operationId: data.operationId,
    ownerUserId: data.ownerUserId,
    readingType: data.readingType,
    language,
    status: data.status,
    createdAtMs: data.createdAtMs,
    readyAtMs: data.readyAtMs,
    updatedAtMs: data.updatedAtMs,
    sourceRequestId: data.sourceRequestId,
    resultId: data.resultId,
    failureCode: data.failureCode ?? null,
    acceleratedAtMs,
    gemDebitId: data.gemDebitId ?? null,
    executionStartedAtMs:
      typeof data.executionStartedAtMs === 'number' ? data.executionStartedAtMs : null,
    // Absent on every pre-SMD1 (including all historical Soulmate) record —
    // parses to null, i.e. legacy, never durable by accident.
    executionMode: isExecutionMode(data.executionMode) ? data.executionMode : null,
  };
}

export function toPublicStatus(
  record: ReadingOperationRecord,
  serverNowMs: number,
): PublicOperationStatus {
  const remainingMs = Math.max(0, record.readyAtMs - serverNowMs);
  const resultReady = record.status === 'ready' && record.resultId != null;
  return {
    operationId: record.operationId,
    readingType: record.readingType,
    status: record.status,
    durable: record.executionMode === 'durable',
    createdAt: new Date(record.createdAtMs).toISOString(),
    readyAt: new Date(record.readyAtMs).toISOString(),
    serverNow: new Date(serverNowMs).toISOString(),
    waitFinished: serverNowMs >= record.readyAtMs,
    remainingMs,
    resultReady,
    resultId: resultReady ? record.resultId : null,
    accelerated: record.acceleratedAtMs != null,
  };
}

function isStatus(value: unknown): value is ReadingOperationStatus {
  return (
    typeof value === 'string' &&
    (OPERATION_STATUSES as readonly string[]).includes(value)
  );
}

function isEpoch(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value) && value > 0;
}

function isNullableEpoch(value: unknown): boolean {
  return value == null || isEpoch(value);
}

function isNullableString(value: unknown): value is string | null {
  return value == null || typeof value === 'string';
}
