import { createHash } from 'node:crypto';
import { Firestore, Timestamp } from '@google-cloud/firestore';
import type { AppConfig } from '../config.js';
export interface SharedWindowStore { consume(scope: string, key: string, max: number, windowMs: number): Promise<boolean>; }
export class FirestoreSharedWindowStore implements SharedWindowStore {
  constructor(private readonly firestore: Firestore) {}
  async consume(scope: string, key: string, max: number, windowMs: number): Promise<boolean> {
    const now = Date.now(); const bucket = Math.floor(now / windowMs);
    const id = createHash('sha256').update(`${scope}\0${key}\0${bucket}`).digest('hex');
    const ref = this.firestore.collection('securityRateWindows').doc(id);
    return this.firestore.runTransaction(async tx => {
      const snap = await tx.get(ref); const raw = snap.data()?.count;
      const count = typeof raw === 'number' ? raw : 0;
      if (count >= max) return false;
      tx.set(ref, { scope, bucket, count: count + 1, expiresAt: Timestamp.fromMillis((bucket + 2) * windowMs), updatedAt: Timestamp.now() });
      return true;
    });
  }
}
export class MemorySharedWindowStore implements SharedWindowStore {
  private readonly counts = new Map<string, number>();
  async consume(scope: string, key: string, max: number, windowMs: number): Promise<boolean> {
    const id = `${scope}|${key}|${Math.floor(Date.now() / windowMs)}`; const count = this.counts.get(id) ?? 0;
    if (count >= max) return false; this.counts.set(id, count + 1); return true;
  }
}
export class FailClosedSharedWindowStore implements SharedWindowStore { async consume(): Promise<boolean> { return false; } }
export function createSharedWindowStore(config: AppConfig): SharedWindowStore {
  if (!config.entitlementDurableRequired) return new MemorySharedWindowStore();
  if (!config.firebaseProjectId) return new FailClosedSharedWindowStore();
  try { return new FirestoreSharedWindowStore(new Firestore({ projectId: config.firebaseProjectId, databaseId: config.firestoreDatabaseId })); }
  catch { return new FailClosedSharedWindowStore(); }
}
