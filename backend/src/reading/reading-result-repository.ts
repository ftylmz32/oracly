import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { Timestamp } from '@google-cloud/firestore';
import type { ReadingGenerationTrace } from './provider-stage-repository.js';

const RESULTS = 'readingOperationResults';

export type ReadingOperationResult = {
  schemaVersion: 1;
  operationId: string;
  ownerUserId: string;
  readingType: 'coffee' | 'palm' | 'soulmate';
  resultId: string;
  data: Record<string, unknown>;
  persistedAtMs: number;
  notificationSentAtMs: number | null;
  generationTrace?: ReadingGenerationTrace;
};

export class ReadingResultRepository {
  constructor(private readonly firestore: FirestoreLike) {}

  async get(operationId: string): Promise<ReadingOperationResult | null> {
    const snap = await this.firestore.collection(RESULTS).doc(operationId).get();
    return parseResult(snap.data());
  }

  async persistOnce(record: ReadingOperationResult): Promise<ReadingOperationResult> {
    const ref = this.firestore.collection(RESULTS).doc(record.operationId);
    return this.firestore.runTransaction(async (tx) => {
      const existing = parseResult((await tx.get(ref)).data());
      if (existing) return existing;
      tx.set(ref, { ...record, expiresAt: Timestamp.fromMillis(record.persistedAtMs + 30 * 86_400_000) });
      return record;
    });
  }

  async markNotificationSent(operationId: string, atMs: number): Promise<boolean> {
    const ref = this.firestore.collection(RESULTS).doc(operationId);
    return this.firestore.runTransaction(async (tx) => {
      const current = parseResult((await tx.get(ref)).data());
      if (!current || current.notificationSentAtMs != null) return false;
      tx.set(ref, { ...current, notificationSentAtMs: atMs });
      return true;
    });
  }
}

function parseResult(data: Record<string, unknown> | undefined): ReadingOperationResult | null {
  if (!data || data.schemaVersion !== 1) return null;
  if (typeof data.operationId !== 'string' || typeof data.ownerUserId !== 'string') return null;
  if (data.readingType !== 'coffee' && data.readingType !== 'palm' && data.readingType !== 'soulmate') return null;
  if (typeof data.resultId !== 'string' || !data.data || typeof data.data !== 'object') return null;
  if (typeof data.persistedAtMs !== 'number') return null;
  return {
    schemaVersion: 1,
    operationId: data.operationId,
    ownerUserId: data.ownerUserId,
    readingType: data.readingType,
    resultId: data.resultId,
    data: data.data as Record<string, unknown>,
    persistedAtMs: data.persistedAtMs,
    notificationSentAtMs:
      typeof data.notificationSentAtMs === 'number' ? data.notificationSentAtMs : null,
    generationTrace: parseTrace(data.generationTrace),
  };
}

function parseTrace(value: unknown): ReadingGenerationTrace | undefined {
  if (!value || typeof value !== 'object') return undefined;
  const trace = value as Record<string, unknown>;
  return typeof trace.pipelineVersion === 'string' && typeof trace.interpretationContractVersion === 'string' &&
    typeof trace.promptRulesVersion === 'string' && typeof trace.modelIdentifier === 'string'
    ? trace as ReadingGenerationTrace : undefined;
}
