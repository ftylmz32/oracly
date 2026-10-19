import { describe, expect, it } from 'vitest';
import { identityKeyFromOpaqueToken } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import type { ReadingStagedObjectStore } from '../src/reading/staged-object-store.js';
import type { ServerClock } from '../src/reading/clock.js';
import { PREVIEW_DAY_MAX } from '../src/reading/luna-speech-preview.js';
import { SPEECH_RENDER_MAX } from '../src/reading/luna-speech-clip.js';
import { InMemorySoulmateEntitlementGuard } from '../src/reading/soulmate-entitlement-guard.js';
import { authHeader, jsonResponse, oracleBody, testApp, testConfig } from './helpers.js';

const tokenA = 'user-access-token';
const tokenB = 'other-access-token';
const ownerA = identityKeyFromOpaqueToken(tokenA);
const preview = 'Selam. Buradayım. Şimdi nasılsın?';
const clip = Buffer.from('ID3fake-oracly-tts-audio-bytes-here!!');

class Clock implements ServerClock {
  now(): Date {
    return new Date(Date.UTC(2026, 9, 19, 12));
  }
}

function later(ms: number): () => void {
  const real = Date.now;
  Date.now = () => real() + ms;
  return () => {
    Date.now = real;
  };
}

class WriteGate implements ReadingStagedObjectStore {
  failWrites = false;
  failReads = false;
  started = 0;
  private waiting: Promise<void> | null = null;
  private open = () => {};
  readonly objects = new Map<string, Buffer>();

  hold(): void {
    this.waiting = new Promise((resolve) => {
      this.open = resolve;
    });
  }

  release(): void {
    this.open();
    this.waiting = null;
  }

  async put(objectPath: string, bytes: Buffer): Promise<void> {
    this.started += 1;
    if (this.waiting) await this.waiting;
    if (this.failWrites) throw new Error('speech_store_write_failed');
    this.objects.set(objectPath, Buffer.from(bytes));
  }

  async get(objectPath: string): Promise<Buffer | null> {
    if (this.failReads) throw new Error('speech_store_read_failed');
    return this.objects.get(objectPath) ?? null;
  }

  async delete(objectPath: string): Promise<void> {
    this.objects.delete(objectPath);
  }
}

function speechTransport() {
  let calls = 0;
  const fetchImpl: typeof fetch = async (url) => {
    if (String(url).includes('/audio/speech')) {
      calls += 1;
      return new Response(clip, { status: 200, headers: { 'content-type': 'audio/mpeg' } });
    }
    return jsonResponse({ choices: [{ message: { content: 'Sakin bir yansıma.' } }] });
  };
  return { fetchImpl, calls: () => calls };
}

function appFor(
  fetchImpl: typeof fetch,
  store: MemoryDocumentStore,
  objects: ReadingStagedObjectStore | undefined,
  guard = new InMemorySoulmateEntitlementGuard(),
) {
  return testApp(testConfig({ AI_RATE_LIMIT_MAX: '100', AI_MAX_CONCURRENT: '4' }), fetchImpl, {
    lunaAccessStore: store,
    speechGrantStore: store,
    ...(objects ? { speechObjectStore: objects } : {}),
    freeTextQuotaStore: store,
    soulmateEntitlement: guard,
    readingClock: new Clock(),
  });
}

function chat(text: string) {
  return { operation: 'chat', model: 'gpt-4o', payload: { userMessage: text, priorUser: [] } };
}

function tts(grant: string | undefined, voiceId = 'warm', speechSpeed = 'normal') {
  return {
    operation: 'tts',
    payload: {
      text: 'metin',
      personality: 'gentle',
      voiceId,
      speechSpeed,
      language: 'tr',
      ...(grant ? { speechGrant: grant } : {}),
    },
  };
}

async function post(
  app: Awaited<ReturnType<typeof appFor>>,
  token: string,
  key: string,
  payload: unknown,
) {
  return app.inject({
    method: 'POST',
    url: '/v1/ai/complete',
    headers: { ...authHeader(token), 'idempotency-key': key },
    payload,
  });
}

function spentCount(store: MemoryDocumentStore): number {
  let count = 0;
  for (const data of store.docs.values()) {
    if (Array.isArray(data.spent)) count += data.spent.length;
  }
  return count;
}

function noStoredAudio(store: MemoryDocumentStore, objects?: { objects: Map<string, Buffer> }): void {
  for (const data of store.docs.values()) {
    const raw = JSON.stringify(data);
    expect(raw).not.toContain('audioBase64');
    expect(raw).not.toContain('https://');
    expect(raw).not.toContain('storage.googleapis.com');
  }
  if (!objects) return;
  for (const path of objects.objects.keys()) {
    expect(path.startsWith('speech-clips/')).toBe(true);
    expect(path).not.toContain('http');
  }
}

