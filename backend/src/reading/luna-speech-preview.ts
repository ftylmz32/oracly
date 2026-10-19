/**
 * Catalog preview stays free. One private clip per setting.
 * Distinct settings are capped per identity per UTC day.
 */
import { createHash } from 'node:crypto';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { ErrorCode, errorEnvelope } from '../errors.js';
import type { ServerClock } from './clock.js';

export const PREVIEW_DAY_MAX = 12;
const COLLECTION = 'speechPreviewDay';

type Row = Record<string, unknown>;

export function previewDocId(identity: string, day: string): string {
  return createHash('sha256').update(`${identity}|${day}`).digest('hex').slice(0, 32);
}

export function previewRef(store: FirestoreLike, id: string) {
  return store.collection(COLLECTION).doc(id);
}

function dayOf(clock: ServerClock): string {
  return clock.now().toISOString().slice(0, 10);
}

export async function admitVoicePreview(input: {
  store: FirestoreLike;
  clock: ServerClock;
  identity: string;
  text: string;
  signature: string;
}): Promise<
  | { action: 'reply'; status: number; payload: unknown }
  | { action: 'speak'; text: string; grantId: string; signature: string; preview: true }
> {
  const id = previewDocId(input.identity, dayOf(input.clock));
  const row = (await previewRef(input.store, id).get()).data() as Row | undefined;
  const clips = row?.clips;
  const known = !!clips
    && typeof clips === 'object'
    && typeof (clips as Record<string, unknown>)[input.signature] === 'string';
  if (!known) {
    const spent = Array.isArray(row?.spent)
      ? row.spent.filter((item) => typeof item === 'string')
      : [];
    if (spent.includes(input.signature)) {
      return { action: 'reply', status: 503, payload: errorEnvelope(ErrorCode.noConfiguration) };
    }
    if (spent.length >= PREVIEW_DAY_MAX) {
      return { action: 'reply', status: 409, payload: errorEnvelope(ErrorCode.rateLimited) };
    }
  }
  return {
    action: 'speak',
    text: input.text,
    grantId: id,
    signature: input.signature,
    preview: true,
  };
}
