/**
 * Aşama 4C — OR/Luna speech data lifecycle.
 *
 * Real AI route (fake provider transport), real speech gate/settle, real
 * account-deletion repository over the in-memory Firestore stand-in, and a
 * GCS stand-in whose one bucket also holds staged coffee / palm images and
 * SoulMate portraits (as in production). No real provider, no cloud.
 */
import { Timestamp } from '@google-cloud/firestore';
import type { Firestore } from '@google-cloud/firestore';
import type { Storage } from '@google-cloud/storage';
import { afterAll, describe, expect, it } from 'vitest';
import { FirestoreAccountDeletionRepository } from '../src/account/account-deletion.js';
import { ACCOUNT_DELETION_RECEIPTS, accountDeletionReceiptId } from '../src/account/deletion-barrier.js';
import { identityKeyFromOpaqueToken, identityKeyFromSubject } from '../src/auth/identity.js';
import type { ServerClock } from '../src/reading/clock.js';
import { discardUnrecordedClip } from '../src/reading/luna-speech-discard.js';
import { issueSpeechGrant, speechGrantRef } from '../src/reading/luna-speech-gate.js';
import { speechClipPath } from '../src/reading/luna-speech-clip.js';
import { PREVIEW_DAY_MAX } from '../src/reading/luna-speech-preview.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { InMemorySoulmateEntitlementGuard } from '../src/reading/soulmate-entitlement-guard.js';
import type { ReadingStagedObjectStore } from '../src/reading/staged-object-store.js';
import {
  applySpeechCleanup,
  planSpeechCleanup,
  redactSpeechObjectName,
} from '../src/reading/speech-cleanup-plan.js';
import {
  decideSpeechObject,
  isOwnedSpeechObject,
  parseSpeechObjectPath,
  previewRecordExpiresAtMs,
  SPEECH_CLIP_MAX_AGE_MS,
  SPEECH_CLIP_ORPHAN_GRACE_MS,
  speechOwnerPrefix,
} from '../src/reading/speech-retention.js';
import { DeletionAdapter } from './support/deletion-adapter.js';
import { authHeader, jsonResponse, signHs256, testApp, testConfig } from './helpers.js';

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const T0 = Date.UTC(2026, 10, 1, 10);
const tokenA = 'speech-life-token-a';
const tokenB = 'speech-life-token-b';
const A = identityKeyFromOpaqueToken(tokenA);
const B = identityKeyFromOpaqueToken(tokenB);
const PREVIEW = 'Selam. Buradayım. Şimdi nasılsın?';
const CLIP = Buffer.from('ID3fake-oracly-tts-audio-bytes-here!!');

// The short-window duplicate filter keys on wall time: step it between
// requests, as the other speech tests do.
const realNow = Date.now;
let wallOffset = 0;
Date.now = () => realNow() + wallOffset;
afterAll(() => { Date.now = realNow; });

class Clock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date { return new Date(this.ms); }
}

/** One bucket, as in production. Hooks model GCS / Firestore failures. */
class Bucket implements ReadingStagedObjectStore {
  readonly objects = new Map<string, { bytes: Buffer; createdMs: number }>();
  failDeleteOnce = false;
  failList = false;
  afterPut: ((path: string) => Promise<void>) | null = null;
  private gate: Promise<void> | null = null;
  private open = () => {};
  constructor(private readonly clock: Clock) {}

  holdPuts(): void { this.gate = new Promise((resolve) => { this.open = resolve; }); }
  releasePuts(): void { this.open(); this.gate = null; }

  async put(path: string, bytes: Buffer): Promise<void> {
    if (this.gate && path.endsWith('.mp3')) await this.gate;
    this.objects.set(path, { bytes: Buffer.from(bytes), createdMs: this.clock.ms });
    if (this.afterPut && path.endsWith('.mp3')) {
      const hook = this.afterPut;
      this.afterPut = null;
      await hook(path);
    }
  }
  async get(path: string): Promise<Buffer | null> { return this.objects.get(path)?.bytes ?? null; }
  async delete(path: string): Promise<void> { this.objects.delete(path); }

