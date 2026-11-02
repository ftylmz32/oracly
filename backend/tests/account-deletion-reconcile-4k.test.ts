/**
 * Aşama 4K — accepted receipts are no longer trusted as "data gone".
 *
 * Models the two switch-window failures:
 *   1. an OLDER revision accepted a deletion without sweeping the quota /
 *      speech collections (its receipt says `accepted`, records remain);
 *   2. an OLD worker (no quota barrier) writes a record after the sweep.
 * The real repository + DeletionAdapter over the in-memory store; a GCS
 * stand-in holding speech clips beside other features' objects.
 */
import type { Firestore } from '@google-cloud/firestore';
import type { Storage } from '@google-cloud/storage';
import { describe, expect, it } from 'vitest';
import { FirestoreAccountDeletionRepository } from '../src/account/account-deletion.js';
import { ACCOUNT_DELETION_RECEIPTS, accountDeletionReceiptId } from '../src/account/deletion-barrier.js';
import { applyDeletionReconcile, planDeletionReconcile, type ReceiptState } from '../src/account/deletion-reconcile-plan.js';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { speechOwnerPrefix } from '../src/reading/speech-retention.js';
import { DeletionAdapter } from './support/deletion-adapter.js';

const A = identityKeyFromSubject('reconcile-a');
const B = identityKeyFromSubject('reconcile-b');
const LEFTOVER = ['freeTextQuota', 'freeTextQuotaAttempts', 'ritualDailyQuota', 'ritualDailyQuotaAttempts',
  'speechGrants', 'speechPreviewDay'] as const;

class Gcs {
  readonly objects = new Set<string>();
  failDeleteOnce = false;
  failListOnce = false;
  asStorage(): Storage {
    const self = this;
    return {
      bucket: () => ({
        async getFiles(o: { prefix: string }) {
          if (self.failListOnce) { self.failListOnce = false; throw new Error('injected gcs list failure'); }
          return [[...self.objects].filter((n) => n.startsWith(o.prefix)).map((name) => ({ name }))];
        },
        file: (name: string) => ({
          async delete() {
            if (self.failDeleteOnce) { self.failDeleteOnce = false; throw new Error('injected gcs delete failure'); }
            self.objects.delete(name);
          },
        }),
      }),
    } as unknown as Storage;
  }
}

function world() {
  const store = new MemoryDocumentStore();
  const gcs = new Gcs();
  const adapter = new DeletionAdapter(store);
  const repo = new FirestoreAccountDeletionRepository(adapter as unknown as Firestore, gcs.asStorage(), 'test-bucket');
  const put = async (collection: string, id: string, data: Record<string, unknown>) =>
    store.runTransaction(async (tx) => { tx.set(store.collection(collection).doc(id), data); });
  const receipt = (owner: string) =>
    store.docs.get(`${ACCOUNT_DELETION_RECEIPTS}/${accountDeletionReceiptId(owner)}`) as Record<string, unknown> | undefined;
  const owned = (owner: string) => [...store.docs.entries()]
    .filter(([path, data]) => !path.startsWith(`${ACCOUNT_DELETION_RECEIPTS}/`)
      && (data.identity === owner || data.ownerUserId === owner)).length;
  const clip = (owner: string, n: number) => `${speechOwnerPrefix(owner)}${String(n).repeat(32)}/${'a'.repeat(20)}.mp3`;

  /** Leftovers an older revision leaves behind (it never swept these). */
  async function leftovers(owner: string, tag: string) {
    for (const c of LEFTOVER) await put(c, `${c}-${tag}`, { identity: owner, body: 'eski yanıt' });
    gcs.objects.add(clip(owner, 1));
    gcs.objects.add(clip(owner, 2)); // orphan MP3 (no record points at it)
  }
  /** The receipt an older revision writes after its incomplete sweep. */
  async function oldAcceptedReceipt(owner: string) {
    await put(ACCOUNT_DELETION_RECEIPTS, accountDeletionReceiptId(owner), {
      receiptId: accountDeletionReceiptId(owner), status: 'accepted', completedAt: '2026-10-30T10:00:00.000Z',
      deletedDocuments: 3, deletedObjects: 0, anonymizedPurchaseBindings: 0,
    });
  }
  return { store, gcs, adapter, repo, put, receipt, owned, clip, leftovers, oldAcceptedReceipt };
}

