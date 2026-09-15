/**
 * Transactional document store for tests and the Firestore adapter.
 * Durability is the shared document map, not process-global operation state.
 */
import type {
  FirestoreDocRefLike,
  FirestoreDocSnapshotLike,
  FirestoreLike,
  FirestoreTransactionLike,
} from '../billing/entitlement-repository.js';

type StoredDoc = Record<string, unknown>;

class MemoryDocRef implements FirestoreDocRefLike {
  constructor(
    private readonly store: MemoryDocumentStore,
    readonly path: string,
  ) {}

  get(): Promise<FirestoreDocSnapshotLike> {
    return Promise.resolve(this.store.read(this.path));
  }
}

export class MemoryDocumentStore implements FirestoreLike {
  readonly docs = new Map<string, StoredDoc>();
  private queue: Promise<unknown> = Promise.resolve();

  collection(name: string) {
    return {
      doc: (id: string): FirestoreDocRefLike =>
        new MemoryDocRef(this, `${name}/${id}`),
    };
  }

  read(path: string): FirestoreDocSnapshotLike {
    const data = this.docs.get(path);
    return {
      exists: data != null,
      data: () => (data ? { ...data } : undefined),
    };
  }

  runTransaction<T>(
    fn: (tx: FirestoreTransactionLike) => Promise<T>,
  ): Promise<T> {
    const run = this.queue.then(() => this.execute(fn));
    this.queue = run.then(
      () => undefined,
      () => undefined,
    );
    return run;
  }

  private async execute<T>(
    fn: (tx: FirestoreTransactionLike) => Promise<T>,
  ): Promise<T> {
    // `null` is a tombstone (delete) — distinct from "not yet touched this
    // transaction", which is why lookups below check `has()` rather than
    // relying on `??` (a deleted-then-read doc must read back as absent,
    // not silently fall through to the pre-transaction value).
    const pending = new Map<string, StoredDoc | null>();
    const tx: FirestoreTransactionLike = {
      get: (ref) => Promise.resolve(this.readBuffered(refPath(ref), pending)),
      set: (ref, data) => {
        pending.set(refPath(ref), { ...data });
      },
      update: (ref, data) => {
        const path = refPath(ref);
        const current = pending.has(path) ? pending.get(path) : this.docs.get(path);
        if (!current) throw new Error('document_missing');
        pending.set(path, { ...current, ...data });
      },
      delete: (ref) => {
        pending.set(refPath(ref), null);
      },
    };
    const result = await fn(tx);
    for (const [path, data] of pending) {
      if (data === null) this.docs.delete(path);
      else this.docs.set(path, data);
    }
    return result;
  }

  private readBuffered(
    path: string,
    pending: Map<string, StoredDoc | null>,
  ): FirestoreDocSnapshotLike {
    const data = pending.has(path) ? pending.get(path) : this.docs.get(path);
    return {
      exists: data != null,
      data: () => (data ? { ...data } : undefined),
    };
  }
}

function refPath(ref: FirestoreDocRefLike): string {
  const path = (ref as { path?: string }).path;
  if (typeof path !== 'string' || path.length === 0) {
    throw new Error('document_ref_path_required');
  }
  return path;
}