  /** `@google-cloud/storage` shape used by account deletion. */
  asStorage(): Storage {
    const self = this;
    return {
      bucket: () => ({
        async getFiles(options: { prefix: string }) {
          if (self.failList) throw new Error('injected gcs list failure');
          return [[...self.objects.keys()].filter((n) => n.startsWith(options.prefix)).map((name) => ({ name }))];
        },
        file: (name: string) => ({
          async delete() {
            if (self.failDeleteOnce) { self.failDeleteOnce = false; throw new Error('injected gcs delete failure'); }
            self.objects.delete(name);
          },
        }),
      }),
    } as unknown as Storage;
  }

  names(prefix = ''): string[] { return [...this.objects.keys()].filter((n) => n.startsWith(prefix)).sort(); }
}

/** Firestore stand-in that can fail the next transaction (finish step). */
class FlakyStore extends MemoryDocumentStore {
  failNextTransaction = false;
  override runTransaction<T>(fn: Parameters<MemoryDocumentStore['runTransaction']>[0]): Promise<T> {
    if (this.failNextTransaction) {
      this.failNextTransaction = false;
      return Promise.reject(new Error('injected firestore failure'));
    }
    return super.runTransaction(fn) as Promise<T>;
  }
}

function provider() {
  let calls = 0;
  let fail = false;
  const fetchImpl: typeof fetch = async (url) => {
    if (String(url).includes('/audio/speech')) {
      calls += 1;
      if (fail) return new Response('upstream', { status: 500 });
      return new Response(CLIP, { status: 200, headers: { 'content-type': 'audio/mpeg' } });
    }
    return jsonResponse({ choices: [{ message: { content: 'Sakin bir yansıma.' } }] });
  };
  return { fetchImpl, calls: () => calls, failSpeech: (v: boolean) => { fail = v; } };
}

async function world() {
  const clock = new Clock(T0);
  const store = new FlakyStore();
  const bucket = new Bucket(clock);
  const guard = new InMemorySoulmateEntitlementGuard();
  guard.grant(A);
  guard.grant(B);
  const spoken = provider();
  const app = await testApp(testConfig({ AI_RATE_LIMIT_MAX: '200', AI_MAX_CONCURRENT: '8' }), spoken.fetchImpl, {
    lunaAccessStore: store,
    speechGrantStore: store,
    speechObjectStore: bucket,
    freeTextQuotaStore: store,
    soulmateEntitlement: guard,
    readingClock: clock,
  });
  const adapter = new DeletionAdapter(store);
  const deletion = new FirestoreAccountDeletionRepository(
    adapter as unknown as Firestore, bucket.asStorage(), 'test-bucket',
  );
  let seq = 0;
  const post = (token: string, payload: unknown) => {
    wallOffset += 5_000;
    return app.inject({
      method: 'POST', url: '/v1/ai/complete',
      headers: { ...authHeader(token), 'idempotency-key': `speech-life-${++seq}-key` },
      payload,
    });
  };
  const chat = async (token: string) => {
    const res = await post(token, { operation: 'chat', model: 'gpt-4o', payload: { userMessage: 'Merhaba', priorUser: [] } });
    return res.json().data.speechGrant as string | undefined;
  };
  const tts = (
    token: string, grant: string | undefined, text = 'metin', voiceId = 'warm',
    speechSpeed = 'normal', personality = 'gentle',
  ) => post(token, {
    operation: 'tts',
    payload: { text, personality, voiceId, speechSpeed, language: 'tr', ...(grant ? { speechGrant: grant } : {}) },
  });
  const docs = (collection: string, owner?: string) => [...store.docs.entries()]
    .filter(([path, data]) => path.startsWith(`${collection}/`) && (owner === undefined || data.identity === owner));
  const receipt = (owner: string) =>
    store.docs.get(`${ACCOUNT_DELETION_RECEIPTS}/${accountDeletionReceiptId(owner)}`) as Record<string, unknown> | undefined;
  /** Firestore TTL model: removes speech records whose `expiresAt` passed. */
  const ttlSweep = () => {
    for (const [path, data] of [...store.docs.entries()]) {
      const at = data.expiresAt;
      if (!(path.startsWith('speechGrants/') || path.startsWith('speechPreviewDay/'))) continue;
      if (at instanceof Timestamp && at.toMillis() <= clock.ms) store.docs.delete(path);
    }
  };
  return { clock, store, bucket, spoken, app, adapter, deletion, post, chat, tts, docs, receipt, ttlSweep };
}