describe('4K: accepted receipt from an older revision with leftovers', () => {
  it('a repeated deletion request re-sweeps; the original receipt is answered and annotated', async () => {
    const w = world();
    await w.leftovers(A, 'a');
    await w.leftovers(B, 'b');
    await w.oldAcceptedReceipt(A);
    const res = await w.repo.deleteForIdentity(A);
    expect(res).toMatchObject({ receiptId: accountDeletionReceiptId(A), status: 'accepted', completedAt: '2026-10-30T10:00:00.000Z' });
    expect(w.owned(A)).toBe(0);
    expect([...w.gcs.objects].filter((n) => n.startsWith(speechOwnerPrefix(A)))).toEqual([]);
    const r = w.receipt(A)!;
    expect(r.status).toBe('accepted');
    expect(r.reconciledDocuments).toBe(LEFTOVER.length);
    expect(r.reconciledObjects).toBe(2);
    expect(typeof r.reconciledAt).toBe('string');
    // B untouched
    expect(w.owned(B)).toBe(LEFTOVER.length);
    expect([...w.gcs.objects].filter((n) => n.startsWith(speechOwnerPrefix(B)))).toHaveLength(2);
  });

  it('reconcileDeletedIdentity cleans the same leftovers (speech grant + orphan MP3)', async () => {
    const w = world();
    await w.leftovers(A, 'a');
    await w.oldAcceptedReceipt(A);
    const out = await w.repo.reconcileDeletedIdentity(A);
    expect(out).toMatchObject({ status: 'reconciled', deletedDocuments: LEFTOVER.length, deletedObjects: 2 });
    expect(w.owned(A)).toBe(0);
  });

  it('never touches an identity without an accepted receipt', async () => {
    const w = world();
    await w.leftovers(B, 'b');
    expect(await w.repo.reconcileDeletedIdentity(B)).toEqual({ status: 'skipped', reason: 'no_receipt' });
    await w.put(ACCOUNT_DELETION_RECEIPTS, accountDeletionReceiptId(B), { status: 'deleting' });
    expect(await w.repo.reconcileDeletedIdentity(B)).toEqual({ status: 'skipped', reason: 'not_accepted' });
    expect(w.owned(B)).toBe(LEFTOVER.length);
  });
});

describe('4K: already complete deletions are unchanged', () => {
  it('re-processing a fully deleted account changes nothing (no annotation, same receipt)', async () => {
    const w = world();
    await w.leftovers(A, 'a');
    const first = await w.repo.deleteForIdentity(A);
    const before = JSON.stringify(w.receipt(A));
    const again = await w.repo.deleteForIdentity(A);
    expect(again).toMatchObject({ receiptId: first.receiptId, status: 'accepted', completedAt: first.completedAt });
    expect(JSON.stringify(w.receipt(A))).toBe(before);
    expect(w.receipt(A)!.reconciledAt).toBeUndefined();
  });

  it('two concurrent deletion requests: both accepted, all data gone, B kept', async () => {
    const w = world();
    await w.leftovers(A, 'a');
    await w.leftovers(B, 'b');
    const [x, y] = await Promise.all([w.repo.deleteForIdentity(A), w.repo.deleteForIdentity(A)]);
    expect(x.status).toBe('accepted');
    expect(y.status).toBe('accepted');
    expect(w.owned(A)).toBe(0);
    expect(w.receipt(A)!.status).toBe('accepted');
    expect(w.owned(B)).toBe(LEFTOVER.length);
  });
});

