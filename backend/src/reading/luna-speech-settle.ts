/** One in-flight render per grant. A finished clip is reused, never re-billed.
 *
 * Aşama 4C: a claim or a finish for an identity under account deletion
 * throws `AccountDeletedError` (the route then discards the clip it just
 * wrote), and every record carries a Firestore TTL `expiresAt`. */
import { Timestamp } from '@google-cloud/firestore';
import { AccountDeletedError, deletionBarrierExists } from '../account/deletion-barrier.js';
import type { FirestoreDocRefLike, FirestoreLike } from '../billing/entitlement-repository.js';
import { speechGrantRef, type SpeechAudio } from './luna-speech-gate.js';
import { readSpeechClip, SPEECH_RENDER_MAX } from './luna-speech-clip.js';
import type { ReadingStagedObjectStore } from './staged-object-store.js';

const CLAIM_MS = 70_000;
type Row = Record<string, unknown>;
type Tx = Parameters<Parameters<FirestoreLike['runTransaction']>[0]>[0];
export type SpeechTurn = 'go' | 'busy' | 'capped' | 'unavailable' | SpeechAudio;

export async function claimSpeech(
  store: FirestoreLike,
  grantId: string,
  identity: string,
  signature: string,
  now: number,
  objects: ReadingStagedObjectStore | undefined,
): Promise<SpeechTurn> {
  return claimSpeechDoc(store, speechGrantRef(store, grantId), identity, signature, now, objects, SPEECH_RENDER_MAX);
}

export async function claimSpeechDoc(
  store: FirestoreLike,
  ref: FirestoreDocRefLike,
  identity: string,
  signature: string,
  now: number,
  objects: ReadingStagedObjectStore | undefined,
  max: number,
  retainUntilMs?: number,
): Promise<SpeechTurn> {
  return store.runTransaction((tx) => hold(tx, store, ref, identity, signature, now, objects, max, retainUntilMs));
}

export async function finishSpeech(
  store: FirestoreLike,
  grantId: string,
  identity: string,
  signature: string,
  clipPath: string | null,
): Promise<void> {
  await finishSpeechDoc(store, speechGrantRef(store, grantId), identity, signature, clipPath);
}

export async function finishSpeechDoc(
  store: FirestoreLike,
  ref: FirestoreDocRefLike,
  identity: string,
  signature: string,
  clipPath: string | null,
): Promise<void> {
  await store.runTransaction((tx) => remember(tx, store, ref, identity, signature, clipPath));
}

export async function releaseSpeech(
  store: FirestoreLike,
  grantId: string,
  identity: string,
  signature: string,
): Promise<void> {
  await releaseSpeechDoc(store, speechGrantRef(store, grantId), identity, signature);
}

export async function releaseSpeechDoc(
  store: FirestoreLike,
  ref: FirestoreDocRefLike,
  identity: string,
  signature: string,
): Promise<void> {
  await store.runTransaction((tx) => clear(tx, ref, identity, signature));
}

async function hold(
  tx: Tx,
  store: FirestoreLike,
  ref: FirestoreDocRefLike,
  identity: string,
  signature: string,
  now: number,
  objects: ReadingStagedObjectStore | undefined,
  max: number,
  retainUntilMs: number | undefined,
): Promise<SpeechTurn> {
  if (await deletionBarrierExists(tx, store, identity)) throw new AccountDeletedError();
  const row = (await tx.get(ref)).data() as Row | undefined;
  if (row && row.identity !== identity) return 'busy';
  const path = clipsOf(row)[signature];
  if (path) {
    if (!objects) return 'unavailable';
    try {
      return (await readSpeechClip(objects, path)) ?? 'unavailable';
    } catch {
      return 'unavailable';
    }
  }
  const spent = spentOf(row);
  if (spent.includes(signature)) return 'unavailable';
  if (spent.length >= max) return 'capped';
  const until = row?.claimUntil;
  if (typeof row?.claimSig === 'string' && row.claimSig !== '' && typeof until === 'number' && until > now) {
    return 'busy';
  }
  tx.set(ref, {
    ...(row ?? {}),
    identity,
    claimSig: signature,
    claimUntil: now + CLAIM_MS,
    spent,
    clips: clipsOf(row),
    ...ttlField(row, retainUntilMs),
  });
  return 'go';
}

async function remember(
  tx: Tx,
  store: FirestoreLike,
  ref: FirestoreDocRefLike,
  identity: string,
  signature: string,
  clipPath: string | null,
): Promise<void> {
  // Deletion barrier first (reads before writes): a clip finished after the
  // sweep began must not be recorded; the caller deletes the object.
  if (await deletionBarrierExists(tx, store, identity)) throw new AccountDeletedError();
  const row = (await tx.get(ref)).data() as Row | undefined;
  if (!row || row.identity !== identity) return;
  const spent = spentOf(row);
  const clips = clipsOf(row);
  const { audio: _audio, ...rest } = row;
  if (!clipPath) {
    tx.set(ref, { ...rest, claimSig: '', claimUntil: 0, spent, clips });
    return;
  }
  clips[signature] = clipPath;
  tx.set(ref, {
    ...rest,
    claimSig: '',
    claimUntil: 0,
    spent: spent.includes(signature) ? spent : [...spent, signature],
    clips,
  });
}

async function clear(tx: Tx, ref: FirestoreDocRefLike, identity: string, signature: string): Promise<void> {
  const row = (await tx.get(ref)).data() as Row | undefined;
  if (!row || row.identity !== identity || row.claimSig !== signature) return;
  tx.set(ref, { ...row, claimSig: '', claimUntil: 0 });
}

/** Keeps an existing TTL instant; otherwise sets one: the preview-day
 * retention passed in, or (a legacy grant without `expiresAt`) its playback
 * end `expiresAtMs`. Never moves an existing instant earlier or later. */
function ttlField(row: Row | undefined, retainUntilMs: number | undefined): { expiresAt?: Timestamp } {
  if (row?.expiresAt !== undefined) return {};
  const fromGrant = typeof row?.expiresAtMs === 'number' ? row.expiresAtMs : undefined;
  const until = retainUntilMs ?? fromGrant;
  return until === undefined ? {} : { expiresAt: Timestamp.fromMillis(until) };
}

function spentOf(row: Row | undefined): string[] {
  const raw = row?.spent;
  return Array.isArray(raw) ? raw.filter((item): item is string => typeof item === 'string') : [];
}

function clipsOf(row: Row | undefined): Record<string, string> {
  const raw = row?.clips;
  if (!raw || typeof raw !== 'object') return {};
  return Object.fromEntries(
    Object.entries(raw).filter((entry): entry is [string, string] => typeof entry[1] === 'string'),
  );
}
