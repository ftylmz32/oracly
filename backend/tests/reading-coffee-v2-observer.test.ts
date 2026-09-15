/**
 * Coffee 3-Photo Reading V2 — Phase 2B: multi-image observer + writer wiring.
 *
 * All provider calls are mocked (fake fetchImpl) — zero paid calls. Every
 * test exercises the REAL HTTP route (`POST /v1/ai/complete`) against a
 * REAL staged Coffee V2 operation, so the assertions prove the actual
 * wired path (service.ts -> ReadingPipeline.coffeeV2 -> observer/gate/
 * writer), not just the pipeline function in isolation.
 */
import { beforeEach, describe, expect, it } from 'vitest';
import { buildServer } from '../src/server.js';
// The observer/writer stage cache is a process-wide singleton (by design,
// for the real single-Cloud-Run-instance observe/write two-phase flow) --
// it must be cleared between tests or a later test's request can silently
// hit an earlier test's cached observation/narrative instead of calling
// the fake transport again.
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { StaticAppCheckVerifier } from '../src/auth/app-check.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import { systemClock } from '../src/reading/clock.js';
import type { CoffeeV2Observation } from '../src/ai/reading/types.js';
import {
  appCheckHeader,
  authHeader,
  fakeJpeg,
  jsonResponse,
  signHs256,
  testConfig,
} from './helpers.js';

const SECRET = 'unit-test-jwt-secret';
const OWNER_SUB = 'coffee-v2-observer-owner';
const OWNER = identityKeyFromSubject(OWNER_SUB);

function authHeaders() {
  return {
    ...authHeader(signHs256(SECRET, { sub: OWNER_SUB })),
    ...appCheckHeader('good-token'),
  };
}

/** A real, gate-passing V2 observation. Callers may override to violate one rule. */
function goodV2Observation(
  overrides: Partial<CoffeeV2Observation> = {},
): CoffeeV2Observation {
  return {
    usable: true,
    reason: '',
    photoChecks: {
      cupPrimary: {
        cupInteriorVisible: true,
        adequateFocusLight: true,
        residueVisible: true,
        usefulRegionsVisible: true,
      },
      cupSecondary: {
        cupInteriorVisible: true,
        adequateFocusLight: true,
        residueVisible: false,
        usefulRegionsVisible: true,
      },
      saucer: {
        saucerVisible: true,
        adequateFocusLight: true,
        // Deliberately sparse -- the gate must accept this (section 8/K).
        residueOrFlowVisible: false,
        usefulRegionsVisible: true,
      },
    },
    evidence: [
      {
        id: 'e1',
        region: 'middle_wall',
        description: 'Dense residue cluster near the middle wall, slightly elongated toward the handle side.',
        confidence: 'high',
        visibility: 'clear',
        resemblance: null,
        sourceSlot: 'cup_primary',
      },
      {
        id: 'e2',
        region: 'base',
        description: 'A clearer open area at the base beside the dense cluster.',
        confidence: 'high',
        visibility: 'clear',
        resemblance: null,
        sourceSlot: 'cup_secondary',
      },
      {
        id: 'e3',
        region: 'rim',
        description: 'A thin scattered trail near the rim, lighter than the cluster.',
        confidence: 'medium',
        visibility: 'partial',
        resemblance: 'may resemble a small bird in flight',
        sourceSlot: 'saucer',
      },
    ],
    ...overrides,
  };
}