function otherFeatureObjects(bucket: Bucket) {
  bucket.objects.set('reading-staging/owner-a/op-1/cup-1.jpg', { bytes: Buffer.from('jpg'), createdMs: 0 });
  bucket.objects.set('soulmate-portraits/owner-a/portrait.png', { bytes: Buffer.from('png'), createdMs: 0 });
  bucket.objects.set('speech-clips-other/x.mp3', { bytes: Buffer.from('x'), createdMs: 0 });
}

describe('speech records carry a Firestore TTL Timestamp; playback rules unchanged', () => {
  it('a grant record expires with its 6-hour playback window', async () => {
    const w = await world();
    const grant = await w.chat(tokenA);
    expect(grant).toMatch(/^[a-f0-9]{32}$/);
    const row = w.store.docs.get(`speechGrants/${grant}`)!;
    expect(row.expiresAt).toBeInstanceOf(Timestamp);
    expect((row.expiresAt as Timestamp).toMillis()).toBe(row.expiresAtMs);
    expect(row.expiresAtMs).toBe(T0 + 6 * HOUR);
    await w.app.close();
  });

  it('valid grant plays; after 6 hours it is refused even while the record still exists', async () => {
    const w = await world();
    const grant = await w.chat(tokenA);
    expect((await w.tts(tokenA, grant)).statusCode).toBe(200);
    w.clock.ms = T0 + 6 * HOUR + 1;
    const late = await w.tts(tokenA, grant, 'metin', 'deep');
    expect(late.statusCode).toBe(403);
    expect(w.docs('speechGrants', A)).toHaveLength(1);
    w.ttlSweep();
    expect(w.docs('speechGrants', A)).toHaveLength(0);
    await w.app.close();
  });

  it('a successful render records its clip; the TTL instant is not moved by the finish', async () => {
    const w = await world();
    const grant = await w.chat(tokenA);
    const before = (w.store.docs.get(`speechGrants/${grant}`)!.expiresAt as Timestamp).toMillis();
    expect((await w.tts(tokenA, grant)).statusCode).toBe(200);
    const row = w.store.docs.get(`speechGrants/${grant}`)!;
    const paths = Object.values(row.clips as Record<string, string>);
    expect(paths).toHaveLength(1);
    expect(w.bucket.names('speech-clips/')).toEqual(paths);
    expect(paths[0]!.startsWith(speechOwnerPrefix(A))).toBe(true);
    expect((row.expiresAt as Timestamp).toMillis()).toBe(before);
    await w.app.close();
  });

  it('a legacy grant without expiresAt gets one from expiresAtMs on its next claim', async () => {
    const w = await world();
    const grant = await w.chat(tokenA);
    const row = w.store.docs.get(`speechGrants/${grant}`)!;
    delete row.expiresAt;
    expect((await w.tts(tokenA, grant)).statusCode).toBe(200);
    const after = w.store.docs.get(`speechGrants/${grant}`)!;
    expect((after.expiresAt as Timestamp).toMillis()).toBe(after.expiresAtMs);
    await w.app.close();
  });
});

describe('daily free preview cap survives TTL', () => {
  it('the preview-day record expires at the start of the second UTC day; the cap holds all day', async () => {
    const w = await world();
    // 4 voices x 3 speeds = 12 distinct settings = the daily cap.
    for (const voice of ['warm', 'calm', 'deep', 'bright']) {
      for (const speed of ['slow', 'normal', 'fast']) {
        expect((await w.tts(tokenA, undefined, PREVIEW, voice, speed)).json().success).toBe(true);
      }
    }
    expect(w.spoken.calls()).toBe(PREVIEW_DAY_MAX);
    const [[, row]] = w.docs('speechPreviewDay', A);
    expect((row!.expiresAt as Timestamp).toMillis()).toBe(previewRecordExpiresAtMs(T0));
    expect(previewRecordExpiresAtMs(T0)).toBe(Date.UTC(2026, 10, 3));
    w.clock.ms = Date.UTC(2026, 10, 1, 23, 59, 59);
    w.ttlSweep();
    expect(w.docs('speechPreviewDay', A)).toHaveLength(1);
    const over = await w.tts(tokenA, undefined, PREVIEW, 'warm', 'slow', 'mystical');
    expect(over.statusCode).toBe(409);
    expect(w.spoken.calls()).toBe(PREVIEW_DAY_MAX);
    await w.app.close();
  });
});