describe('luna speech object storage failures', () => {
  it('keeps the render and preview caps', () => {
    expect(SPEECH_RENDER_MAX).toBe(4);
    expect(PREVIEW_DAY_MAX).toBe(12);
  });

  it('does not call the provider when the object store is missing', async () => {
    const spoken = speechTransport();
    const store = new MemoryDocumentStore();
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, store, undefined, guard);
    const chatRes = await post(app, tokenA, 'or-store-miss-chat', chat('Depo yok'));
    const grant = chatRes.json().data.speechGrant as string;
    const heard = await post(app, tokenA, 'or-store-miss-tts', tts(grant));
    expect(heard.statusCode).toBe(503);
    expect(heard.json().error.code).toBe('no_configuration');
    expect(JSON.stringify(heard.json())).not.toContain('audioBase64');
    expect(spoken.calls()).toBe(0);
    expect(spentCount(store)).toBe(0);
    noStoredAudio(store);
    await app.close();
  });

  it('does not call the provider when writes fail, and a retry stays unpaid', async () => {
    const spoken = speechTransport();
    const store = new MemoryDocumentStore();
    const objects = new WriteGate();
    objects.failWrites = true;
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, store, objects, guard);
    const chatRes = await post(app, tokenA, 'or-store-write-chat', chat('Yazma hatasi'));
    const grant = chatRes.json().data.speechGrant as string;
    const failed = await post(app, tokenA, 'or-store-write-1', tts(grant));
    expect(failed.statusCode).toBe(503);
    expect(failed.json().success).toBe(false);
    expect(spoken.calls()).toBe(0);
    expect(spentCount(store)).toBe(0);
    const restore = later(5_000);
    try {
      const again = await post(app, tokenA, 'or-store-write-2', tts(grant));
      expect(again.statusCode).toBe(503);
      expect(spoken.calls()).toBe(0);
      expect(spentCount(store)).toBe(0);
    } finally {
      restore();
    }
    noStoredAudio(store, objects);
    await app.close();
  });

  it('hides a stored clip when the object store cannot read it', async () => {
    const spoken = speechTransport();
    const store = new MemoryDocumentStore();
    const objects = new WriteGate();
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, store, objects, guard);
    const chatRes = await post(app, tokenA, 'or-store-read-chat', chat('Okuma hatasi'));
    const grant = chatRes.json().data.speechGrant as string;
    const heard = await post(app, tokenA, 'or-store-read-ok', tts(grant));
    expect(heard.json().success).toBe(true);
    objects.failReads = true;
    const restore = later(5_000);
    try {
      const again = await post(app, tokenA, 'or-store-read-fail', tts(grant));
      expect(again.statusCode).toBe(503);
      expect(again.json().error.code).toBe('no_configuration');
      expect(JSON.stringify(again.json())).not.toContain('audioBase64');
      expect(spoken.calls()).toBe(1);
      expect(spentCount(store)).toBe(1);
    } finally {
      restore();
    }
    noStoredAudio(store, objects);
    await app.close();
  });

  it('does not regenerate when the stored object is gone', async () => {
    const spoken = speechTransport();
    const store = new MemoryDocumentStore();
    const objects = new WriteGate();
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, store, objects, guard);
    const chatRes = await post(app, tokenA, 'or-store-gone-chat', chat('Silinen klip'));
    const grant = chatRes.json().data.speechGrant as string;
    expect((await post(app, tokenA, 'or-store-gone-ok', tts(grant))).json().success).toBe(true);
    objects.objects.clear();
    const restore = later(5_000);
    try {
      const again = await post(app, tokenA, 'or-store-gone-miss', tts(grant));
      expect(again.statusCode).toBe(503);
      expect(spoken.calls()).toBe(1);
      expect(spentCount(store)).toBe(1);
    } finally {
      restore();
    }
    noStoredAudio(store);
    await app.close();
  });

  it('keeps one failure in flight and does not speak for a second account', async () => {
    const spoken = speechTransport();
    const store = new MemoryDocumentStore();
    const objects = new WriteGate();
    objects.failWrites = true;
    objects.hold();
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, store, objects, guard);
    const chatRes = await post(app, tokenA, 'or-store-race-chat', chat('Yaris'));
    const grant = chatRes.json().data.speechGrant as string;
    const pending = Promise.all([
      post(app, tokenA, 'or-store-race-a', tts(grant, 'warm', 'normal')),
      post(app, tokenA, 'or-store-race-b', tts(grant, 'warm', 'slow')),
    ]);
    for (let i = 0; i < 40 && objects.started < 1; i += 1) {
      await new Promise((resolve) => setImmediate(resolve));
    }
    expect(objects.started).toBeGreaterThan(0);
    expect(spoken.calls()).toBe(0);
    objects.release();
    const pair = await pending;
    expect(pair.map((res) => res.statusCode).sort()).toEqual([409, 503]);
    expect(spoken.calls()).toBe(0);
    const other = await post(app, tokenB, 'or-store-race-other', tts(grant, 'calm'));
    expect(other.statusCode).toBe(403);
    expect(other.json().error.code).toBe('premium_required');
    expect(JSON.stringify(other.json())).not.toContain('audioBase64');
    expect(spoken.calls()).toBe(0);
    noStoredAudio(store, objects);
    await app.close();
  });

  it('speaks again after the store recovers and still replays the stored clip', async () => {
    const spoken = speechTransport();
    const store = new MemoryDocumentStore();
    const objects = new WriteGate();
    objects.failWrites = true;
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, store, objects, guard);
    const chatRes = await post(app, tokenA, 'or-store-back-chat', chat('Geri gelen depo'));
    const grant = chatRes.json().data.speechGrant as string;
    expect((await post(app, tokenA, 'or-store-back-down', tts(grant))).statusCode).toBe(503);
    objects.failWrites = false;
    const restore = later(5_000);
    let heardOk = false;
    try {
      const heard = await post(app, tokenA, 'or-store-back-up', tts(grant));
      expect(heard.json().success, JSON.stringify(heard.json())).toBe(true);
      expect(typeof heard.json().data.audioBase64).toBe('string');
      expect(spoken.calls()).toBe(1);
      heardOk = true;
    } finally {
      restore();
    }
    expect(heardOk).toBe(true);
    objects.failWrites = true;
    const replay = later(10_000);
    try {
      const same = await post(app, tokenA, 'or-store-back-same', tts(grant));
      expect(same.json().success, JSON.stringify(same.json())).toBe(true);
      expect(spoken.calls()).toBe(1);
      expect(spentCount(store)).toBe(1);
    } finally {
      replay();
    }
    noStoredAudio(store, objects);
    await app.close();
  });

  it('does not turn a storage failure into a premium or auth leak', async () => {
    const spoken = speechTransport();
    const store = new MemoryDocumentStore();
    const objects = new WriteGate();
    objects.failWrites = true;
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, store, objects, guard);
    const chatRes = await post(app, tokenA, 'or-store-leak-chat', chat('Sizma'));
    const grant = chatRes.json().data.speechGrant as string;
    guard.revoke(ownerA);
    const lapsed = await post(app, tokenA, 'or-store-leak-lapsed', tts(grant));
    expect(lapsed.statusCode).toBe(403);
    expect(lapsed.json().error.code).toBe('premium_required');
    const missing = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'idempotency-key': 'or-store-leak-anon' },
      payload: tts(grant),
    });
    expect(missing.statusCode).toBe(401);
    expect(missing.json().error.code).toBe('unauthorized');
    const unknown = await post(app, tokenA, 'or-store-leak-bad', tts('ab'.repeat(16)));
    expect(unknown.statusCode).toBe(403);
    expect(unknown.json().error.code).toBe('premium_required');
    expect(spoken.calls()).toBe(0);
    await app.close();
  });

  it('keeps a free preview unspent until the store can keep it', async () => {
    const spoken = speechTransport();
    const store = new MemoryDocumentStore();
    const objects = new WriteGate();
    objects.failWrites = true;
    const app = await appFor(spoken.fetchImpl, store, objects);
    const denied = await post(app, tokenA, 'or-store-prev-down', {
      operation: 'tts',
      payload: { text: preview, personality: 'gentle', voiceId: 'warm', speechSpeed: 'slow', language: 'tr' },
    });
    expect(denied.statusCode).toBe(503);
    expect(spoken.calls()).toBe(0);
    expect(spentCount(store)).toBe(0);
    objects.failWrites = false;
    const restore = later(5_000);
    try {
      const heard = await post(app, tokenA, 'or-store-prev-up', {
        operation: 'tts',
        payload: { text: preview, personality: 'gentle', voiceId: 'warm', speechSpeed: 'slow', language: 'tr' },
      });
      expect(heard.json().success, JSON.stringify(heard.json())).toBe(true);
      expect(spoken.calls()).toBe(1);
      expect(spentCount(store)).toBe(1);
    } finally {
      restore();
    }
    noStoredAudio(store, objects);
    await app.close();
  });
});
