import { createHash } from 'node:crypto';
import { Firestore, Timestamp } from '@google-cloud/firestore';
import type { AppConfig } from '../config.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { AccountDeletedError, assertNoDeletionBarrier } from '../account/deletion-barrier.js';

export const CONTENT_REPORTS_COLLECTION = 'aiContentReports';
export const CONTENT_REPORT_RETENTION_MS = 30 * 24 * 60 * 60 * 1_000;

export type ContentReportRecord = {
  reportId: string;
  ownerUserId: string;
  feature: string;
  category: string;
  contentRef: string | null;
  reportedContent: string | null;
  contentSource: 'user_selected_unverified' | null;
  createdAtMs: number;
  expiresAtMs: number;
  status: 'open';
};

export type ContentReportCreateResult = {
  created: boolean;
  record: ContentReportRecord;
};

export interface ContentReportRepository {
  createIfAbsent(record: ContentReportRecord): Promise<ContentReportCreateResult>;
}

export class ContentReportStorageUnavailable extends Error {
  constructor() {
    super('content_report_storage_unavailable');
    this.name = 'ContentReportStorageUnavailable';
  }
}

export class FirestoreContentReportRepository implements ContentReportRepository {
  constructor(private readonly firestore: FirestoreLike) {}

  async createIfAbsent(record: ContentReportRecord): Promise<ContentReportCreateResult> {
    const id = createHash('sha256')
      .update(`${record.ownerUserId}\0${record.reportId}`)
      .digest('hex');
    const ref = this.firestore.collection(CONTENT_REPORTS_COLLECTION).doc(id);
    try {
      return await this.firestore.runTransaction(async (tx) => {
        // This read must share the report-write transaction: a deletion that
        // wins first blocks the report, while a report that wins first is
        // visible to the subsequent account-deletion sweep.
        await assertNoDeletionBarrier(tx, this.firestore, record.ownerUserId);
        const existing = await tx.get(ref);
        if (existing.exists) {
          const data = existing.data();
          if (data?.ownerUserId !== record.ownerUserId || data?.reportId !== record.reportId) {
            throw new ContentReportStorageUnavailable();
          }
          return { created: false, record: parseRecord(data) ?? record };
        }
        tx.set(ref, {
          ...record,
          createdAt: Timestamp.fromMillis(record.createdAtMs),
          expiresAt: Timestamp.fromMillis(record.expiresAtMs),
        });
        return { created: true, record };
      });
    } catch (error) {
      if (error instanceof ContentReportStorageUnavailable || error instanceof AccountDeletedError) throw error;
      throw new ContentReportStorageUnavailable();
    }
  }
}

export class FailClosedContentReportRepository implements ContentReportRepository {
  async createIfAbsent(): Promise<ContentReportCreateResult> {
    throw new ContentReportStorageUnavailable();
  }
}

export function createContentReportRepository(config: AppConfig): ContentReportRepository {
  if (!config.firebaseProjectId || !config.entitlementDurableRequired) {
    return new FailClosedContentReportRepository();
  }
  try {
    return new FirestoreContentReportRepository(new Firestore({
      projectId: config.firebaseProjectId,
      databaseId: config.firestoreDatabaseId,
    }));
  } catch {
    return new FailClosedContentReportRepository();
  }
}

function parseRecord(value: Record<string, unknown> | undefined): ContentReportRecord | null {
  if (!value || typeof value.reportId !== 'string' || typeof value.ownerUserId !== 'string') {
    return null;
  }
  return {
    reportId: value.reportId,
    ownerUserId: value.ownerUserId,
    feature: typeof value.feature === 'string' ? value.feature : 'unknown',
    category: typeof value.category === 'string' ? value.category : 'other',
    contentRef: typeof value.contentRef === 'string' ? value.contentRef : null,
    reportedContent: typeof value.reportedContent === 'string' ? value.reportedContent : null,
    contentSource: value.contentSource === 'user_selected_unverified' ? value.contentSource : null,
    createdAtMs: typeof value.createdAtMs === 'number' ? value.createdAtMs : 0,
    expiresAtMs: typeof value.expiresAtMs === 'number' ? value.expiresAtMs : 0,
    status: 'open',
  };
}