/** A real, known-good narrative (mirrors tests/fixtures/batch3a/coffee_good.json). */
const GOOD_NARRATIVE = {
  visualObservation: {
    text: 'Ortada belirgin bir küme, dipte ise daha açık bir alan göze çarpıyor; ağza yakın ince bir iz de seçiliyor.',
    evidenceIds: ['e1', 'e2', 'e3'],
  },
  overall: {
    text: 'Bu kümenin dipteki açıklıkla yan yana durması, uzun süredir ertelediğin bir kararın nihayet yerini bulmaya başladığını düşündürüyor. Ortadaki yoğunluk geçmiş bir yükün henüz tam çözülmediğine, dipteki ferahlık ise bu yükün yavaşça hafifleyeceğine işaret ediyor gibi. Kenardaki ince iz ise küçük, belki beklenmedik bir haberin bu sürece eşlik edebileceğini çağrıştırıyor; kesin bir olay değil, yalnızca bir olasılık.',
    evidenceIds: ['e1', 'e2', 'e3'],
  },
  love: { text: '', evidenceIds: [] },
  career: {
    text: 'Aynı örüntü iş hayatına da yansıyabilir: biriken bir sorumluluğun ardından biraz nefes alacağın bir aralık doğabilir; bu dönemi zorlamadan kabul etmek işine yarayabilir.',
    evidenceIds: ['e1', 'e2'],
  },
  money: { text: '', evidenceIds: [] },
  nearFuture: {
    text: 'Önümüzdeki günlerde bu ertelenen konuda küçük ama gerçek bir adımın atılma ihtimali var; belki bir mesaj, belki kısa bir konuşma bu süreci hızlandırabilir.',
    evidenceIds: ['e3'],
  },
  takeaway: {
    text: 'Yoğunluk ile açıklığın yan yana durması aslında basit bir şey anlatıyor: bir şey kapanmadan önce hafiflemeye başlar. Bu hafiflemeyi fark etmek, bu fincanın sunduğu en sakin ipucu.',
    evidenceIds: ['e1', 'e2'],
  },
};

type SeenRequest = { schemaName: string | undefined; body: Record<string, unknown> };

function recordingFetch(observation: CoffeeV2Observation) {
  const seen: SeenRequest[] = [];
  const fetchImpl = async (_url: unknown, init?: RequestInit) => {
    const body = JSON.parse(String(init?.body ?? '{}')) as Record<string, unknown>;
    const responseFormat = body.response_format as
      | { json_schema?: { name?: string } }
      | undefined;
    const schemaName = responseFormat?.json_schema?.name;
    seen.push({ schemaName, body });
    if (schemaName === 'coffee_v2_observation') {
      return jsonResponse({ choices: [{ message: { content: JSON.stringify(observation) } }] });
    }
    if (schemaName === 'coffee_narrative') {
      return jsonResponse({ choices: [{ message: { content: JSON.stringify(GOOD_NARRATIVE) } }] });
    }
    if (schemaName === 'palm_observation' || schemaName === 'coffee_observation') {
      // Legacy single-image observer schemas -- a minimal accepting shape.
      return jsonResponse({
        choices: [
          {
            message: {
              content: JSON.stringify({
                usable: true,
                reason: '',
                checks:
                  schemaName === 'coffee_observation'
                    ? {
                        cupInteriorVisible: true,
                        adequateFocusLight: true,
                        residueVisible: true,
                        milkFoamObstruction: false,
                        usefulRegionsVisible: true,
                      }
                    : {
                        onePalmFacing: true,
                        majorLinesVisible: true,
                        adequateFocusLight: true,
                        overlapOcclusion: false,
                        dorsal: false,
                      },
                evidence: [
                  { id: 'e1', region: 'r1', description: 'A visible mark, clearly placed.', confidence: 'high', visibility: 'clear', resemblance: null },
                  { id: 'e2', region: 'r2', description: 'A second visible mark, distinct from the first.', confidence: 'high', visibility: 'clear', resemblance: null },
                  { id: 'e3', region: 'r3', description: 'A third visible mark, in a different region.', confidence: 'medium', visibility: 'partial', resemblance: null },
                ],
              }),
            },
          },
        ],
      });
    }
    return jsonResponse({ choices: [{ message: { content: JSON.stringify(GOOD_NARRATIVE) } }] });
  };
  return { fetchImpl, seen };
}

async function harness(observation = goodV2Observation()) {
  const store = new MemoryDocumentStore();
  const objects = new MemoryStagedObjectStore();
  const clock = systemClock();
  const waitPolicy = provisionalWaitPolicy({ coffee: 60_000, palm: 60_000, soulmate: 60_000 });
  const operationRepository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(operationRepository, clock, waitPolicy);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const config = testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' });
  const stagedImages = new ReadingStagedImageService(stagedRepository, objects, operations, clock, config);
  const { fetchImpl, seen } = recordingFetch(observation);
  const app = await buildServer({
    config,
    fetchImpl,
    appCheck: new StaticAppCheckVerifier('good-token'),
    readingOperationRepository: operationRepository,
    readingWaitPolicy: waitPolicy,
    readingStagedImageRepository: stagedRepository,
    readingStagedImages: stagedImages,
  });
  return { app, operations, stagedImages, seen };
}

