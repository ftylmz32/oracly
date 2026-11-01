/**
 * Test-only Firestore transport for the REAL `FirestoreAccountDeletionRepository`,
 * backed by a shared MemoryDocumentStore (as in the other deletion tests).
 * `failOnce` makes the next batch commit touching that collection throw, to
 * model an interrupted deletion run.
 */
import type { Firestore } from '@google-cloud/firestore';
import { FirestoreAccountDeletionRepository } from '../../src/account/account-deletion.js';
import type { MemoryDocumentStore } from '../../src/reading/memory-document-store.js';

export class DeletionAdapter {
  failOnce: string | null = null;
  constructor(private readonly store: MemoryDocumentStore) {}

  collection(name: string) {
    const store = this.store;
    return {
      doc(id: string) {
        const ref = store.collection(name).doc(id);
        return {
          path: `${name}/${id}`,
          get: () => ref.get(),
          async set(data: Record<string, unknown>) {
            await store.runTransaction(async (tx) => { tx.set(ref, data); });
          },
        };
      },
      where(field: string, _op: string, value: unknown) {
        return {
          async get() {
            const docs = [...store.docs.entries()]
              .filter(([path]) => path.startsWith(`${name}/`))
              .filter(([, data]) => data[field] === value)
              .map(([path, data]) => ({
                ref: Object.assign(store.collection(name).doc(path.slice(name.length + 1)), { path }),
                data: () => ({ ...data }),
              }));
            return { docs, empty: docs.length === 0, size: docs.length };
          },
        };
      },
    };
  }

  batch() {
    const refs: { path: string }[] = [];
    const self = this;
    return {
      delete(ref: { path: string }) { refs.push(ref); },
      async commit() {
        const failing = self.failOnce;
        if (failing && refs.some((ref) => ref.path.startsWith(`${failing}/`))) {
          self.failOnce = null;
          throw new Error(`injected failure deleting ${failing}`);
        }
        await self.store.runTransaction(async (tx) => {
          for (const ref of refs) tx.delete(ref as never);
        });
      },
    };
  }

  runTransaction<T>(fn: (tx: never) => Promise<T>): Promise<T> {
    return this.store.runTransaction(fn as never);
  }
}

export function realDeletion(store: MemoryDocumentStore) {
  const adapter = new DeletionAdapter(store);
  const deletion = new FirestoreAccountDeletionRepository(adapter as unknown as Firestore, null, null);
  return { adapter, deletion };
}
