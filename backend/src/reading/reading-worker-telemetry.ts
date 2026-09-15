/**
 * Safe stage telemetry for the durable reading worker.
 * Never logs tokens, image bytes, prompts, or user prose.
 */

export type ReadingWorkerStage =
  | 'reading_task_auth_verified'
  | 'reading_task_claim_acquired'
  | 'staged_fetch_started'
  | 'staged_fetch_succeeded'
  | 'provider_started'
  | 'provider_completed'
  | 'validation_started'
  | 'validation_completed'
  | 'result_persist_started'
  | 'result_persist_completed'
  | 'notification_started'
  | 'notification_completed'
  // R2.1 — the durable dispatch claim was already held (or already sent)
  // by an earlier/racing invocation; this run never called the provider.
  | 'notification_already_dispatched'
  // SMD1 — Soulmate durable worker (no staged input image, no separate
  // validation phase; a durable portrait-persist step instead).
  | 'soulmate_input_load_started'
  | 'soulmate_input_load_succeeded'
  | 'soulmate_portrait_persist_started'
  | 'soulmate_portrait_persist_completed';

export type WorkerStageLogger = {
  info: (fields: Record<string, unknown>, msg?: string) => void;
  error: (fields: Record<string, unknown>, msg?: string) => void;
};

export class ReadingWorkerFailure extends Error {
  constructor(
    readonly stage: ReadingWorkerStage | 'worker',
    readonly safeCode: string,
    readonly retryable: boolean,
    readonly feature: 'coffee' | 'palm' | 'soulmate' | 'unknown' = 'unknown',
    cause?: unknown,
  ) {
    const safeMessage = safeErrorMessage(cause) || safeCode;
    super(safeMessage, cause instanceof Error ? { cause } : undefined);
    this.name = 'ReadingWorkerFailure';
  }
}

export function logWorkerStage(
  log: WorkerStageLogger,
  event: ReadingWorkerStage,
  fields: {
    operationId?: string;
    feature?: string;
    byteLength?: number;
    checksumMatched?: boolean;
  } = {},
): void {
  log.info({
    event,
    operationId: fields.operationId,
    feature: fields.feature,
    byteLength: fields.byteLength,
    checksumMatched: fields.checksumMatched,
  });
}

export function logWorkerFailure(
  log: WorkerStageLogger,
  input: {
    operationId: string;
    feature: string;
    stage: string;
    error: unknown;
    retryable: boolean;
  },
): void {
  const err = input.error;
  log.error({
    event: 'reading_task_stage_failed',
    operationId: input.operationId,
    feature: input.feature,
    stage: input.stage,
    errorName: errorName(err),
    errorCode: safeErrorCode(err),
    errorMessage: safeErrorMessage(err),
    retryable: input.retryable,
  });
}

export function wrapStageError(
  stage: ReadingWorkerStage | 'worker',
  feature: 'coffee' | 'palm' | 'soulmate' | 'unknown',
  error: unknown,
  retryable = true,
): ReadingWorkerFailure {
  if (error instanceof ReadingWorkerFailure) return error;
  return new ReadingWorkerFailure(
    stage,
    safeErrorCode(error),
    retryable,
    feature,
    error,
  );
}

function errorName(error: unknown): string {
  if (error instanceof Error && error.name) return error.name.slice(0, 80);
  return 'Error';
}

function rootCause(error: unknown): unknown {
  let current: unknown = error;
  for (let i = 0; i < 4; i++) {
    if (!(current instanceof Error) || current.cause == null) return current;
    current = current.cause;
  }
  return current;
}

function safeErrorCode(error: unknown): string {
  if (error instanceof ReadingWorkerFailure) return error.safeCode.slice(0, 80);
  const root = rootCause(error);
  if (root && typeof root === 'object' && 'code' in root) {
    const code = (root as { code?: unknown }).code;
    if (typeof code === 'string' && code.length > 0 && code.length <= 80) {
      return code;
    }
    if (typeof code === 'number') return String(code);
  }
  if (root instanceof Error && root.message) {
    return root.message.replace(/\s+/g, '_').slice(0, 80);
  }
  if (error instanceof Error && error.message) {
    return error.message.replace(/\s+/g, '_').slice(0, 80);
  }
  return 'internal_error';
}

function safeErrorMessage(error: unknown): string {
  const preferred =
    rootCause(error) instanceof Error
      ? (rootCause(error) as Error)
      : error instanceof Error
        ? error
        : null;
  if (!preferred) return 'internal_error';
  const raw = preferred.message || preferred.name || 'internal_error';
  return raw
    .replace(/Bearer\s+\S+/gi, '[redacted]')
    .replace(/sk-[a-zA-Z0-9_-]{8,}/g, '[redacted]')
    .slice(0, 160);
}
