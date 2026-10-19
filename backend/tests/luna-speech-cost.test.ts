import { describe, expect, it } from 'vitest';
import { identityKeyFromOpaqueToken } from '../src/auth/identity.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import type { ServerClock } from '../src/reading/clock.js';
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

function appFor(
  fetchImpl: typeof fetch,
  store: MemoryDocumentStore,
  objects: MemoryStagedObjectStore,
  guard = new InMemorySoulmateEntitlementGuard(),
) {
  return testApp(testConfig({ AI_RATE_LIMIT_MAX: '100' }), fetchImpl, {
    lunaAccessStore: store,
    speechGrantStore: store,
    speechObjectStore: objects,
    freeTextQuotaStore: store,
    soulmateEntitlement: guard,
    readingClock: new Clock(),
  });
}

function chat(text: string) {
  return { operation: 'chat', model: 'gpt-4o', payload: { userMessage: text, priorUser: [] } };
}

function tts(
  text: string,
  grant: string | undefined,
  voiceId: string,
  speechSpeed: string,
  language = 'tr',
) {
  return {
    operation: 'tts',
    payload: {
      text,
      personality: 'gentle',
      voiceId,
      speechSpeed,
      language,
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

function speechTransport(replies: string[]) {
  let calls = 0;
  let replyAt = 0;
  let fail = false;
  let gate: Promise<void> | null = null;
  let openGate = () => {};
  const inputs: string[] = [];
  const fetchImpl: typeof fetch = async (url, init) => {
    const body = JSON.parse(String(init?.body ?? '{}')) as { input?: string };
    if (String(url).includes('/audio/speech')) {
      calls += 1;
      inputs.push(body.input ?? '');
      const waiting = gate;
      gate = null;
      if (waiting) await waiting;
      if (fail) return new Response('no', { status: 500 });
      return new Response(clip, { status: 200, headers: { 'content-type': 'audio/mpeg' } });
    }
    const content = replies[Math.min(replyAt, replies.length - 1)] ?? 'Sakin bir yansıma.';
    replyAt += 1;
    return jsonResponse({ choices: [{ message: { content } }] });
  };
  return {
    fetchImpl,
    calls: () => calls,
    inputs,
    fail: (value: boolean) => {
      fail = value;
    },
    holdNext() {
      gate = new Promise((resolve) => {
        openGate = resolve;
      });
    },
    release: () => openGate(),
  };
}

function storedClean(store: MemoryDocumentStore, objects: MemoryStagedObjectStore) {
  for (const [, data] of store.docs) {
    const raw = JSON.stringify(data);
    expect(raw).not.toContain('audioBase64');
    expect(raw).not.toContain('https://');
  }
  expect(objects.objects.size).toBeGreaterThan(0);
  for (const path of objects.objects.keys()) {
    expect(path.startsWith('speech-clips/')).toBe(true);
    expect(path).not.toContain('http');
  }
}

describe('luna speech cost', () => {
  it('speaks each reply with its own grant', async () => {
    const spoken = speechTransport(['Birinci yansıma sakin.', 'Ikinci yansıma duru.']);
    const store = new MemoryDocumentStore();
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, store, new MemoryStagedObjectStore(), guard);
    const first = await post(app, tokenA, 'or-cost-chat-01', chat('Birinci not'));
    const second = await post(app, tokenA, 'or-cost-chat-02', chat('Ikinci not'));
    const grantA = first.json().data.speechGrant as string;
    const grantB = second.json().data.speechGrant as string;
    expect(grantA).not.toBe(grantB);
    const hearA = await post(app, tokenA, 'or-cost-hear-a', tts('yanlis metin', grantA, 'warm', 'normal'));
    const hearB = await post(app, tokenA, 'or-cost-hear-b', tts('baska yanlis metin', grantB, 'warm', 'normal'));
    expect(hearA.json().success).toBe(true);
    expect(hearB.json().success).toBe(true);
    expect(spoken.inputs[0]).toContain('Birinci');
    expect(spoken.inputs[0]).not.toContain('Ikinci');
    expect(spoken.inputs[1]).toContain('Ikinci');
    expect(spoken.inputs[1]).not.toContain('Birinci');
    const restore = later(5_000);
    try {
      const again = await post(app, tokenA, 'or-cost-hear-a2', tts('eski mesaj', grantA, 'warm', 'normal'));
      expect(again.json().success).toBe(true);
      expect(spoken.calls()).toBe(2);
    } finally {
      restore();
    }
    await app.close();
  });

  it('caps renders and keeps one in-flight call', async () => {
    const spoken = speechTransport(['Sakin bir yansıma.']);
    const store = new MemoryDocumentStore();
    const objects = new MemoryStagedObjectStore();
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, store, objects, guard);
    const chatRes = await post(app, tokenA, 'or-cost-cap-chat', chat('Ses hakkı'));
    const grant = chatRes.json().data.speechGrant as string;
    spoken.holdNext();
    const pending = Promise.all([
      post(app, tokenA, 'or-cost-cap-a', tts('metin', grant, 'warm', 'normal')),
      post(app, tokenA, 'or-cost-cap-b', tts('metin', grant, 'warm', 'slow')),
    ]);
    for (let i = 0; i < 30 && spoken.calls() < 1; i += 1) {
      await new Promise((resolve) => setImmediate(resolve));
    }
    expect(spoken.calls()).toBe(1);
    spoken.release();
    const pair = await pending;
    const codes = pair.map((res) => res.statusCode).sort();
    expect(codes).toEqual([200, 409]);
    expect(spoken.calls()).toBe(1);
    const restore = later(5_000);
    try {
      const slow = await post(app, tokenA, 'or-cost-cap-slow', tts('metin', grant, 'warm', 'slow'));
      const calm = await post(app, tokenA, 'or-cost-cap-calm', tts('metin', grant, 'calm', 'normal'));
      const deep = await post(app, tokenA, 'or-cost-cap-deep', tts('metin', grant, 'deep', 'normal'));
      expect(slow.json().success && calm.json().success && deep.json().success).toBe(true);
      expect(spoken.calls()).toBe(4);
      const blocked = await post(app, tokenA, 'or-cost-cap-bright', tts('metin', grant, 'bright', 'normal'));
      expect(blocked.statusCode).toBe(409);
      expect(blocked.json().error.code).toBe('rate_limited');
      expect(spoken.calls()).toBe(4);
      const replay = await post(app, tokenA, 'or-cost-cap-replay', tts('baska', grant, 'warm', 'normal'));
      expect(replay.json().success).toBe(true);
      expect(spoken.calls()).toBe(4);
    } finally {
      restore();
    }
    const other = await post(app, tokenB, 'or-cost-cap-other', tts('baska', grant, 'warm', 'normal'));
    expect(other.statusCode).toBe(403);
    expect(JSON.stringify(other.json())).not.toContain('audioBase64');
    storedClean(store, objects);
    await app.close();
  });

  it('retries a provider failure without billing the failed attempt', async () => {
    const spoken = speechTransport(['Sakin bir yansıma.']);
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(spoken.fetchImpl, new MemoryDocumentStore(), new MemoryStagedObjectStore(), guard);
    const chatRes = await post(app, tokenA, 'or-cost-fail-chat', chat('Yeniden dene'));
    const grant = chatRes.json().data.speechGrant as string;
    spoken.fail(true);
    const failed = await post(app, tokenA, 'or-cost-fail-1', tts('metin', grant, 'warm', 'normal'));
    expect(failed.json().success).not.toBe(true);
    const burned = spoken.calls();
    expect(burned).toBeGreaterThan(0);
    spoken.fail(false);
    const restore = later(5_000);
    try {
      const retried = await post(app, tokenA, 'or-cost-fail-2', tts('metin', grant, 'warm', 'normal'));
      expect(retried.json().success).toBe(true);
      expect(spoken.calls()).toBe(burned + 1);
      const again = await post(app, tokenA, 'or-cost-fail-3', tts('eski', grant, 'warm', 'normal'));
      expect(again.json().success).toBe(true);
      expect(spoken.calls()).toBe(burned + 1);
    } finally {
      restore();
    }
    await app.close();
  });

  it('reuses a free preview and stops new settings after the day cap', async () => {
    const spoken = speechTransport([]);
    const store = new MemoryDocumentStore();
    const app = await appFor(spoken.fetchImpl, store, new MemoryStagedObjectStore());
    const voices = ['warm', 'calm', 'deep', 'bright'];
    const speeds = ['slow', 'normal', 'fast'];
    let n = 0;
    for (const voiceId of voices) {
      for (const speechSpeed of speeds) {
        n += 1;
        const res = await post(
          app,
          tokenA,
          `or-cost-prev-${n}`,
          tts(preview, undefined, voiceId, speechSpeed),
        );
        expect(res.json().success, JSON.stringify(res.json())).toBe(true);
      }
    }
    expect(spoken.calls()).toBe(12);
    const restoreRepeat = later(5_000);
    try {
      const repeat = await post(app, tokenA, 'or-cost-prev-repeat', tts(preview, undefined, 'warm', 'slow'));
      expect(repeat.json().success).toBe(true);
      expect(spoken.calls()).toBe(12);
    } finally {
      restoreRepeat();
    }
    const restoreExtra = later(10_000);
    try {
      const extra = await post(
        app,
        tokenA,
        'or-cost-prev-over',
        tts(preview, undefined, 'warm', 'slow', 'en'),
      );
      expect(extra.statusCode).toBe(409);
      expect(extra.json().error.code).toBe('rate_limited');
      expect(spoken.calls()).toBe(12);
    } finally {
      restoreExtra();
    }
    const paths = [...store.docs.keys()];
    expect(paths.some((path) => path.startsWith('freeTextQuota'))).toBe(false);
    expect(paths.some((path) => path.startsWith('ritualDailyQuota'))).toBe(false);
    await app.close();
  });

  it('stops Luna speech after premium lapses and still speaks a delivered oracle reply', async () => {
    const spoken = speechTransport(['Oracle yansıması sakin.', 'Luna yansıması sakin.']);
    const guard = new InMemorySoulmateEntitlementGuard();
    guard.grant(ownerA);
    const app = await appFor(
      spoken.fetchImpl,
      new MemoryDocumentStore(),
      new MemoryStagedObjectStore(),
      guard,
    );
    const oracle = await post(app, tokenA, 'or-cost-oracle', oracleBody);
    expect(oracle.json().success, JSON.stringify(oracle.json())).toBe(true);
    const oracleGrant = oracle.json().data.speechGrant as string;
    const luna = await post(app, tokenA, 'or-cost-luna', chat('Premium ses'));
    const lunaGrant = luna.json().data.speechGrant as string;
    const heard = await post(app, tokenA, 'or-cost-oracle-hear', tts('kehanet', oracleGrant, 'warm', 'normal'));
    const lunaHeard = await post(app, tokenA, 'or-cost-luna-hear', tts('kehanet', lunaGrant, 'calm', 'normal'));
    expect(heard.json().success && lunaHeard.json().success).toBe(true);
    expect(spoken.inputs[0]).toContain('Oracle');
    expect(spoken.inputs[1]).toContain('Luna');
    guard.revoke(ownerA);
    const lapsed = await post(app, tokenA, 'or-cost-luna-lapsed', tts('kehanet', lunaGrant, 'calm', 'normal'));
    expect(lapsed.statusCode).toBe(403);
    const restore = later(8_000);
    try {
      const still = await post(app, tokenA, 'or-cost-oracle-still', tts('baska', oracleGrant, 'warm', 'normal'));
      expect(still.json().success).toBe(true);
      expect(spoken.calls()).toBe(2);
    } finally {
      restore();
    }
    await app.close();
  });
});
