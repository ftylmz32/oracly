/** Drop an in-flight speech claim without spending a render. */
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { previewRef } from './luna-speech-preview.js';
import { releaseSpeech, releaseSpeechDoc } from './luna-speech-settle.js';

export async function releaseSpokenClaim(
  store: FirestoreLike,
  identity: string,
  turn: { grantId: string; signature: string; preview?: boolean },
): Promise<void> {
  if (turn.preview) {
    await releaseSpeechDoc(store, previewRef(store, turn.grantId), identity, turn.signature);
    return;
  }
  await releaseSpeech(store, turn.grantId, identity, turn.signature);
}
