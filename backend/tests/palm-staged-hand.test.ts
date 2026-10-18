/**
 * PALM STAGED HAND — a staged palm photo keeps the hand chosen at staging.
 * The client's `hand` echo never relabels it. Fake fetch only: zero real
 * provider calls. Texts are SYNTHETIC.
 */
import { describe, expect, it } from 'vitest';
import { AiProxyService } from '../src/ai/service.js';
import type { ValidatedRequest } from '../src/ai/validate-request.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import { fakeJpeg, jsonResponse, testConfig } from './helpers.js';

class FixedClock implements ServerClock {
  constructor(private readonly ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

const READING = {
  visualObservation: 'Avucun geniş, çizgilerin net ve derin.',
  overall: 'Önümüzdeki aylarda hızlanan bir dönem başlıyor; kararlarını daha hızlı vereceksin.',
  lifeLine: 'Hayat çizgin başparmağının çevresini geniş bir kavisle dolaşıyor.',
  headLine: 'Akıl çizgin uzun ve hafif aşağı eğimli; hayal gücün güçlü.',
  heartLine: 'Kalp çizgin işaret parmağına kadar uzanıyor.',
  fateLine: '',
  takeaway: 'Bu el, cesaretle atılan adımların karşılığını gören birinin eli.',
};

function harness() {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-10-17T00:00:00.000Z'));
  const policy = provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 });
  const operations = new ReadingOperationService(
    new FirestoreReadingOperationRepository(store),
    clock,
    policy,
  );
  const config = testConfig();
  const staged = new ReadingStagedImageService(
    new FirestoreReadingStagedImageRepository(store),
    new MemoryStagedObjectStore(),
    operations,
    clock,
    config,
  );
  return { operations, staged, config };
}

async function stagedPalm(h: ReturnType<typeof harness>, handSide: 'left' | 'right') {
  const op = await h.operations.create({
    ownerUserId: 'owner-a',
    readingType: 'palm',
    sourceRequestId: `req-palm-${handSide}-${Math.random().toString(36).slice(2)}`,
  });
  await h.staged.stage({
    ownerUserId: 'owner-a',
    operationId: op.operationId,
    mimeType: 'image/jpeg',
    imageBase64: fakeJpeg().toString('base64'),
    handSide,
  });
  return op.operationId;
}

/** Runs one staged palm request and returns every provider request body. */
async function run(
  h: ReturnType<typeof harness>,
  operationId: string,
  clientHand: string,
  identity = 'owner-a',
) {
  const bodies: string[] = [];
  const service = new AiProxyService(
    h.config,
    async (_url, init) => {
      bodies.push(String(init?.body ?? ''));
      return jsonResponse({ choices: [{ message: { content: JSON.stringify(READING) } }] });
    },
    h.staged,
  );
  const request = {
    operation: 'palm_analysis',
    language: 'tr',
    payload: { operationId, mimeType: 'image/jpeg', hand: clientHand },
  } as unknown as ValidatedRequest;
  const result = await service
    .handle(request, undefined, { identity, parentKey: `palm:${operationId}` })
    .catch((error: unknown) => error);
  return { bodies, result };
}

describe('staged palm hand side', () => {
  it('palmHandSide returns the staged hand for its owner only', async () => {
    const h = harness();
    const left = await stagedPalm(h, 'left');
    const right = await stagedPalm(h, 'right');
    expect(await h.staged.palmHandSide({ ownerUserId: 'owner-a', operationId: left })).toBe('left');
    expect(await h.staged.palmHandSide({ ownerUserId: 'owner-a', operationId: right })).toBe('right');
    await expect(
      h.staged.palmHandSide({ ownerUserId: 'owner-b', operationId: left }),
    ).rejects.toBeTruthy();
  });

  it.each([
    ['left', 'right', 'sol el'],
    ['right', 'left', 'sağ el'],
    ['left', 'left', 'sol el'],
    ['right', 'right', 'sağ el'],
  ] as const)(
    'staged %s with client echo %s reaches the reader as %s',
    async (stagedHand, clientHand, phrase) => {
      const h = harness();
      const operationId = await stagedPalm(h, stagedHand);
      const { bodies, result } = await run(h, operationId, clientHand);
      expect(result).not.toBeInstanceOf(Error);
      expect(bodies.length).toBeGreaterThan(0);
      const prompt = bodies.join('\n');
      expect(prompt).toContain(`Kişi ${phrase} avucunu gösterdi.`);
      const other = phrase === 'sol el' ? 'sağ el' : 'sol el';
      expect(prompt).not.toContain(`Kişi ${other} avucunu gösterdi.`);
    },
  );

  it('another owner cannot borrow the stage; image resolution still fails closed', async () => {
    const h = harness();
    const operationId = await stagedPalm(h, 'left');
    const { bodies, result } = await run(h, operationId, 'right', 'owner-b');
    expect(result).toBeInstanceOf(Error);
    expect(bodies).toHaveLength(0);
  });
});
