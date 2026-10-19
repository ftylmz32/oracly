/**
 * Private speech bytes. The Firestore grant stores only the object path.
 * No public URL is ever minted.
 */
import { createHash } from 'node:crypto';
import type { ReadingStagedObjectStore } from './staged-object-store.js';
import type { SpeechAudio } from './luna-speech-gate.js';

export const SPEECH_RENDER_MAX = 4;

export function speechClipPath(identity: string, docId: string, signature: string): string {
  const owner = createHash('sha256').update(identity).digest('hex').slice(0, 24);
  const sig = createHash('sha256').update(signature).digest('hex').slice(0, 20);
  const doc = docId.replace(/[^a-f0-9]/g, '').slice(0, 32);
  return `speech-clips/${owner}/${doc}/${sig}.mp3`;
}

export async function readSpeechClip(
  store: ReadingStagedObjectStore,
  path: string,
): Promise<SpeechAudio | null> {
  const bytes = await store.get(path);
  if (!bytes || bytes.length < 16) return null;
  return {
    audioBase64: bytes.toString('base64'),
    mimeType: 'audio/mpeg',
    operation: 'tts',
  };
}

export async function writeSpeechClip(
  store: ReadingStagedObjectStore,
  path: string,
  audioBase64: string,
): Promise<void> {
  await store.put(path, Buffer.from(audioBase64, 'base64'), 'audio/mpeg');
}