describe('failed and partial renders leave no MP3', () => {
  it('provider failure: no clip written, claim released, nothing spent', async () => {
    const w = await world();
    const grant = await w.chat(tokenA);
    w.spoken.failSpeech(true);
    const res = await w.tts(tokenA, grant);
    expect(res.json().success).toBe(false);
    expect(w.bucket.names('speech-clips/')).toEqual([]);
    const row = w.store.docs.get(`speechGrants/${grant}`)!;
    expect(row.claimSig).toBe('');
    expect(row.spent).toEqual([]);
    await w.app.close();
  });

  it('finishSpeech Firestore failure: the written MP3 is deleted, not orphaned', async () => {
    const w = await world();
    const grant = await w.chat(tokenA);
    w.bucket.afterPut = async () => { w.store.failNextTransaction = true; };
    const res = await w.tts(tokenA, grant);
    expect(res.json().success).toBe(false);
    expect(w.bucket.names('speech-clips/')).toEqual([]);
    expect(w.store.docs.get(`speechGrants/${grant}`)!.clips).toEqual({});
    await w.app.close();
  });

  it('preview finish failure also deletes its clip', async () => {
    const w = await world();
    w.bucket.afterPut = async () => { w.store.failNextTransaction = true; };
    const res = await w.tts(tokenA, undefined, PREVIEW, 'warm');
    expect(res.json().success).toBe(false);
    expect(w.bucket.names('speech-clips/')).toEqual([]);
    await w.app.close();
  });

  it('discard keeps a clip another render of the same grant/signature recorded', async () => {
    const store = new MemoryDocumentStore();
    const clock = new Clock(T0);
    const bucket = new Bucket(clock);
    const grant = (await issueSpeechGrant({ store, clock, identity: A, kind: 'luna', text: 'yanıt' }))!;
    const path = speechClipPath(A, grant, 'sig');
    await bucket.put(path, CLIP);
    const ref = speechGrantRef(store, grant);
    await store.runTransaction(async (tx) => { tx.update(ref, { clips: { sig: path } }); });
    expect(await discardUnrecordedClip({ objects: bucket, ref, identity: A, signature: 'sig', clipPath: path, accountDeleted: false }))
      .toBe('kept_referenced');
    expect(bucket.names()).toEqual([path]);
    expect(await discardUnrecordedClip({ objects: bucket, ref, identity: A, signature: 'sig', clipPath: path, accountDeleted: true }))
      .toBe('deleted');
    expect(await discardUnrecordedClip({ objects: bucket, ref, identity: A, signature: 'sig', clipPath: path, accountDeleted: true }))
      .toBe('deleted'); // idempotent: missing object is fine
  });

  it('discard refuses a path of another owner or another feature', async () => {
    const store = new MemoryDocumentStore();
    const bucket = new Bucket(new Clock(T0));
    otherFeatureObjects(bucket);
    const ref = speechGrantRef(store, 'a'.repeat(32));
    for (const clipPath of [
      speechClipPath(B, 'a'.repeat(32), 'sig'),
      'reading-staging/owner-a/op-1/cup-1.jpg',
      'soulmate-portraits/owner-a/portrait.png',
      `${speechOwnerPrefix(A)}../../reading-staging/owner-a/op-1/cup-1.jpg`,
    ]) {
      expect(await discardUnrecordedClip({ objects: bucket, ref, identity: A, signature: 's', clipPath, accountDeleted: true }))
        .toBe('refused');
    }
    expect(bucket.names()).toHaveLength(3);
  });
});