async function createCoffeeOp(h: Awaited<ReturnType<typeof harness>>, owner = OWNER) {
  return h.operations.create({
    ownerUserId: owner,
    readingType: 'coffee',
    sourceRequestId: `coffee-v2-obs-${Math.random().toString(36).slice(2)}`,
  });
}

beforeEach(() => {
  readingStageStore.clear();
});

async function stageAllThree(h: Awaited<ReturnType<typeof harness>>, operationId: string, owner = OWNER) {
  await h.stagedImages.stage({ ownerUserId: owner, operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(9000).toString('base64'), slot: 'cup_primary' });
  await h.stagedImages.stage({ ownerUserId: owner, operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(9100).toString('base64'), slot: 'cup_secondary' });
  await h.stagedImages.stage({ ownerUserId: owner, operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(9200).toString('base64'), slot: 'saucer' });
}

async function callCoffeeAnalysis(h: Awaited<ReturnType<typeof harness>>, operationId: string) {
  return h.app.inject({
    method: 'POST',
    url: '/v1/ai/complete',
    headers: authHeaders(),
    payload: { operation: 'coffee_analysis', payload: { operationId } },
  });
}

function observerRequests(seen: SeenRequest[]) {
  return seen.filter((r) => r.schemaName === 'coffee_v2_observation');
}

describe('A/B/C/D/E/F provider observer call shape for a complete V2 operation', () => {
  it('A/B sends exactly ONE observer request with exactly THREE image_url content parts', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(true);
    const obsCalls = observerRequests(h.seen);
    expect(obsCalls).toHaveLength(1);
    const content = obsCalls[0]!.body.messages as Array<{ role: string; content: unknown }>;
    const userMessage = content.find((m) => m.role === 'user')!;
    const parts = userMessage.content as Array<{ type: string }>;
    const images = parts.filter((p) => p.type === 'image_url');
    expect(images).toHaveLength(3);
  });

  it('C image order is exactly cup_primary, cup_secondary, saucer', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    // Stage deliberately out of canonical order.
    await h.stagedImages.stage({ ownerUserId: OWNER, operationId: op.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(9200).toString('base64'), slot: 'saucer' });
    await h.stagedImages.stage({ ownerUserId: OWNER, operationId: op.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(9000).toString('base64'), slot: 'cup_primary' });
    await h.stagedImages.stage({ ownerUserId: OWNER, operationId: op.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(9100).toString('base64'), slot: 'cup_secondary' });
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.statusCode).toBe(200);
    const parts = (observerRequests(h.seen)[0]!.body.messages as Array<{ role: string; content: unknown }>)
      .find((m) => m.role === 'user')!.content as Array<{ type: string; text?: string; image_url?: { url: string } }>;
    const imageUrls = parts.filter((p) => p.type === 'image_url').map((p) => p.image_url!.url);
    // Distinct base64 payloads let us recover which upload landed at each
    // position without depending on label text parsing.
    const primaryB64 = fakeJpeg(9000).toString('base64');
    const secondaryB64 = fakeJpeg(9100).toString('base64');
    const saucerB64 = fakeJpeg(9200).toString('base64');
    expect(imageUrls[0]).toContain(primaryB64);
    expect(imageUrls[1]).toContain(secondaryB64);
    expect(imageUrls[2]).toContain(saucerB64);
  });

  it('D each image is preceded by its correct role label', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    await callCoffeeAnalysis(h, op.operationId);
    const parts = (observerRequests(h.seen)[0]!.body.messages as Array<{ role: string; content: unknown }>)
      .find((m) => m.role === 'user')!.content as Array<{ type: string; text?: string }>;
    const texts = parts.filter((p) => p.type === 'text').map((p) => p.text ?? '');
    expect(texts.some((t) => t.includes('IMAGE 1') && t.includes('CUP_PRIMARY'))).toBe(true);
    expect(texts.some((t) => t.includes('IMAGE 2') && t.includes('CUP_SECONDARY'))).toBe(true);
    expect(texts.some((t) => t.includes('IMAGE 3') && t.includes('SAUCER'))).toBe(true);
  });

  it('E CUP_SECONDARY is explicitly described as the SAME cup, complementary/opposite view', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    await callCoffeeAnalysis(h, op.operationId);
    const parts = (observerRequests(h.seen)[0]!.body.messages as Array<{ role: string; content: unknown }>)
      .find((m) => m.role === 'user')!.content as Array<{ type: string; text?: string }>;
    const label = parts.find((p) => p.text?.includes('CUP_SECONDARY'))!.text!;
    expect(label.toLowerCase()).toContain('complementary');
    expect(label.toLowerCase()).toContain('same coffee cup');
    // "second cup"/"second reading" appear only inside the explicit
    // negation ("do not treat it as..."), never as a positive claim.
    expect(label.toLowerCase()).toContain('do not treat it as a second cup');
  });

  it('F SAUCER is explicitly described as belonging to the same reading', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    await callCoffeeAnalysis(h, op.operationId);
    const parts = (observerRequests(h.seen)[0]!.body.messages as Array<{ role: string; content: unknown }>)
      .find((m) => m.role === 'user')!.content as Array<{ type: string; text?: string }>;
    const label = parts.find((p) => p.text?.includes('SAUCER') && p.text.includes('IMAGE 3'))!.text!;
    expect(label.toLowerCase()).toContain('same cup');
    expect(label.toLowerCase()).toContain('same reading');
  });

  it('H a complete V2 operation invokes the observer once, never three times', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    await callCoffeeAnalysis(h, op.operationId);
    expect(observerRequests(h.seen)).toHaveLength(1);
  });
});

