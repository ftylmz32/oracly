/**
 * Aşama 4C — retention rules for OR/Luna reply audio.
 *
 * Three stores hold speech data:
 *   - `speechGrants/{grantId}`: identity, reply text, playback window
 *     (`expiresAtMs`, 6 hours) and the rendered clip paths;
 *   - `speechPreviewDay/{sha256(identity|day)}`: the daily free preview cap
 *     and its clip paths;
 *   - GCS `speech-clips/<owner>/<grant>/<signature>.mp3` (+ a `_probe` file).
 *
 * Rules:
 *   - every speech document carries a Firestore Timestamp `expiresAt` so a
 *     Firestore TTL policy can remove it. TTL never deletes before that
 *     instant, only (usually within a day) after it;
 *   - a grant record expires with its playback window, so the reply text is
 *     not kept longer than it can be used;
 *   - a preview-day record expires at the start of the SECOND UTC day after
 *     its day, so the daily cap can never be reset by an early delete;
 *   - clips are removed by object age (`SPEECH_CLIP_MAX_AGE_MS`, prefix-
 *     bounded GCS lifecycle or the cleanup tool), never by reading the
 *     Firestore record first. A record deleted before its clip therefore
 *     cannot strand the clip, and a clip deleted before its record is never
 *     needed: the record no longer grants playback by then.
 *
 * Paths are validated strictly: nothing outside `speech-clips/` and nothing
 * that does not match the clip / probe shape is ever selected for deletion.
 */
import { createHash } from 'node:crypto';

export const SPEECH_CLIP_PREFIX = 'speech-clips/';

/** Playback window of a grant (mirrors `luna-speech-gate.ts`). */
export const SPEECH_GRANT_PLAYBACK_MS = 6 * 60 * 60 * 1000;

/** Object age after which any clip may be deleted (GCS lifecycle `age: 2`). */
export const SPEECH_CLIP_MAX_AGE_MS = 2 * 24 * 60 * 60 * 1000;

/** An unreferenced clip younger than this may still be in its finish step. */
export const SPEECH_CLIP_ORPHAN_GRACE_MS = 60 * 60 * 1000;

const DAY_MS = 24 * 60 * 60 * 1000;

const OWNER = /^[a-f0-9]{24}$/;
const CLIP = /^speech-clips\/([a-f0-9]{24})\/([a-f0-9]{1,32})\/([a-f0-9]{20})\.mp3$/;
const PROBE = /^speech-clips\/([a-f0-9]{24})\/_probe\/ready\.txt$/;

/** Same owner segment as `speechClipPath` in `luna-speech-clip.ts`. */
export function speechOwnerSegment(identityKey: string): string {
  return createHash('sha256').update(identityKey).digest('hex').slice(0, 24);
}

/** `speech-clips/<owner>/` — the only prefix account deletion lists. */
export function speechOwnerPrefix(identityKey: string): string {
  const owner = speechOwnerSegment(identityKey);
  if (!OWNER.test(owner)) throw new Error('speech_owner_segment_invalid');
  return `${SPEECH_CLIP_PREFIX}${owner}/`;
}

export type SpeechObjectKind = 'clip' | 'probe';

export function parseSpeechObjectPath(
  name: string,
): { kind: SpeechObjectKind; owner: string } | null {
  const clip = CLIP.exec(name);
  if (clip) return { kind: 'clip', owner: clip[1]! };
  const probe = PROBE.exec(name);
  if (probe) return { kind: 'probe', owner: probe[1]! };
  return null;
}

/** True only for a speech object of exactly this owner. */
export function isOwnedSpeechObject(name: string, identityKey: string): boolean {
  const parsed = parseSpeechObjectPath(name);
  return parsed !== null && parsed.owner === speechOwnerSegment(identityKey);
}

/** Grant record TTL instant: the end of its playback window. */
export function grantRecordExpiresAtMs(playbackExpiresAtMs: number): number {
  return playbackExpiresAtMs;
}

/** Preview-day record TTL instant: start of the second UTC day after `now`. */
export function previewRecordExpiresAtMs(nowMs: number): number {
  const dayStart = Math.floor(nowMs / DAY_MS) * DAY_MS;
  return dayStart + 2 * DAY_MS;
}

export type SpeechObjectInfo = { name: string; createdMs: number | null };

export type SpeechCleanupDecision =
  | { action: 'keep'; reason: 'young' | 'referenced' | 'in_grace' }
  | { action: 'delete'; reason: 'expired' | 'orphan' | 'stale_probe' }
  | { action: 'skip'; reason: 'not_speech' | 'no_timestamp' };

/**
 * Historical / scheduled cleanup rule for one object.
 *   - not a speech object, or no creation time → never touched;
 *   - older than SPEECH_CLIP_MAX_AGE_MS → delete (expired);
 *   - a probe older than the grace window → delete;
 *   - a clip not referenced by any speech record and older than the grace
 *     window → delete (orphan: e.g. its finish step failed);
 *   - everything else is kept.
 */
export function decideSpeechObject(
  object: SpeechObjectInfo,
  referenced: ReadonlySet<string>,
  nowMs: number,
): SpeechCleanupDecision {
  const parsed = parseSpeechObjectPath(object.name);
  if (!parsed) return { action: 'skip', reason: 'not_speech' };
  if (object.createdMs === null || !Number.isFinite(object.createdMs)) {
    return { action: 'skip', reason: 'no_timestamp' };
  }
  const age = nowMs - object.createdMs;
  if (age >= SPEECH_CLIP_MAX_AGE_MS) return { action: 'delete', reason: 'expired' };
  if (age < SPEECH_CLIP_ORPHAN_GRACE_MS) return { action: 'keep', reason: 'in_grace' };
  if (parsed.kind === 'probe') return { action: 'delete', reason: 'stale_probe' };
  if (referenced.has(object.name)) return { action: 'keep', reason: 'referenced' };
  return { action: 'delete', reason: 'orphan' };
}

/** Clip paths a speech record still points at (its `clips` map values). */
export function referencedClipPaths(row: Record<string, unknown> | undefined): string[] {
  const raw = row?.clips;
  if (!raw || typeof raw !== 'object') return [];
  return Object.values(raw as Record<string, unknown>).filter(
    (value): value is string => typeof value === 'string' && parseSpeechObjectPath(value)?.kind === 'clip',
  );
}