describe('account deletion removes speech data of exactly that identity', () => {
  async function seeded() {
    const w = await world();
    otherFeatureObjects(w.bucket);
    const grantA = await w.chat(tokenA);
    expect((await w.tts(tokenA, grantA)).statusCode).toBe(200);
    expect((await w.tts(tokenA, undefined, PREVIEW, 'warm')).statusCode).toBe(200);
    // An orphan of A (finish failed long ago) and a stale probe of A.
    w.bucket.objects.set(`${speechOwnerPrefix(A)}${'c'.repeat(32)}/${'d'.repeat(20)}.mp3`, { bytes: CLIP, createdMs: 0 });
    w.bucket.objects.set(`${speechOwnerPrefix(A)}_probe/ready.txt`, { bytes: Buffer.from('ready'), createdMs: 0 });
    const grantB = await w.chat(tokenB);
    expect((await w.tts(tokenB, grantB)).statusCode).toBe(200);
    expect((await w.tts(tokenB, undefined, PREVIEW, 'warm')).statusCode).toBe(200);
    return { ...w, grantB };
  }

  it('A: grants, preview days, clips, orphan and probe gone; B and other features intact', async () => {
    const w = await seeded();
    const bBefore = w.bucket.names(speechOwnerPrefix(B));
    expect(w.bucket.names(speechOwnerPrefix(A))).toHaveLength(4);
    const receipt = await w.deletion.deleteForIdentity(A);
    expect(receipt.status).toBe('accepted');
    expect(receipt.deletedObjects).toBe(4);
    expect(w.docs('speechGrants', A)).toHaveLength(0);
    expect(w.docs('speechPreviewDay', A)).toHaveLength(0);
    expect(w.bucket.names(speechOwnerPrefix(A))).toEqual([]);
    expect(w.docs('speechGrants', B)).toHaveLength(1);
    expect(w.docs('speechPreviewDay', B)).toHaveLength(1);
    expect(w.bucket.names(speechOwnerPrefix(B))).toEqual(bBefore);
    expect(w.bucket.names('reading-staging/')).toHaveLength(1);
    expect(w.bucket.names('soulmate-portraits/')).toHaveLength(1);
    expect(w.bucket.names('speech-clips-other/')).toHaveLength(1);
    expect((await w.tts(tokenB, w.grantB)).statusCode).toBe(200);
    await w.app.close();
  });

  it('GCS delete failure: not accepted, records kept; the retry completes; a repeat is a no-op', async () => {
    const w = await seeded();
    w.bucket.failDeleteOnce = true;
    await expect(w.deletion.deleteForIdentity(A)).rejects.toThrow(/injected gcs delete failure/);
    expect(w.receipt(A)?.status).toBe('deleting');
    expect(w.docs('speechGrants', A)).toHaveLength(1);
    expect(w.docs('speechPreviewDay', A)).toHaveLength(1);
    const retried = await w.deletion.deleteForIdentity(A);
    expect(retried.status).toBe('accepted');
    expect(w.bucket.names(speechOwnerPrefix(A))).toEqual([]);
    expect(w.docs('speechGrants', A)).toHaveLength(0);
    const again = await w.deletion.deleteForIdentity(A);
    expect(again).toMatchObject({ receiptId: retried.receiptId, status: 'accepted', deletedObjects: retried.deletedObjects });
    await w.app.close();
  });

  it('GCS list failure: not accepted', async () => {
    const w = await seeded();
    w.bucket.failList = true;
    await expect(w.deletion.deleteForIdentity(A)).rejects.toThrow(/injected gcs list failure/);
    expect(w.receipt(A)?.status).toBe('deleting');
    w.bucket.failList = false;
    expect((await w.deletion.deleteForIdentity(A)).status).toBe('accepted');
    await w.app.close();
  });

  it('Firestore failure on the speech sweep: not accepted; retry completes', async () => {
    const w = await seeded();
    w.adapter.failOnce = 'speechPreviewDay';
    await expect(w.deletion.deleteForIdentity(A)).rejects.toThrow(/injected failure/);
    expect(w.receipt(A)?.status).toBe('deleting');
    expect(w.docs('speechPreviewDay', A)).toHaveLength(1);
    expect((await w.deletion.deleteForIdentity(A)).status).toBe('accepted');
    expect(w.docs('speechPreviewDay', A)).toHaveLength(0);
    await w.app.close();
  });

  it('without object storage it fails closed when speech records exist', async () => {
    const w = await seeded();
    const noStorage = new FirestoreAccountDeletionRepository(w.adapter as unknown as Firestore, null, null);
    await expect(noStorage.deleteForIdentity(A)).rejects.toThrow(/object_store_unavailable/);
    expect(w.docs('speechGrants', A)).toHaveLength(1);
    await w.app.close();
  });
});

