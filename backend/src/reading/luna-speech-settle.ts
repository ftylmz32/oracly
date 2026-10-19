/** One in-flight render per grant. A finished clip is reused, never re-billed. */
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
): Promise<SpeechTurn> {
  return store.runTransaction((tx) => hold(tx, ref, identity, signature, now, objects, max));
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
  await store.runTransaction((tx) => remember(tx, ref, identity, signature, clipPath));
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
  ref: FirestoreDocRefLike,
  identity: string,
  signature: string,
  now: number,
  objects: ReadingStagedObjectStore | undefined,
  max: number,
): Promise<SpeechTurn> {
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
  tx.set(ref, { ...(row ?? {}), identity, claimSig: signature, claimUntil: now + CLAIM_MS, spent, clips: clipsOf(row) });
  return 'go';
}

async function remember(
  tx: Tx,
  ref: FirestoreDocRefLike,
  identity: string,
  signature: string,
  clipPath: string | null,
): Promise<void> {
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
