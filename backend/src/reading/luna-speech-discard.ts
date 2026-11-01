/**
 * Aşama 4C — a clip written to `speech-clips/` whose finish step failed is
 * not referenced by any record: delete it now instead of leaving an orphan.
 *
 * Safety:
 *   - only a path of this identity's own `speech-clips/<owner>/` shape is
 *     ever deleted;
 *   - when the account is being deleted the clip is always removed;
 *   - otherwise it is removed only if its record does NOT point at it (two
 *     renders of the same grant/signature share one path; the other render
 *     may have recorded it). If the record cannot be read, the clip is left
 *     to the age-based cleanup rather than risk deleting a used clip;
 *   - best effort and idempotent: a missing object is not an error, and a
 *     failure here never replaces the original error.
 */
import type { FirestoreDocRefLike } from '../billing/entitlement-repository.js';
import type { ReadingStagedObjectStore } from './staged-object-store.js';
import { isOwnedSpeechObject } from './speech-retention.js';

export type DiscardOutcome = 'deleted' | 'kept_referenced' | 'kept_unknown' | 'refused' | 'failed';

export async function discardUnrecordedClip(input: {
  objects: ReadingStagedObjectStore | undefined;
  ref: FirestoreDocRefLike;
  identity: string;
  signature: string;
  clipPath: string;
  accountDeleted: boolean;
}): Promise<DiscardOutcome> {
  if (!input.objects || !isOwnedSpeechObject(input.clipPath, input.identity)) return 'refused';
  if (!input.accountDeleted) {
    let row: Record<string, unknown> | undefined;
    try {
      row = (await input.ref.get()).data() as Record<string, unknown> | undefined;
    } catch {
      return 'kept_unknown';
    }
    const clips = row?.clips;
    const recorded = clips && typeof clips === 'object'
      ? (clips as Record<string, unknown>)[input.signature]
      : undefined;
    if (row?.identity === input.identity && recorded === input.clipPath) return 'kept_referenced';
  }
  try {
    await input.objects.delete(input.clipPath);
    return 'deleted';
  } catch {
    return 'failed';
  }
}