describe('speech in flight while the account is deleted', () => {
  it('a render whose upload finishes after the sweep leaves no clip and no record', async () => {
    const w = await world();
    const grant = await w.chat(tokenA);
    w.bucket.holdPuts();
    const pending = w.tts(tokenA, grant);
    for (let i = 0; i < 50 && w.spoken.calls() === 0; i++) await new Promise((r) => setTimeout(r, 5));
    await new Promise((r) => setTimeout(r, 20));
    const receipt = await w.deletion.deleteForIdentity(A);
    expect(receipt.status).toBe('accepted');
    w.bucket.releasePuts();
    const res = await pending;
    expect(res.statusCode).toBe(401);
    expect(w.bucket.names(speechOwnerPrefix(A))).toEqual([]);
    expect(w.docs('speechGrants', A)).toHaveLength(0);
    await w.app.close();
  });

  it('after the barrier: no new claim (provider not called) and no new grant record', async () => {
    const w = await world();
    const grant = await w.chat(tokenA);
    await w.deletion.deleteForIdentity(A);
    const calls = w.spoken.calls();
    expect((await w.tts(tokenA, grant)).statusCode).toBe(403); // record swept
    expect((await w.tts(tokenA, undefined, PREVIEW, 'warm')).statusCode).toBe(401);
    expect(w.spoken.calls()).toBe(calls);
    expect(await issueSpeechGrant({ store: w.store, clock: w.clock, identity: A, kind: 'luna', text: 'geç' })).toBeNull();
    expect(w.docs('speechGrants', A)).toHaveLength(0);
    expect(w.docs('speechPreviewDay', A)).toHaveLength(0);
    expect(w.bucket.names(speechOwnerPrefix(A))).toEqual([]);
    await w.app.close();
  });
});

describe('deletion cannot be aimed at another identity', () => {
  it('token B with expectedTargetUid A is rejected and nothing of A or B is deleted', async () => {
    const SECRET = 'speech-life-secret';
    const store = new MemoryDocumentStore();
    const clock = new Clock(T0);
    const bucket = new Bucket(clock);
    const uidA = identityKeyFromSubject('user-a');
    const uidB = identityKeyFromSubject('user-b');
    for (const owner of [uidA, uidB]) {
      const grant = (await issueSpeechGrant({ store, clock, identity: owner, kind: 'luna', text: 'yanıt' }))!;
      await bucket.put(speechClipPath(owner, grant, 'sig'), CLIP);
    }
    const deletion = new FirestoreAccountDeletionRepository(
      new DeletionAdapter(store) as unknown as Firestore, bucket.asStorage(), 'test-bucket',
    );
    const app = await testApp(testConfig({ AI_JWT_SECRET: SECRET }), undefined, { accountDeletionRepository: deletion });
    const res = await app.inject({
      method: 'POST', url: '/v1/account/deletion',
      headers: authHeader(signHs256(SECRET, { sub: 'user-b' })),
      payload: { expectedTargetUid: 'user-a' },
    });
    expect(res.statusCode).toBe(409);
    expect(bucket.names('speech-clips/')).toHaveLength(2);
    expect([...store.docs.keys()].filter((k) => k.startsWith('speechGrants/'))).toHaveLength(2);
    const own = await app.inject({
      method: 'POST', url: '/v1/account/deletion',
      headers: authHeader(signHs256(SECRET, { sub: 'user-b' })),
      payload: { expectedTargetUid: 'user-b' },
    });
    expect(own.statusCode).toBe(202);
    expect(bucket.names('speech-clips/').every((n) => isOwnedSpeechObject(n, uidA))).toBe(true);
    expect([...store.docs.values()].filter((d) => d.identity === uidA && 'text' in d)).toHaveLength(1);
    await app.close();
  });
});

