import { describe, expect, it } from 'vitest';
import type { Firestore } from '@google-cloud/firestore';
import { FirestoreAccountDeletionRepository } from '../src/account/account-deletion.js';

/**
 * R2.1 Phase 2.B — proves what was previously only implicit: real account
 * deletion already purges EVERY server-known notification-token record for
 * the deleting owner (both the owner->token doc `reading-notifications.ts`
 * keys by hashed ownerUserId, and the token->owner doc it keys by hashed
 * token), via the same generic `DELETE_COLLECTIONS` sweep used for every
 * other owner-scoped collection. No new deletion logic was added — this
 * test exists to make that guarantee explicit and regression-proof.
 */
class DeletionFakeFirestore {
  private readonly store = new Map<string, Record<string, unknown>>();

  seed(path: string, data: Record<string, unknown>): void {
    this.store.set(path, data);
  }

  has(path: string): boolean {
    return this.store.has(path);
  }

  collection(name: string) {
    const self = this;
    return {
      doc(id: string) {
        const path = `${name}/${id}`;
        return {
          id,
          async get() {
            const data = self.store.get(path);
            return { exists: data !== undefined, data: () => data };
          },
          async set(data: Record<string, unknown>) {
            self.store.set(path, data);
          },
        };
      },
      where(field: string, _op: string, value: unknown) {
        const matching = () =>
          [...self.store.entries()]
            .filter(([path]) => path.startsWith(`${name}/`))
            .filter(([, data]) => data[field] === value)
            .map(([path, data]) => ({
              ref: {
                delete: async () => {
                  self.store.delete(path);
                },
              },
              data: () => data,
            }));
        return {
          async get() {
            const docs = matching();
            return { docs, empty: docs.length === 0, size: docs.length };
          },
        };
      },
    };
  }

  batch() {
    const ops: Array<() => Promise<void>> = [];
    return {
      delete(ref: { delete: () => Promise<void> }) {
        ops.push(() => ref.delete());
      },
      async commit() {
        for (const op of ops) await op();
      },
    };
  }

  async runTransaction<T>(): Promise<T> {
    throw new Error('not exercised by this fake — no purchaseBindings seeded');
  }
}

describe('account deletion purges notification-token registrations', () => {
  const owner = 'owner-being-deleted';

  it('removes both the owner->token doc and the token->owner doc for the deleted identity', async () => {
    const fake = new DeletionFakeFirestore();
    fake.seed('readingNotificationTokens/owner-doc-1', {
      ownerUserId: owner,
      token: 'fcm-token-abc',
      schemaVersion: 1,
    });
    fake.seed('readingNotificationTokenOwners/token-doc-1', {
      ownerUserId: owner,
      updatedAtMs: 1,
    });
    // A DIFFERENT owner's registration must survive untouched.
    fake.seed('readingNotificationTokens/owner-doc-2', {
      ownerUserId: 'someone-else',
      token: 'fcm-token-xyz',
      schemaVersion: 1,
    });

    const repo = new FirestoreAccountDeletionRepository(
      fake as unknown as Firestore,
      null,
      null,
    );
    const receipt = await repo.deleteForIdentity(owner);

    expect(receipt.status).toBe('accepted');
    expect(fake.has('readingNotificationTokens/owner-doc-1')).toBe(false);
    expect(fake.has('readingNotificationTokenOwners/token-doc-1')).toBe(false);
    expect(fake.has('readingNotificationTokens/owner-doc-2')).toBe(true);
  });

  it('is idempotent — a second deletion call for an already-deleted owner is a safe no-op', async () => {
    const fake = new DeletionFakeFirestore();
    fake.seed('readingNotificationTokens/owner-doc-1', {
      ownerUserId: owner,
      token: 'fcm-token-abc',
      schemaVersion: 1,
    });

    const repo = new FirestoreAccountDeletionRepository(
      fake as unknown as Firestore,
      null,
      null,
    );
    await repo.deleteForIdentity(owner);
    await expect(repo.deleteForIdentity(owner)).resolves.toMatchObject({ status: 'accepted' });
    expect(fake.has('readingNotificationTokens/owner-doc-1')).toBe(false);
  });
});
