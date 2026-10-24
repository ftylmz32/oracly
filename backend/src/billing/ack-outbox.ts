/**
 * Durable, server-only outbox for Play acknowledgements that failed after a
 * purchase was verified and bound to its owner. A delayed Cloud Task on the
 * dedicated billing-acknowledge queue retries each one (a sweep re-creates
 * lost tasks), so a paid purchase no longer
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

/** A task due longer ago than this and still pending is treated as lost. */
export const ACK_LOST_GRACE_MS = 15 * 60_000;

/** Pending this long is overdue: alert, Play's 3-day window is closing. */
export const ACK_OVERDUE_MS = 60 * 3_600_000;

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
  /** When the next retry task is due to run. */
  nextAttemptAtMs?: number;
  /** The retry task could not be created; the sweep re-creates it. */
  scheduleFailed?: boolean;
};

export interface AckOutbox {
  /** Creates the entry unless one exists. True when it was created. */
  create(entry: AckOutboxEntry): Promise<boolean>;
  get(id: string): Promise<AckOutboxEntry | null>;
  update(id: string, patch: Partial<AckOutboxEntry>): Promise<void>;
  /** Pending entries, for the sweep. */
  listPending(limit: number): Promise<AckOutboxEntry[]>;
}

export type AckRetryInput = {
  id: string;
  attempt: number;
  atMs: number;
  /**
   * Suffix for a re-created task. Cloud Tasks reserves a used task name
   * for a while, so a sweep re-creation needs its own name or the 409
   * would be taken for an existing task and the retry lost.
   */
  key?: string;
};

export interface AckRetryScheduler {
  schedule(input: AckRetryInput): Promise<void>;
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

  async listPending(limit: number): Promise<AckOutboxEntry[]> {
    return (await this.all()).slice(0, limit);
  }

  /** Pending ones only, as tests and support see the queue. */
  async all(): Promise<AckOutboxEntry[]> {
    return [...this.entries.values()]
      .filter((e) => e.status === 'pending')
      .map((e) => ({ ...e }));
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

  async listPending(limit: number): Promise<AckOutboxEntry[]> {
    const snap = await this.db
      .collection('billingAckOutbox')
      .where('status', '==', 'pending')
      .limit(limit)
      .get();
    return snap.docs.map((d) => d.data() as AckOutboxEntry);
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

/** No billing queue configured: scheduling fails loudly, never silently. */
export class UnconfiguredAckRetryScheduler implements AckRetryScheduler {
  async schedule(): Promise<void> {
    throw new Error('ack_retry_scheduler_unconfigured');
  }
}

/**
 * Delayed retry on the dedicated billing-acknowledge Cloud Tasks queue,
 * authenticated with the billing task service account. A duplicate task
 * name (same entry and attempt) is ignored.
 */
export class CloudTasksAckRetryScheduler implements AckRetryScheduler {
  constructor(
    private readonly config: AppConfig,
    private readonly auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    }),
  ) {}

  async schedule(input: AckRetryInput) {
    const c = this.config;
    if (!billingAckConfigured(c)) {
      throw new Error('ack_retry_scheduler_unconfigured');
    }
    const parent =
      `projects/${c.firebaseProjectId}/locations/${c.billingAckLocation}` +
      `/queues/${c.billingAckQueue}`;
    const target = c.billingAckTargetUrl!;
    try {
      await this.auth.request({
        url: `https://cloudtasks.googleapis.com/v2/${parent}/tasks`,
        method: 'POST',
        data: {
          task: {
            name:
              `${parent}/tasks/billing-ack-${input.id}-${input.attempt}` +
              (input.key ? `-${input.key}` : ''),
            scheduleTime: new Date(input.atMs).toISOString(),
            httpRequest: {
              httpMethod: 'POST',
              url: target,
              headers: { 'Content-Type': 'application/json' },
              body: Buffer.from(JSON.stringify({ id: input.id })).toString('base64'),
              oidcToken: {
                serviceAccountEmail: c.billingAckServiceAccount,
                audience: c.billingAckAudience,
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

function billingAckConfigured(c: AppConfig): boolean {
  return Boolean(
    c.firebaseProjectId &&
      c.billingAckQueue &&
      c.billingAckTargetUrl &&
      c.billingAckAudience &&
      c.billingAckServiceAccount,
  );
}

export function createAckRetryScheduler(config: AppConfig): AckRetryScheduler {
  return billingAckConfigured(config)
    ? new CloudTasksAckRetryScheduler(config)
    : new UnconfiguredAckRetryScheduler();
}
