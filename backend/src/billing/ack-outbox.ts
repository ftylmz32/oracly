/**
 * Durable, server-only outbox for Play acknowledgements that failed after a
 * purchase was verified and bound to its owner. A delayed Cloud Task on the
 * existing reading queue retries each one, so a paid purchase no longer
 * depends on the app reopening to escape Play's automatic refund.
 *
 * Entries hold the raw purchase token (needed to call Play later), so the
 * collection is backend-only: clients never read it and responses never
 * carry it. The document id is a SHA-256 of platform + token.
 */
import { createHash } from 'node:crypto';
import { Firestore } from '@google-cloud/firestore';
import { GoogleAuth } from 'google-auth-library';
import type { AppConfig } from '../config.js';

/**
 * Backoff between retries. Sums to under two days, inside Play's 3-day
 * acknowledgement window, after which an entry is closed as `gave_up`.
 */
export const ACK_RETRY_DELAYS_MS: readonly number[] = [
  60_000,
  5 * 60_000,
  15 * 60_000,
  60 * 60_000,
  3 * 3_600_000,
  6 * 3_600_000,
  12 * 3_600_000,
  24 * 3_600_000,
];

export type AckOutboxStatus = 'pending' | 'done' | 'closed';

export type AckOutboxEntry = {
  id: string;
  platform: 'android';
  productId: string;
  purchaseToken: string;
  /** The verify route's identity key the purchase was bound to. */
  ownerIdentityKey: string;
  attempts: number;
  status: AckOutboxStatus;
  lastReason?: string;
  createdAtMs: number;
  updatedAtMs: number;
};

export interface AckOutbox {
  /** Creates the entry unless one exists. True when it was created. */
  create(entry: AckOutboxEntry): Promise<boolean>;
  get(id: string): Promise<AckOutboxEntry | null>;
  update(id: string, patch: Partial<AckOutboxEntry>): Promise<void>;
}

export interface AckRetryScheduler {
  schedule(input: { id: string; attempt: number; atMs: number }): Promise<void>;
}

export type BillingAckOptions = {
  outbox?: AckOutbox | null;
  scheduler?: AckRetryScheduler;
  /** Verifies the caller is our Cloud Task (OIDC). */
  verifyTask?: (request: import('fastify').FastifyRequest) => Promise<boolean>;
  now?: () => number;
};

export function ackOutboxId(platform: string, purchaseToken: string): string {
  return createHash('sha256').update(`${platform}:${purchaseToken}`, 'utf8').digest('hex');
}

export class InMemoryAckOutbox implements AckOutbox {
  private readonly entries = new Map<string, AckOutboxEntry>();

  async create(entry: AckOutboxEntry): Promise<boolean> {
    if (this.entries.has(entry.id)) return false;
    this.entries.set(entry.id, { ...entry });
    return true;
  }

  async get(id: string): Promise<AckOutboxEntry | null> {
    const entry = this.entries.get(id);
    return entry ? { ...entry } : null;
  }

  async update(id: string, patch: Partial<AckOutboxEntry>): Promise<void> {
    const entry = this.entries.get(id);
    if (entry) this.entries.set(id, { ...entry, ...patch });
  }

  /** Pending ones only, as tests and support see the queue. */
  async all(): Promise<AckOutboxEntry[]> {
    return [...this.entries.values()].filter((e) => e.status === 'pending');
  }

  async rewriteOwnerForTest(id: string, owner: string): Promise<void> {
    await this.update(id, { ownerIdentityKey: owner });
  }
}

type FirestoreLike = Pick<Firestore, 'collection'>;

export class FirestoreAckOutbox implements AckOutbox {
  constructor(private readonly db: FirestoreLike) {}

  private doc(id: string) {
    return this.db.collection('billingAckOutbox').doc(id);
  }

  async create(entry: AckOutboxEntry): Promise<boolean> {
    try {
      await this.doc(entry.id).create(entry);
      return true;
    } catch (error) {
      // ALREADY_EXISTS (gRPC 6): one entry per purchase token.
      if ((error as { code?: number }).code === 6) return false;
      throw error;
    }
  }

  async get(id: string): Promise<AckOutboxEntry | null> {
    const snap = await this.doc(id).get();
    return snap.exists ? (snap.data() as AckOutboxEntry) : null;
  }

  async update(id: string, patch: Partial<AckOutboxEntry>): Promise<void> {
    await this.doc(id).update(patch);
  }
}

let sharedFirestore: Firestore | null = null;

/** Null when no durable store is configured: the inline retry still runs. */
export function createAckOutbox(config: AppConfig): AckOutbox | null {
  if (!config.entitlementDurableRequired) return new InMemoryAckOutbox();
  if (!config.firebaseProjectId) return null;
  try {
    sharedFirestore ??= new Firestore({
      projectId: config.firebaseProjectId,
      databaseId: config.firestoreDatabaseId,
    });
    return new FirestoreAckOutbox(sharedFirestore);
  } catch {
    return null;
  }
}

export class NoopAckRetryScheduler implements AckRetryScheduler {
  async schedule(): Promise<void> {}
}

/**
 * Delayed retry on the existing reading Cloud Tasks queue, authenticated
 * with the same OIDC service account and audience. Targets this service's
 * own origin. A duplicate task name (same entry and attempt) is ignored.
 */
export class CloudTasksAckRetryScheduler implements AckRetryScheduler {
  constructor(
    private readonly config: AppConfig,
    private readonly auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    }),
  ) {}

  async schedule(input: { id: string; attempt: number; atMs: number }) {
    const c = this.config;
    if (
      !c.firebaseProjectId ||
      !c.readingTaskQueue ||
      !c.readingTaskTargetUrl ||
      !c.readingTaskAudience ||
      !c.readingTaskServiceAccount
    ) {
      throw new Error('ack_retry_scheduler_unconfigured');
    }
    const parent =
      `projects/${c.firebaseProjectId}/locations/${c.readingTaskLocation}` +
      `/queues/${c.readingTaskQueue}`;
    const target = `${new URL(c.readingTaskTargetUrl).origin}/internal/billing/acknowledge-retry`;
    try {
      await this.auth.request({
        url: `https://cloudtasks.googleapis.com/v2/${parent}/tasks`,
        method: 'POST',
        data: {
          task: {
            name: `${parent}/tasks/billing-ack-${input.id}-${input.attempt}`,
            scheduleTime: new Date(input.atMs).toISOString(),
            httpRequest: {
              httpMethod: 'POST',
              url: target,
              headers: { 'Content-Type': 'application/json' },
              body: Buffer.from(JSON.stringify({ id: input.id })).toString('base64'),
              oidcToken: {
                serviceAccountEmail: c.readingTaskServiceAccount,
                audience: c.readingTaskAudience,
              },
            },
          },
        },
      });
    } catch (error) {
      const status = (error as { response?: { status?: number } }).response?.status;
      if (status === 409) return;
      throw error;
    }
  }
}

export function createAckRetryScheduler(config: AppConfig): AckRetryScheduler {
  return config.firebaseProjectId &&
    config.readingTaskQueue &&
    config.readingTaskTargetUrl &&
    config.readingTaskAudience &&
    config.readingTaskServiceAccount
    ? new CloudTasksAckRetryScheduler(config)
    : new NoopAckRetryScheduler();
}