describe('historical cleanup plan (dry run first)', () => {
  const now = T0 + 10 * DAY;
  const owner = speechOwnerPrefix(A);
  const clip = (g: string, s: string) => `${owner}${g.repeat(32)}/${s.repeat(20)}.mp3`;

  it('selects only expired, orphaned and stale-probe speech objects', () => {
    const referenced = clip('a', 'b');
    const plan = planSpeechCleanup({
      nowMs: now,
      records: [{ collection: 'speechGrants', id: 'g1', data: { identity: A, clips: { s: referenced }, expiresAtMs: now - DAY } }],
      objects: [
        { name: clip('1', '2'), createdMs: now - SPEECH_CLIP_MAX_AGE_MS },         // expired
        { name: clip('3', '4'), createdMs: now - 2 * SPEECH_CLIP_ORPHAN_GRACE_MS }, // orphan
        { name: referenced, createdMs: now - 2 * SPEECH_CLIP_ORPHAN_GRACE_MS },     // referenced
        { name: clip('5', '6'), createdMs: now - 60_000 },                          // in grace
        { name: `${owner}_probe/ready.txt`, createdMs: now - 2 * HOUR },             // stale probe
        { name: 'reading-staging/owner/op/cup.jpg', createdMs: 0 },                  // other feature
        { name: 'soulmate-portraits/owner/p.png', createdMs: 0 },
        { name: `${owner}evil.mp3`, createdMs: 0 },                                  // wrong shape
        { name: clip('7', '8'), createdMs: null },                                   // no timestamp
      ],
    });
    expect(plan.deleteObjects.map((d) => d.reason).sort()).toEqual(['expired', 'orphan', 'stale_probe']);
    expect(plan.keptObjects).toEqual({ young: 0, referenced: 1, in_grace: 1 });
    expect(plan.skippedObjects).toEqual({ not_speech: 3, no_timestamp: 1 });
    expect(plan.backfillRecords).toEqual([{ collection: 'speechGrants', id: 'g1', expiresAtMs: now - DAY }]);
    expect(redactSpeechObjectName(clip('1', '2'))).toMatch(/^speech-clips\/<owner>\//);
  });

  it('backfill: preview days get two days from now; records with expiresAt are untouched', () => {
    const plan = planSpeechCleanup({
      nowMs: now,
      objects: [],
      records: [
        { collection: 'speechPreviewDay', id: 'p1', data: { identity: A } },
        { collection: 'speechGrants', id: 'g2', data: { identity: A, expiresAt: Timestamp.fromMillis(now) } },
        { collection: 'speechGrants', id: 'g3', data: { identity: A } },
      ],
    });
    expect(plan.backfillRecords).toEqual([
      { collection: 'speechPreviewDay', id: 'p1', expiresAtMs: previewRecordExpiresAtMs(now) },
      { collection: 'speechGrants', id: 'g3', expiresAtMs: now },
    ]);
  });

  it('apply refuses an over-cap plan and any non-speech name', async () => {
    const deleted: string[] = [];
    const ports = {
      deleteObject: async (n: string) => { deleted.push(n); },
      setRecordExpiresAt: async () => {},
    };
    const plan = planSpeechCleanup({ nowMs: now, records: [], objects: [{ name: clip('1', '2'), createdMs: 0 }] });
    await expect(applySpeechCleanup(plan, ports, { maxDeletes: 0 })).rejects.toThrow(/over_cap/);
    expect(deleted).toEqual([]);
    const forged = { ...plan, deleteObjects: [...plan.deleteObjects, { name: 'reading-staging/x/y.jpg', reason: 'expired' as const }] };
    const result = await applySpeechCleanup(forged, ports, { maxDeletes: 10 });
    expect(result).toEqual({ deletedObjects: 1, backfilledRecords: 0, refused: 1 });
    expect(deleted).toEqual([clip('1', '2')]);
  });

  it('decision and path rules', () => {
    expect(parseSpeechObjectPath(speechClipPath(A, 'f'.repeat(32), 'sig'))?.kind).toBe('clip');
    expect(parseSpeechObjectPath('speech-clips/x/y.mp3')).toBeNull();
    expect(isOwnedSpeechObject(speechClipPath(A, 'f'.repeat(32), 'sig'), B)).toBe(false);
    expect(decideSpeechObject({ name: speechClipPath(A, 'f'.repeat(32), 'sig'), createdMs: now }, new Set(), now))
      .toEqual({ action: 'keep', reason: 'in_grace' });
  });
});
