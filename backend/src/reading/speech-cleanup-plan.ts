/**
 * Aşama 4C — plan (and, only when explicitly asked, apply) the cleanup of
 * existing OR/Luna speech data that was written before `expiresAt` and the
 * account-deletion coverage existed.
 *
 * Pure: storage and Firestore are passed in, so the rules are unit-tested
 * and the CLI (`scripts/speech-clips-cleanup.ts`) is only wiring.
 *
 * Planning is read-only. It selects
 *   - objects under `speech-clips/` that match the clip / probe shape and are
 *     expired (older than SPEECH_CLIP_MAX_AGE_MS), orphaned (no record points
 *     at them, older than the grace window) or stale probes;
 *   - speech records without a Timestamp `expiresAt`, with the instant a TTL
 *     backfill would set (a grant: its playback end; a preview day, whose day
 *     is not stored: two days from now, so today's cap cannot be reset).
 * Nothing else in the bucket can be selected: every name is re-validated.
 */
import {
  decideSpeechObject,
  parseSpeechObjectPath,
  previewRecordExpiresAtMs,
  referencedClipPaths,
  SPEECH_CLIP_PREFIX,
  type SpeechObjectInfo,
} from './speech-retention.js';

export const SPEECH_RECORD_COLLECTIONS = ['speechGrants', 'speechPreviewDay'] as const;
export type SpeechRecordCollection = (typeof SPEECH_RECORD_COLLECTIONS)[number];

export type SpeechRecord = {
  collection: SpeechRecordCollection;
  id: string;
  data: Record<string, unknown>;
};

export type SpeechCleanupPlan = {
  scannedObjects: number;
  scannedRecords: number;
  deleteObjects: { name: string; reason: 'expired' | 'orphan' | 'stale_probe' }[];
  keptObjects: Record<'young' | 'referenced' | 'in_grace', number>;
  skippedObjects: Record<'not_speech' | 'no_timestamp', number>;
  backfillRecords: { collection: SpeechRecordCollection; id: string; expiresAtMs: number }[];
};

export function planSpeechCleanup(input: {
  objects: SpeechObjectInfo[];
  records: SpeechRecord[];
  nowMs: number;
}): SpeechCleanupPlan {
  const referenced = new Set<string>();
  for (const record of input.records) {
    for (const path of referencedClipPaths(record.data)) referenced.add(path);
  }
  const plan: SpeechCleanupPlan = {
    scannedObjects: input.objects.length,
    scannedRecords: input.records.length,
    deleteObjects: [],
    keptObjects: { young: 0, referenced: 0, in_grace: 0 },
    skippedObjects: { not_speech: 0, no_timestamp: 0 },
    backfillRecords: [],
  };
  for (const object of input.objects) {
    const decision = decideSpeechObject(object, referenced, input.nowMs);
    if (decision.action === 'delete') plan.deleteObjects.push({ name: object.name, reason: decision.reason });
    else if (decision.action === 'keep') plan.keptObjects[decision.reason] += 1;
    else plan.skippedObjects[decision.reason] += 1;
  }
  for (const record of input.records) {
    if (record.data.expiresAt !== undefined) continue;
    const expiresAtMs = record.collection === 'speechGrants'
      ? (typeof record.data.expiresAtMs === 'number' ? record.data.expiresAtMs : input.nowMs)
      : previewRecordExpiresAtMs(input.nowMs);
    plan.backfillRecords.push({ collection: record.collection, id: record.id, expiresAtMs });
  }
  return plan;
}

export type SpeechCleanupPorts = {
  deleteObject(name: string): Promise<void>;
  setRecordExpiresAt(collection: SpeechRecordCollection, id: string, expiresAtMs: number): Promise<void>;
};

export type SpeechCleanupResult = { deletedObjects: number; backfilledRecords: number; refused: number };

/** Executes a plan. Refuses any name outside the speech shape (defense in
 * depth) and any plan larger than `maxDeletes`. Idempotent: the ports treat
 * a missing object / record as done. */
export async function applySpeechCleanup(
  plan: SpeechCleanupPlan,
  ports: SpeechCleanupPorts,
  options: { maxDeletes: number },
): Promise<SpeechCleanupResult> {
  if (plan.deleteObjects.length > options.maxDeletes) {
    throw new Error(`speech_cleanup_over_cap:${plan.deleteObjects.length}>${options.maxDeletes}`);
  }
  const result: SpeechCleanupResult = { deletedObjects: 0, backfilledRecords: 0, refused: 0 };
  for (const target of plan.deleteObjects) {
    if (!target.name.startsWith(SPEECH_CLIP_PREFIX) || parseSpeechObjectPath(target.name) === null) {
      result.refused += 1;
      continue;
    }
    await ports.deleteObject(target.name);
    result.deletedObjects += 1;
  }
  for (const record of plan.backfillRecords) {
    await ports.setRecordExpiresAt(record.collection, record.id, record.expiresAtMs);
    result.backfilledRecords += 1;
  }
  return result;
}

/** Report line for a name without its owner segment. */
export function redactSpeechObjectName(name: string): string {
  return name.replace(/^speech-clips\/[a-f0-9]{24}\//, 'speech-clips/<owner>/');
}