describe('G a partial V2 operation invokes zero providers', () => {
  it('only cup_primary staged -> fails closed, zero provider calls', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await h.stagedImages.stage({ ownerUserId: OWNER, operationId: op.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(9000).toString('base64'), slot: 'cup_primary' });
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.json().success).toBe(false);
    expect(h.seen).toHaveLength(0);
  });
});

describe('I/J legacy Coffee and Palm provider behavior is unaffected', () => {
  it('I legacy Coffee (no slot) still sends exactly ONE image via the legacy schema', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await h.stagedImages.stage({ ownerUserId: OWNER, operationId: op.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg().toString('base64') });
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(true);
    const legacyObsCalls = h.seen.filter((r) => r.schemaName === 'coffee_observation');
    expect(legacyObsCalls).toHaveLength(1);
    expect(observerRequests(h.seen)).toHaveLength(0);
    const content = legacyObsCalls[0]!.body.messages as Array<{ role: string; content: unknown }>;
    const parts = content.find((m) => m.role === 'user')!.content as Array<{ type: string }>;
    expect(parts.filter((p) => p.type === 'image_url')).toHaveLength(1);
  });

  it('J Palm provider behavior is unchanged (still one image, legacy schema)', async () => {
    const h = await harness();
    const op = await h.operations.create({ ownerUserId: OWNER, readingType: 'palm', sourceRequestId: `palm-v2-check-${Math.random()}` });
    await h.stagedImages.stage({ ownerUserId: OWNER, operationId: op.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg().toString('base64'), handSide: 'right' });
    const res = await h.app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeaders(),
      payload: { operation: 'palm_analysis', payload: { operationId: op.operationId, hand: 'right' } },
    });
    expect(res.statusCode).toBe(200);
    // This test's only concern is the OBSERVER call shape for Palm (image
    // count), not full narrative-quality validation (already covered by
    // Palm's own extensive test suites) -- the fake writer response below
    // is intentionally minimal and may or may not clear every downstream
    // quality gate; that outcome is irrelevant here.
    const palmObsCalls = h.seen.filter((r) => r.schemaName === 'palm_observation');
    expect(palmObsCalls).toHaveLength(1);
    const content = palmObsCalls[0]!.body.messages as Array<{ role: string; content: unknown }>;
    const parts = content.find((m) => m.role === 'user')!.content as Array<{ type: string }>;
    expect(parts.filter((p) => p.type === 'image_url')).toHaveLength(1);
  });
});

