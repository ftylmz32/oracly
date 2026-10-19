/**
 * Paid speech follows a server reply. A client feature tag cannot grant it.
 * Catalog preview phrases stay free. Luna chat speech still needs premium.
 */
import { randomBytes } from 'node:crypto';
import { asRecord, sanitizeText } from '../ai/sanitize.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope } from '../errors.js';
import { toEpochMs, type ServerClock } from './clock.js';
import { admitVoicePreview } from './luna-speech-preview.js';
import type { SoulmateEntitlementGuard } from './soulmate-entitlement-guard.js';

export const SPEECH_GRANTS = 'speechGrants';
const TTL_MS = 6 * 60 * 60 * 1000;
const PHRASES = [
  'Selam. Buradayım. Şimdi nasılsın?',
  "Hello. I'm here. How are you now?",
  'Привет. Я здесь. Как ты сейчас?',
];

export type SpeechAuthorization =
  | { action: 'skip' }
  | { action: 'preview' }
  | { action: 'reply'; status: number; payload: unknown }
  | { action: 'cached'; data: SpeechAudio }
  | { action: 'speak'; text: string; grantId: string; signature: string; preview?: boolean };

export type SpeechAudio = {
  audioBase64: string;
  mimeType: string;
  operation: 'tts';
};

type GrantRow = Record<string, unknown>;

function locked(config: AppConfig): boolean {
  return config.appEnv === 'production' || config.appEnv === 'staging';
}

function words(value: string): string {
  return value.toLocaleLowerCase('tr-TR').replace(/[^\p{L}\p{N}]+/gu, ' ').replace(/\s+/g, ' ').trim();
}

const PREVIEW = new Set(PHRASES.map(words));

export function isVoicePreview(text: string): boolean {
  const spoken = words(text);
  return spoken.length > 0 && PREVIEW.has(spoken);
}

export function speechGrantIdFromBody(body: unknown): string | null {
  const id = asRecord(asRecord(body)?.payload)?.speechGrant;
  return typeof id === 'string' ? id : null;
}

export function speechSignature(input: {
  voiceId?: string;
  speechSpeed?: string;
  personality?: string;
  language?: string;
}): string {
  return `${input.voiceId ?? ''}|${input.speechSpeed ?? ''}|${input.personality ?? ''}|${input.language ?? ''}`;
}

function denied(): SpeechAuthorization {
  return { action: 'reply', status: 403, payload: errorEnvelope(ErrorCode.premiumRequired) };
}

function unconfigured(): SpeechAuthorization {
  return { action: 'reply', status: 503, payload: errorEnvelope(ErrorCode.noConfiguration) };
}

export function speechGrantRef(store: FirestoreLike, id: string) {
  return store.collection(SPEECH_GRANTS).doc(id);
}

export async function issueSpeechGrant(input: {
  store: FirestoreLike;
  clock: ServerClock;
  identity: string;
  kind: 'luna' | 'oracle';
  text: string;
}): Promise<string> {
  const id = randomBytes(16).toString('hex');
  const text = sanitizeText(input.text, 1200);
  const doc = speechGrantRef(input.store, id);
  await input.store.runTransaction(async (tx) => {
    tx.set(doc, {
      identity: input.identity,
      kind: input.kind,
      text,
      expiresAtMs: toEpochMs(input.clock.now()) + TTL_MS,
    });
  });
  return id;
}

export async function authorizeSpeech(input: {
  config: AppConfig;
  store: FirestoreLike | undefined;
  guard: SoulmateEntitlementGuard | undefined;
  clock: ServerClock;
  operation: string;
  identity: string;
  text: string;
  grantId: string | null;
  signature: string;
}): Promise<SpeechAuthorization> {
  if (input.operation !== 'tts') return { action: 'skip' };
  if (isVoicePreview(input.text)) {
    if (!input.store) return locked(input.config) ? unconfigured() : { action: 'preview' };
    return admitVoicePreview({
      store: input.store,
      clock: input.clock,
      identity: input.identity,
      text: input.text,
      signature: input.signature,
    });
  }
  if (!input.store) return locked(input.config) ? unconfigured() : { action: 'skip' };
  const id = input.grantId ?? '';
  if (!/^[a-f0-9]{32}$/.test(id)) return denied();
  const row = (await speechGrantRef(input.store, id).get()).data() as GrantRow | undefined;
  if (!row || row.identity !== input.identity) return denied();
  const now = toEpochMs(input.clock.now());
  if (typeof row.expiresAtMs !== 'number' || row.expiresAtMs <= now) return denied();
  if (row.kind === 'luna') {
    if (!input.guard) return locked(input.config) ? unconfigured() : denied();
    if (!(await input.guard.isPremiumActive(input.identity))) return denied();
  } else if (row.kind !== 'oracle') {
    return denied();
  }
  const text = typeof row.text === 'string' ? row.text.trim() : '';
  if (!text) return denied();
  return { action: 'speak', text, grantId: id, signature: input.signature };
}
