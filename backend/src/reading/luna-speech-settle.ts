/** One in-flight speech per grant, then the clip is reused. */
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import {
  speechAudioOf,
  speechGrantRef,
  type SpeechAudio,
} from './luna-speech-gate.js';

const CLAIM_MS = 70_000;

type GrantRow = Record<string, unknown>;

export async function claimSpeech(
  store: FirestoreLike,
  grantId: string,
  identity: string,
  signature: string,
  now: number,
): Promise<'go' | 'busy' | SpeechAudio> {
  return store.runTransaction(async (tx) => {
    const doc = speechGrantRef(store, grantId);
    const row = (await tx.get(doc)).data() as GrantRow | undefined;
    if (!row || row.identity !== identity) return 'busy';
    const cached = speechAudioOf(row, signature);
    if (cached) return cached;
    const until = row.claimUntil;
    if (row.claimSig === signature && typeof until === 'number' && until > now) return 'busy';
    tx.set(doc, { ...row, claimSig: signature, claimUntil: now + CLAIM_MS });
    return 'go';
  });
}

export async function finishSpeech(
  store: FirestoreLike,
  grantId: string,
  identity: string,
  signature: string,
  audioBase64: string,
  mimeType: string,
): Promise<void> {
  const doc = speechGrantRef(store, grantId);
  await store.runTransaction(async (tx) => {
    const row = (await tx.get(doc)).data() as GrantRow | undefined;
    if (!row || row.identity !== identity) return;
    const prior = row.audio && typeof row.audio === 'object' ? row.audio : {};
    tx.set(doc, {
      ...row,
      claimSig: '',
      claimUntil: 0,
      audio: { ...(prior as object), [signature]: { audioBase64, mimeType } },
    });
  });
}

export async function releaseSpeech(
  store: FirestoreLike,
  grantId: string,
  identity: string,
  signature: string,
): Promise<void> {
  const doc = speechGrantRef(store, grantId);
  await store.runTransaction(async (tx) => {
    const row = (await tx.get(doc)).data() as GrantRow | undefined;
    if (!row || row.identity !== identity || row.claimSig !== signature) return;
    tx.set(doc, { ...row, claimSig: '', claimUntil: 0 });
  });
}
