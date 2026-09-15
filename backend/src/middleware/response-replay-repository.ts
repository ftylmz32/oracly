import { createHash, randomUUID } from 'node:crypto';
import { Firestore, Timestamp } from '@google-cloud/firestore';
import type { AppConfig } from '../config.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';

export const RESPONSE_REPLAY_TTL_MS = 10 * 60_000;
export type ReplayEntry = { status: number; body: unknown; contentType: string; expiresAtMs: number };
export type ReplayClaim =
  | { kind: 'producer'; attemptId: string }
  | { kind: 'in_progress'; expiresAtMs: number }
  | { kind: 'completed'; entry: ReplayEntry };

export interface ResponseReplayRepository {
  claim(identity: string, key: string): Promise<ReplayClaim>;
  complete(identity: string, key: string, attemptId: string, entry: Omit<ReplayEntry, 'expiresAtMs'>): Promise<void>;
}

export class FirestoreResponseReplayRepository implements ResponseReplayRepository {
  constructor(private readonly firestore: FirestoreLike, private readonly now: () => number = Date.now) {}
  private ref(identity: string, key: string) {
    const id = createHash('sha256').update(`${identity}\0${key}`).digest('hex');
    return this.firestore.collection('responseReplay').doc(id);
  }
  async claim(identity: string, key: string): Promise<ReplayClaim> {
    const now = this.now(); const attemptId = randomUUID(); const ref = this.ref(identity, key);
    return this.firestore.runTransaction(async tx => {
      const snap = await tx.get(ref); const data = snap.data();
      if (data && typeof data.expiresAtMs === 'number' && data.expiresAtMs > now) {
        if (data.state === 'completed' && typeof data.status === 'number') return { kind: 'completed', entry: {
          status: data.status, body: data.body, contentType: typeof data.contentType === 'string' ? data.contentType : 'application/json', expiresAtMs: data.expiresAtMs,
        }};
        if (data.state === 'in_progress') return { kind: 'in_progress', expiresAtMs: data.expiresAtMs };
      }
      tx.set(ref, { state: 'in_progress', attemptId, expiresAtMs: now + RESPONSE_REPLAY_TTL_MS, expiresAt: Timestamp.fromMillis(now + RESPONSE_REPLAY_TTL_MS), updatedAtMs: now });
      return { kind: 'producer', attemptId };
    });
  }
  async complete(identity: string, key: string, attemptId: string, entry: Omit<ReplayEntry, 'expiresAtMs'>): Promise<void> {
    const now = this.now(); const ref = this.ref(identity, key);
    await this.firestore.runTransaction(async tx => {
      const snap = await tx.get(ref); const data = snap.data();
      if (!data || data.state !== 'in_progress' || data.attemptId !== attemptId) throw new Error('replay_claim_lost');
      tx.set(ref, { state: 'completed', status: entry.status, body: entry.body, contentType: entry.contentType, expiresAtMs: now + RESPONSE_REPLAY_TTL_MS, expiresAt: Timestamp.fromMillis(now + RESPONSE_REPLAY_TTL_MS), updatedAtMs: now });
    });
  }
}

export class FailClosedResponseReplayRepository implements ResponseReplayRepository {
  async claim(): Promise<ReplayClaim> { throw new Error('response_replay_unavailable'); }
  async complete(): Promise<void> { throw new Error('response_replay_unavailable'); }
}

export function createResponseReplayRepository(config: AppConfig): ResponseReplayRepository {
  if (!config.firebaseProjectId || !config.entitlementDurableRequired) return new FailClosedResponseReplayRepository();
  try { return new FirestoreResponseReplayRepository(new Firestore({ projectId: config.firebaseProjectId, databaseId: config.firestoreDatabaseId })); }
  catch { return new FailClosedResponseReplayRepository(); }
}
