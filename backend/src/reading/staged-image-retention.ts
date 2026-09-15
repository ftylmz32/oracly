import { Firestore, Timestamp } from '@google-cloud/firestore';
import { Storage } from '@google-cloud/storage';

const MAX_STAGED_AGE_MS = 24 * 60 * 60 * 1000;

type OperationRetentionView = {
  status?: unknown;
  updatedAtMs?: unknown;
  readyAtMs?: unknown;
};

/** Pure release rule: current active work is never deleted; only terminal,
 * missing, or demonstrably abandoned work older than the staging ceiling. */
export function mayDeleteExpiredStagedInput(
  operation: OperationRetentionView | undefined,
  nowMs: number,
): boolean {
  if (!operation) return true;
  if (operation.status === 'ready' || operation.status === 'failed') return true;
  const updatedAtMs = typeof operation.updatedAtMs === 'number' ? operation.updatedAtMs : nowMs;
  if (operation.status === 'processing') return updatedAtMs <= nowMs - MAX_STAGED_AGE_MS;
  if (operation.status === 'waiting') {
    const readyAtMs = typeof operation.readyAtMs === 'number' ? operation.readyAtMs : nowMs;
    return updatedAtMs <= nowMs - MAX_STAGED_AGE_MS && readyAtMs <= nowMs - MAX_STAGED_AGE_MS;
  }
  return false;
}

export type StagedImageSweepResult = {
  examined: number;
  deleted: number;
  protectedActive: number;
  failed: number;
};

/** Bounded maintenance operation. It queries only expired metadata, never scans
 * the bucket, verifies the authoritative operation immediately before delete,
 * and leaves metadata in place when object deletion fails so retries remain safe. */
export class FirestoreStagedImageRetentionSweeper {
  constructor(
    private readonly firestore: Firestore,
    private readonly storage: Storage,
    private readonly bucketName: string,
  ) {}

  async sweep(nowMs = Date.now(), limit = 100): Promise<StagedImageSweepResult> {
    const result: StagedImageSweepResult = { examined: 0, deleted: 0, protectedActive: 0, failed: 0 };
    const expired = await this.firestore.collection('readingOperationStagedImages')
      .where('expiresAt', '<=', Timestamp.fromMillis(nowMs)).limit(Math.min(Math.max(limit, 1), 500)).get();
    for (const staged of expired.docs) {
      result.examined++;
      try {
        const data = staged.data();
        const operationId = data.operationId;
        const objectPath = data.objectPath;
        if (typeof operationId !== 'string' || typeof objectPath !== 'string' || !objectPath.startsWith('reading-staging/')) {
          result.failed++;
          continue;
        }
        const operation = await this.firestore.collection('readingOperations').doc(operationId).get();
        if (!mayDeleteExpiredStagedInput(operation.exists ? operation.data() : undefined, nowMs)) {
          result.protectedActive++;
          continue;
        }
        await this.storage.bucket(this.bucketName).file(objectPath).delete({ ignoreNotFound: true });
        await staged.ref.delete();
        result.deleted++;
      } catch {
        result.failed++;
      }
    }
    return result;
  }
}
