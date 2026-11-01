/**
 * Production backport (Aşama 4E) — records written by the CURRENT production
 * revision (5c1090a0) have no `expiresAt`. The backport must read and use
 * them unchanged, give them a TTL instant on their next write, and delete
 * them with the account.
 */
import { Timestamp } from '@google-cloud/firestore';
import { describe, expect, it } from 'vitest';
import { identityKeyFromOpaqueToken } from '../src/auth/identity.js';
import type { ServerClock } from '../src/reading/clock.js';
import { speechClipPath } from '../src/reading/luna-speech-clip.js';
import { PREVIEW_DAY_MAX, previewDocId } from '../src/reading/luna-speech-preview.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { InMemorySoulmateEntitlementGuard } from '../src/reading/soulmate-entitlement-guard.js';
import { previewRecordExpiresAtMs } from '../src/reading/speech-retention.js';
import { realDeletion } from './support/deletion-adapter.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

const T0 = Date.UTC(2026, 10, 2, 9);
const token = 'legacy-schema-token';
const A = identityKeyFromOpaqueToken(token);
const PREVIEW = 'Selam. Buradayım. Şimdi nasılsın?';
const CLIP = Buffer.from('ID3fake-oracly-tts-audio-bytes-here!!');

class Clock implements ServerClock { now(): Date { return new Date(T0); } }

const realNow = Date.now;
let offset = 0;

async function app(store: MemoryDocumentStore, objects: MemoryStagedObjectStore) {
  let calls = 0;
  const fetchImpl: typeof fetch = async (url) => {
    if (String(url).includes('/audio/speech')) {
      calls += 1;
      return new Response(CLIP, { status: 200, headers: { 'content-type': 'audio/mpeg' } });
    }
    return jsonResponse({ choices: [{ message: { content: 'ok' } }] });
  };
  const guard = new InMemorySoulmateEntitlementGuard();
  guard.grant(A);
  const built = await testApp(testConfig({ AI_RATE_LIMIT_MAX: '100' }), fetchImpl, {
    lunaAccessStore: store, speechGrantStore: store, speechObjectStore: objects,
    freeTextQuotaStore: store, soulmateEntitlement: guard, readingClock: new Clock(),
  });
  let n = 0;
  const tts = (payload: Record<string, unknown>) => {
    offset += 5_000;
    Date.now = () => realNow() + offset;
    return built.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: { ...authHeader(token), 'idempotency-key': `legacy-schema-${++n}-key` },
      payload: { operation: 'tts', payload: { personality: 'gentle', speechSpeed: 'normal', language: 'tr', ...payload } },
    }).finally(() => { Date.now = realNow; });
  };
  return { built, tts, calls: () => calls };
}

describe('current-production speech records (no expiresAt)', () => {
  it('a full legacy preview day (12 spent, no expiresAt) still enforces the cap', async () => {
    const store = new MemoryDocumentStore();
    const objects = new MemoryStagedObjectStore();
    const id = previewDocId(A, new Date(T0).toISOString().slice(0, 10));
    await store.runTransaction(async (tx) => {
      tx.set(store.collection('speechPreviewDay').doc(id), {
        identity: A, spent: Array.from({ length: PREVIEW_DAY_MAX }, (_, i) => `sig-${i}`), clips: {}, claimSig: '', claimUntil: 0,
      });
    });
    const w = await app(store, objects);
    const res = await w.tts({ text: PREVIEW, voiceId: 'warm' });
    expect(res.statusCode).toBe(409);
    expect(w.calls()).toBe(0);
    await w.built.close();
  });

  it('a partial legacy preview day gets the day+2 TTL instant on its next claim', async () => {
    const store = new MemoryDocumentStore();
    const objects = new MemoryStagedObjectStore();
    const id = previewDocId(A, new Date(T0).toISOString().slice(0, 10));
    await store.runTransaction(async (tx) => {
      tx.set(store.collection('speechPreviewDay').doc(id), { identity: A, spent: ['other'], clips: {}, claimSig: '', claimUntil: 0 });
    });
    const w = await app(store, objects);
    expect((await w.tts({ text: PREVIEW, voiceId: 'deep' })).json().success).toBe(true);
    const row = store.docs.get(`speechPreviewDay/${id}`)!;
    expect((row.expiresAt as Timestamp).toMillis()).toBe(previewRecordExpiresAtMs(T0));
    expect(row.spent).toEqual(['other', 'deep|normal|gentle|tr']);
    await w.built.close();
  });

  it('a legacy grant with a cached clip replays it without a new render', async () => {
    const store = new MemoryDocumentStore();
    const objects = new MemoryStagedObjectStore();
    const grant = 'a'.repeat(32);
    const signature = 'warm|normal|gentle|tr';
    const path = speechClipPath(A, grant, signature);
    await objects.put(path, CLIP, 'audio/mpeg');
    await store.runTransaction(async (tx) => {
      tx.set(store.collection('speechGrants').doc(grant), {
        identity: A, kind: 'oracle', text: 'eski yanıt', expiresAtMs: T0 + 3_600_000,
        claimSig: '', claimUntil: 0, spent: [signature], clips: { [signature]: path },
      });
    });
    const w = await app(store, objects);
    const res = await w.tts({ text: 'metin', voiceId: 'warm', speechGrant: grant });
    expect(res.json().success).toBe(true);
    expect(res.json().data.audioBase64).toBe(CLIP.toString('base64'));
    expect(w.calls()).toBe(0);
    await w.built.close();
  });

  it('legacy records without expiresAt are deleted with the account', async () => {
    const store = new MemoryDocumentStore();
    await store.runTransaction(async (tx) => {
      tx.set(store.collection('speechGrants').doc('g'), { identity: A, kind: 'luna', text: 't', expiresAtMs: 1 });
      tx.set(store.collection('speechPreviewDay').doc('p'), { identity: A, spent: [], clips: {} });
      tx.set(store.collection('speechGrants').doc('other'), { identity: 'sub:other', kind: 'luna', text: 't', expiresAtMs: 1 });
    });
    // No object storage in this adapter: speech records exist -> fail closed.
    const { deletion } = realDeletion(store);
    await expect(deletion.deleteForIdentity(A)).rejects.toThrow(/object_store_unavailable/);
    expect(store.docs.has('speechGrants/g')).toBe(true);
  });
});