describe('K/L/M/N/O V2 quality gate — locked rules', () => {
  it('K accepts: both cup interiors visible/focused, saucer visible/focused, residue on at least one cup, EVEN IF saucer has no residue/flow', async () => {
    const h = await harness(goodV2Observation());
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.json().success).toBe(true);
  });

  it('L rejects if cup_primary interior is not visible', async () => {
    const obs = goodV2Observation();
    obs.photoChecks.cupPrimary.cupInteriorVisible = false;
    const h = await harness(obs);
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.json().success).toBe(false);
  });

  it('M rejects if cup_secondary interior is not visible', async () => {
    const obs = goodV2Observation();
    obs.photoChecks.cupSecondary.cupInteriorVisible = false;
    const h = await harness(obs);
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.json().success).toBe(false);
  });

  it('N rejects if saucer is not visible', async () => {
    const obs = goodV2Observation();
    obs.photoChecks.saucer.saucerVisible = false;
    const h = await harness(obs);
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.json().success).toBe(false);
  });

  it('O rejects if any of the 3 photos fails adequateFocusLight', async () => {
    for (const which of ['cupPrimary', 'cupSecondary', 'saucer'] as const) {
      const obs = goodV2Observation();
      obs.photoChecks[which].adequateFocusLight = false;
      const h = await harness(obs);
      const op = await createCoffeeOp(h);
      await stageAllThree(h, op.operationId);
      const res = await callCoffeeAnalysis(h, op.operationId);
      expect(res.json().success, `${which} focus/light failure should reject`).toBe(false);
    }
  });

  it('P rejects if BOTH cup views have residueVisible == false', async () => {
    const obs = goodV2Observation();
    obs.photoChecks.cupPrimary.residueVisible = false;
    obs.photoChecks.cupSecondary.residueVisible = false;
    const h = await harness(obs);
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.json().success).toBe(false);
  });
});

describe('Q/R/S sourceSlot enforcement', () => {
  it('Q every V2 evidence item must contain a canonical sourceSlot (the good fixture already does)', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.json().success).toBe(true);
    const obsCalls = observerRequests(h.seen);
    expect(obsCalls).toHaveLength(1);
  });

  it('R an unknown sourceSlot fails schema/gate validation', async () => {
    const obs = goodV2Observation();
    // @ts-expect-error deliberately invalid for this test
    obs.evidence[0]!.sourceSlot = 'cup_third';
    const h = await harness(obs);
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.json().success).toBe(false);
  });

  it('S legacy Coffee observations do not require sourceSlot (unaffected)', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await h.stagedImages.stage({ ownerUserId: OWNER, operationId: op.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg().toString('base64') });
    const res = await callCoffeeAnalysis(h, op.operationId);
    expect(res.json().success).toBe(true);
  });
});

describe('T/U/V/W/X result contract is unchanged', () => {
  it('T/U the writer executes exactly once and produces exactly one final Coffee result', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    await callCoffeeAnalysis(h, op.operationId);
    const writerCalls = h.seen.filter((r) => r.schemaName === 'coffee_narrative');
    expect(writerCalls).toHaveLength(1);
  });

  it('V/W/X the public result contains exactly the legacy Coffee fields and nothing else', async () => {
    const h = await harness();
    const op = await createCoffeeOp(h);
    await stageAllThree(h, op.operationId);
    const res = await callCoffeeAnalysis(h, op.operationId);
    const data = res.json().data as Record<string, unknown>;
    expect(Object.keys(data).sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'symbols', 'takeaway', 'visualObservation'].sort(),
    );
    expect(data).not.toHaveProperty('photoChecks');
    expect(data).not.toHaveProperty('sourceSlot');
    expect(data).not.toHaveProperty('images');
    expect(JSON.stringify(data)).not.toContain('sourceSlot');
    expect(typeof data.overall).toBe('string');
    expect(typeof data.visualObservation).toBe('string');
  });
});