describe('4K: failures are never reported as cleaned', () => {
  it('GCS delete failure during reconciliation rejects; records stay; retry completes', async () => {
    const w = world();
    await w.leftovers(A, 'a');
    await w.oldAcceptedReceipt(A);
    w.gcs.failDeleteOnce = true;
    await expect(w.repo.deleteForIdentity(A)).rejects.toThrow(/injected gcs delete failure/);
    expect(w.receipt(A)!.reconciledAt).toBeUndefined();
    expect(w.owned(A)).toBe(LEFTOVER.length);
    await w.repo.deleteForIdentity(A);
    expect(w.owned(A)).toBe(0);
    expect(w.receipt(A)!.reconciledObjects).toBe(2);
  });

  it('GCS list failure and Firestore failure reject; retry completes', async () => {
    const w = world();
    await w.leftovers(A, 'a');
    await w.oldAcceptedReceipt(A);
    w.gcs.failListOnce = true;
    await expect(w.repo.reconcileDeletedIdentity(A)).rejects.toThrow(/injected gcs list failure/);
    w.adapter.failOnce = 'freeTextQuotaAttempts';
    await expect(w.repo.reconcileDeletedIdentity(A)).rejects.toThrow(/injected failure/);
    expect(w.owned(A)).toBeGreaterThan(0);
    expect(await w.repo.reconcileDeletedIdentity(A)).toMatchObject({ status: 'reconciled' });
    expect(w.owned(A)).toBe(0);
  });
});

describe('4K: late write from an old worker after the deletion', () => {
  it('is detected by exact receipt match and reconciled; B and receipt-less owners are not selected', async () => {
    const w = world();
    await w.leftovers(B, 'b');
    await w.repo.deleteForIdentity(A); // complete deletion by the new code
    // Old worker (no quota barrier) settles a reading after the sweep:
    await w.put('ritualDailyQuotaAttempts', 'late-a', { identity: A, body: 'geç gelen yanıt', status: 'final' });
    await w.put('ritualDailyQuota', 'late-a-day', { identity: A, count: 1 });

    const receipts = new Map<string, ReceiptState>();
    for (const [path, data] of w.store.docs) {
      if (path.startsWith(`${ACCOUNT_DELETION_RECEIPTS}/`)) {
        receipts.set(path.split('/')[1]!, data.status === 'accepted' ? 'accepted' : 'other');
      }
    }
    const records = [...w.store.docs.entries()]
      .filter(([path]) => !path.startsWith(`${ACCOUNT_DELETION_RECEIPTS}/`))
      .map(([path, data]) => ({ collection: path.split('/')[0]!, owner: String(data.identity ?? data.ownerUserId ?? '') }));
    const plan = planDeletionReconcile({ records, receipts });
    expect(plan.identities).toEqual([A]);
    expect(plan.leftoverByCollection).toEqual({ ritualDailyQuotaAttempts: 1, ritualDailyQuota: 1 });
    expect(plan.ownersWithoutReceipt).toBe(1); // B

    const applied = await applyDeletionReconcile(plan, w.repo, { maxIdentities: 5 });
    expect(applied).toMatchObject({ reconciled: 1, skipped: 0, deletedDocuments: 2 });
    expect(w.owned(A)).toBe(0);
    expect(w.owned(B)).toBe(LEFTOVER.length);
    expect(w.receipt(A)!.reconciledDocuments).toBe(2);
  });

  it('apply refuses a plan over the cap and does nothing', async () => {
    const w = world();
    await w.leftovers(A, 'a');
    await w.oldAcceptedReceipt(A);
    const plan = planDeletionReconcile({
      records: [{ collection: 'freeTextQuota', owner: A }],
      receipts: new Map([[accountDeletionReceiptId(A), 'accepted' as const]]),
    });
    await expect(applyDeletionReconcile(plan, w.repo, { maxIdentities: 0 })).rejects.toThrow(/over_cap/);
    expect(w.owned(A)).toBe(LEFTOVER.length);
  });
});
