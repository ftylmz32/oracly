/**
 * Production backport (Aşama 4E) — `readingLegacyDirectAi` pins.
 *
 * The production base (5c1090a0) has no writer for this collection (the
 * writer arrived later, in 0f960699); the sweep is forward-compatible: once a
 * revision writes pins (`ownerUserId` field), account deletion removes
 * exactly the deleted owner's pins. With none present it is a no-op.
 */
import { describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { realDeletion } from './support/deletion-adapter.js';

const A = identityKeyFromSubject('legacy-a');
const B = identityKeyFromSubject('legacy-b');

function pins(store: MemoryDocumentStore, owner: string) {
  return [...store.docs.entries()].filter(([path, data]) =>
    path.startsWith('readingLegacyDirectAi/') && data.ownerUserId === owner).length;
}

describe('backport: legacy direct-AI pins follow account deletion', () => {
  it('deletes A\'s pins (more than one batch), keeps B\'s', async () => {
    const store = new MemoryDocumentStore();
    await store.runTransaction(async (tx) => {
      for (let i = 0; i < 450; i++) {
        tx.set(store.collection('readingLegacyDirectAi').doc(`op-a-${i}`), { ownerUserId: A, requestKey: 'k', admitted: [] });
      }
      tx.set(store.collection('readingLegacyDirectAi').doc('op-b'), { ownerUserId: B, requestKey: 'k', admitted: [] });
    });
    const { deletion } = realDeletion(store);
    expect((await deletion.deleteForIdentity(A)).status).toBe('accepted');
    expect(pins(store, A)).toBe(0);
    expect(pins(store, B)).toBe(1);
  });

  it('no pins (the production state today): deletion still accepted', async () => {
    const store = new MemoryDocumentStore();
    const { deletion } = realDeletion(store);
    expect((await deletion.deleteForIdentity(A)).status).toBe('accepted');
  });
});
